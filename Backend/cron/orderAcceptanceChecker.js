const schedule = require('node-schedule');
const prisma = require("../utils/prisma");

// Store scheduled jobs by orderId
const scheduledJobs = new Map();

/**
 * Schedule a job to update order status after configured time
 * @param {number} orderId - The order ID
 * @param {number} delayMinutes - Minutes to wait before updating
 */
async function scheduleOrderAcceptanceCheck(orderId, delayMinutes) {
    try {
        // Cancel existing job for this order if any
        if (scheduledJobs.has(orderId)) {
            scheduledJobs.get(orderId).cancel();
            scheduledJobs.delete(orderId);
        }

        // Calculate when to run the job
        const runAt = new Date();
        runAt.setMinutes(runAt.getMinutes() + delayMinutes);

        console.log(`⏰ [ORDER ACCEPTANCE] Scheduling check for Order #${orderId} at ${runAt.toISOString()} (${delayMinutes} min from now)`);

        // Schedule the job
        const job = schedule.scheduleJob(runAt, async () => {
            console.log(`🕐 [ORDER ACCEPTANCE] Running scheduled check for Order #${orderId}`);

            try {
                // Check if order is still PENDING
                const order = await prisma.order.findUnique({
                    where: { orderId },
                    select: {
                        orderId: true,
                        orderNumber: true,
                        status: true,
                        paymentStatus: true,
                        orderedAt: true,
                        createdAt: true,
                        userId: true,
                        kitchen: {
                            select: {
                                kitchenName: true
                            }
                        }
                    }
                });

                if (!order) {
                    console.log(`⚠️  [ORDER ACCEPTANCE] Order #${orderId} not found`);
                    scheduledJobs.delete(orderId);
                    return;
                }

                // Only update if still PENDING (not yet accepted/rejected)
                if (order.status === 'PENDING') {
                    // Cancel the Stripe payment intent
                    try {
                        const Stripe = require('stripe');
                        const stripe = new Stripe(process.env.STRIPE_SECRET_KEY_VENDORS);

                        const payment = await prisma.orderPayment.findFirst({
                            where: { orderId }
                        });

                        if (payment && payment.paymentIntentId) {
                            await stripe.paymentIntents.cancel(payment.paymentIntentId);
                            console.log(`💳 [ORDER ACCEPTANCE] Payment intent cancelled: ${payment.paymentIntentId}`);
                        }
                    } catch (stripeError) {
                        console.error(`⚠️  [ORDER ACCEPTANCE] Error cancelling payment:`, stripeError.message);
                        // Continue with rejection even if payment cancellation fails
                    }

                    // Fetch order items to restore inventory
                    const orderItems = await prisma.orderItem.findMany({
                        where: { orderId }
                    });

                    console.log(`📦 [ORDER ACCEPTANCE] Restoring ${orderItems.length} menu item(s) to inventory...`);

                    // Restore quantity for each menu item
                    for (const item of orderItems) {
                        const menuItem = await prisma.menuItem.findUnique({
                            where: { id: item.menuItemId },
                            select: { id: true, name: true, quantity: true }
                        });

                        if (menuItem) {
                            const restoredQuantity = menuItem.quantity + item.quantity;

                            await prisma.menuItem.update({
                                where: { id: item.menuItemId },
                                data: { quantity: restoredQuantity }
                            });

                            console.log(`   ✅ [INVENTORY] ${menuItem.name}: ${menuItem.quantity} → ${restoredQuantity} (restored ${item.quantity})`);
                        } else {
                            console.log(`   ⚠️  [INVENTORY] Menu item ${item.menuItemId} not found`);
                        }
                    }

                    // Update order to REJECTED
                    await prisma.order.update({
                        where: { orderId },
                        data: { status: 'REJECTED' }
                    });

                    const minutesElapsed = Math.floor((new Date() - new Date(order.createdAt)) / 60000);
                    console.log(`✅ [ORDER ACCEPTANCE] Order #${orderId} updated to REJECTED (${minutesElapsed} min elapsed - not accepted in time)`);

                    // 🔌 SOCKET — Notify user of auto-rejection
                    try {
                        const { getIO } = require('../utils/socket');
                        getIO().to(`user_${order.userId}`).emit('order_status_update', {
                            orderId: order.orderId,
                            orderNumber: order.orderNumber,
                            status: 'REJECTED'
                        });
                        console.log(`🔌 [SOCKET] Emitted order_status_update (REJECTED) to user_${order.userId}`);
                    } catch (socketError) {
                        console.error('⚠️ [SOCKET] Failed to emit order_status_update:', socketError.message);
                    }

                    // Send notification to user
                    await prisma.notification.create({
                        data: {
                            ownerId: order.userId,
                            ownerType: "USER",
                            title: "Order Rejected",
                            message: `We're sorry, but your order #OD${order.orderNumber} was not accepted by ${order.kitchen.kitchenName} within the required time.`,
                            orderId: orderId,
                            type: 1
                        }
                    });

                    console.log(`📲 [ORDER ACCEPTANCE] Notification sent to user ${order.userId}`);
                } else {
                    console.log(`ℹ️  [ORDER ACCEPTANCE] Order #${orderId} status is ${order.status}, no update needed`);
                }

                // Remove from scheduled jobs
                scheduledJobs.delete(orderId);

            } catch (error) {
                console.error(`❌ [ORDER ACCEPTANCE] Error processing Order #${orderId}:`, error.message);
                scheduledJobs.delete(orderId);
            }
        });

        // Store the job
        scheduledJobs.set(orderId, job);

        return {
            success: true,
            orderId,
            scheduledAt: runAt.toISOString()
        };

    } catch (error) {
        console.error(`❌ [ORDER ACCEPTANCE] Error scheduling job for Order #${orderId}:`, error.message);
        return {
            success: false,
            error: error.message
        };
    }
}

/**
 * Check all existing PENDING orders and schedule jobs for them
 * Called when server starts
 */
async function checkExistingPendingOrders() {
    try {
        console.log("🔍 [ORDER ACCEPTANCE] Checking existing pending orders on server start...");

        // Get the maximum time to accept order from config
        const config = await prisma.config.findFirst({
            where: { configKey: "Maximum time to Accept Order" }
        });

        if (!config) {
            console.log("⚠️  [ORDER ACCEPTANCE] Config 'Maximum time to Accept Order' not found");
            return { success: false, error: "Config not found" };
        }

        const maxMinutes = Number(config.configValue);
        if (isNaN(maxMinutes) || maxMinutes <= 0) {
            console.log("⚠️  [ORDER ACCEPTANCE] Invalid config value:", config.configValue);
            return { success: false, error: "Invalid config value" };
        }

        console.log(`⏱️  [ORDER ACCEPTANCE] Maximum acceptance time: ${maxMinutes} minutes`);

        // Find all PENDING orders
        const pendingOrders = await prisma.order.findMany({
            where: {
                status: "PENDING"
            },
            select: {
                orderId: true,
                createdAt: true
            }
        });

        console.log(`📦 [ORDER ACCEPTANCE] Found ${pendingOrders.length} pending order(s)`);

        let scheduledCount = 0;
        let expiredCount = 0;

        for (const order of pendingOrders) {
            const minutesElapsed = Math.floor((new Date() - new Date(order.createdAt)) / 60000);
            const remainingMinutes = maxMinutes - minutesElapsed;

            if (remainingMinutes <= 0) {
                // Already expired, update immediately
                try {
                    // Fetch order items to restore inventory
                    const orderItems = await prisma.orderItem.findMany({
                        where: { orderId: order.orderId }
                    });

                    console.log(`   📦 Restoring ${orderItems.length} menu item(s) to inventory...`);

                    // Restore quantity for each menu item
                    for (const item of orderItems) {
                        const menuItem = await prisma.menuItem.findUnique({
                            where: { id: item.menuItemId },
                            select: { id: true, name: true, quantity: true }
                        });

                        if (menuItem) {
                            const restoredQuantity = menuItem.quantity + item.quantity;

                            await prisma.menuItem.update({
                                where: { id: item.menuItemId },
                                data: { quantity: restoredQuantity }
                            });

                            console.log(`      ✅ ${menuItem.name}: ${menuItem.quantity} → ${restoredQuantity}`);
                        }
                    }

                    await prisma.order.update({
                        where: { orderId: order.orderId },
                        data: { status: 'REJECTED' }
                    });

                    console.log(`   ✅ Order #${order.orderId} updated to REJECTED immediately (already ${minutesElapsed} min old)`);
                    expiredCount++;

                    // Send notification + socket (startup catch-up)
                    const orderDetails = await prisma.order.findUnique({
                        where: { orderId: order.orderId },
                        select: {
                            userId: true,
                            orderNumber: true,
                            kitchen: { select: { kitchenName: true } }
                        }
                    });

                    // 🔌 SOCKET — Notify user of auto-rejection (startup catch-up)
                    try {
                        const { getIO } = require('../utils/socket');
                        getIO().to(`user_${orderDetails?.userId}`).emit('order_status_update', {
                            orderId: order.orderId,
                            orderNumber: orderDetails?.orderNumber,
                            status: 'REJECTED'
                        });
                        console.log(`🔌 [SOCKET] Emitted order_status_update (REJECTED) to user_${orderDetails?.userId}`);
                    } catch (socketError) {
                        console.error('⚠️ [SOCKET] Failed to emit order_status_update:', socketError.message);
                    }

                    if (orderDetails) {
                        await prisma.notification.create({
                            data: {
                                ownerId: orderDetails.userId,
                                ownerType: "USER",
                                title: "Order Rejected",
                                message: `We're sorry, but your order #OD${orderDetails.orderNumber} was not accepted by ${orderDetails.kitchen.kitchenName} within the required time.`,
                                orderId: order.orderId,
                                type: 1
                            }
                        });
                    }

                } catch (error) {
                    console.error(`❌ Error updating Order #${order.orderId}:`, error.message);
                }
            } else {
                // Schedule for remaining time
                await scheduleOrderAcceptanceCheck(order.orderId, remainingMinutes);
                console.log(`⏰ Order #${order.orderId} scheduled in ${remainingMinutes} min (${minutesElapsed} min elapsed)`);
                scheduledCount++;
            }
        }

        console.log(`✅ [ORDER ACCEPTANCE] Server startup check complete:`);
        console.log(`   - Immediately updated: ${expiredCount}`);
        console.log(`   - Scheduled: ${scheduledCount}`);

        return {
            success: true,
            expiredCount,
            scheduledCount,
            totalProcessed: pendingOrders.length
        };

    } catch (error) {
        console.error("❌ [ORDER ACCEPTANCE] Error checking existing orders:", error);
        return {
            success: false,
            error: error.message
        };
    }
}

/**
 * Cancel scheduled job for an order (e.g., when vendor accepts)
 * @param {number} orderId 
 */
function cancelOrderAcceptanceCheck(orderId) {
    if (scheduledJobs.has(orderId)) {
        scheduledJobs.get(orderId).cancel();
        scheduledJobs.delete(orderId);
        console.log(`🚫 [ORDER ACCEPTANCE] Cancelled scheduled check for Order #${orderId}`);
        return true;
    }
    return false;
}

/**
 * Get count of currently scheduled jobs
 */
function getScheduledJobsCount() {
    return scheduledJobs.size;
}

module.exports = {
    scheduleOrderAcceptanceCheck,
    checkExistingPendingOrders,
    cancelOrderAcceptanceCheck,
    getScheduledJobsCount
};
