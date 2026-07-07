const schedule = require('node-schedule');
const prisma = require("../utils/prisma");
const { DateTime } = require("luxon");

// Store scheduled jobs by orderId
const scheduledNoShowJobs = new Map();

/**
 * Update order to NO_SHOW, send notifications and generate invoices
 * This mirrors the logic in vendorController.updateStatus for status === "NO_SHOW"
 */
async function processNoShow(orderId) {
    try {
        console.log(`🕐 [NO SHOW] Processing Order #${orderId}...`);

        // Fetch user + device token + kitchen details + items
        // We need all these for invoice generation
        const order = await prisma.order.findUnique({
            where: { orderId: Number(orderId) },
            include: {
                user: {
                    select: {
                        userId: true,
                        deviceToken: true,
                        name: true,
                        phoneNumber: true,
                        email: true
                    }
                },
                kitchen: {
                    include: {
                        address: true,
                        kyc: true,
                        timezone: true
                    }
                },
                items: {
                    include: {
                        menu: {
                            select: {
                                name: true,
                                price: true
                            }
                        }
                    }
                }
            }
        });

        if (!order) {
            console.log(`⚠️  [NO SHOW] Order #${orderId} not found`);
            return;
        }

        // Only update to NO_SHOW if it's not already PICKED, CANCELLED, REJECTED, or NO_SHOW
        const terminalStatuses = ['PICKED', 'CANCELLED', 'REJECTED', 'NO_SHOW'];
        if (terminalStatuses.includes(order.status)) {
            console.log(`ℹ️  [NO SHOW] Order #${orderId} status is already ${order.status}, skipping.`);
            return;
        }

        // 1️⃣ Update order status with timestamps
        await prisma.order.update({
            where: { orderId: Number(orderId) },
            data: {
                status: 'NO_SHOW',
                preparedAt: new Date(),
                pickedAt: new Date()
            }
        });

        console.log(`✅ [NO SHOW] Order #${orderId} updated to NO_SHOW`);

        // 2️⃣ Notifications
        const notificationTitle = "Order Not Collected ⏰";
        const notificationMessage = "You did not collect your order. Please contact support if you have any questions.";
        const userId = order.user.userId;
        const deviceToken = order.user.deviceToken;

        // 🔌 SOCKET — Notify user of NO_SHOW
        try {
            const { getIO } = require('../utils/socket');
            const noShowTimestamp = new Date();
            getIO().to(`user_${userId}`).emit('order_status_update', {
                orderId: order.orderId,
                orderNumber: order.orderNumber,
                status: 'NO_SHOW',
                preparedAt: noShowTimestamp,
                pickedAt: noShowTimestamp
            });
            console.log(`🔌 [SOCKET] Emitted order_status_update (NO_SHOW) to user_${userId}`);
        } catch (socketError) {
            console.error('⚠️ [SOCKET] Failed to emit order_status_update:', socketError.message);
        }

        // DB Notification
        await prisma.notification.create({
            data: {
                ownerId: userId,
                ownerType: "USER",
                title: notificationTitle,
                message: notificationMessage,
                orderId: order.orderId,
                type: 1
            }
        });

        // Push Notification
        if (deviceToken) {
            try {
                const handleFactory = require("../controllers/handleFactory");
                await handleFactory.sendNotificationToUser(
                    userId,
                    {
                        title: notificationTitle,
                        body: notificationMessage,
                        orderId: order.orderId.toString(),
                        status: "NO_SHOW"
                    },
                    deviceToken
                );
            } catch (notifErr) {
                console.error("❌ [NO SHOW] Push notification error:", notifErr.message);
            }
        }

        // 3️⃣ 📄 Generate Invoices (User and Restaurant)
        try {
            const { getNextOrderInvoiceNumber, generateOrderInvoice, generateRestaurantOrderInvoice } = require("../utils/invoiceGenerator");

            // 📄 A. Generate User Invoice (with retry logic for race conditions)
            const existingInvoice = await prisma.orderInvoice.findUnique({
                where: { orderId: Number(orderId) }
            });

            if (!existingInvoice) {
                console.log(`📄 [NO SHOW] Generating user invoice for order ${orderId}...`);

                let invoiceCreated = false;
                let retryCount = 0;
                const maxRetries = 3;

                while (!invoiceCreated && retryCount < maxRetries) {
                    try {
                        const invoiceNumber = await getNextOrderInvoiceNumber();

                        const customerAddress = order.kitchen.address
                            ? `${order.kitchen.address.houseNo || ""} ${order.kitchen.address.street || ""}, ${order.kitchen.address.city || ""}, ${order.kitchen.address.state || ""} ${order.kitchen.address.pincode || ""}`.trim()
                            : null;

                        const restaurantAddress = order.kitchen.address
                            ? `${order.kitchen.address.houseNo || ""} ${order.kitchen.address.street || ""}, ${order.kitchen.address.landmark || ""}, ${order.kitchen.address.city || ""}, ${order.kitchen.address.state || ""} ${order.kitchen.address.pincode || ""}`.trim()
                            : null;

                        const orderItems = order.items.map(item => ({
                            name: item.menu?.name || "Unknown Item",
                            quantity: item.quantity,
                            price: item.price,
                            totalPrice: item.totalPrice
                        }));

                        const { pdfUrl } = await generateOrderInvoice({
                            invoiceNumber,
                            order: {
                                orderId: order.orderId,
                                orderNumber: order.orderNumber,
                                totalAmount: order.totalAmount,
                                gstAmount: order.gstAmount,
                                platformFee: order.platformFee || 0,
                                packingCharges: 0
                            },
                            customer: {
                                name: order.user.name || "Customer",
                                address: customerAddress,
                                phone: order.user.phoneNumber || "N/A"
                            },
                            restaurant: {
                                name: order.kitchen.kitchenName,
                                gstin: order.kitchen.kyc?.abnNumber || null,
                                fssai: order.kitchen.kyc?.fssaiNumber || null,
                                address: restaurantAddress,
                                state: order.kitchen.address?.state || null
                            },
                            orderItems,
                            createdAt: new Date()
                        });

                        await prisma.orderInvoice.create({
                            data: {
                                orderId: Number(orderId),
                                invoiceNumber,
                                pdfUrl
                            }
                        });

                        console.log(`✅ [NO SHOW] User invoice generated: ${invoiceNumber}`);
                        invoiceCreated = true;

                    } catch (error) {
                        if (error.code === 'P2002' && retryCount < maxRetries - 1) {
                            retryCount++;
                            console.log(`⚠️  [NO SHOW] Invoice number collision for order ${orderId}, retrying... (${retryCount}/${maxRetries})`);
                            // Add small random delay before retry
                            await new Promise(resolve => setTimeout(resolve, 100 + Math.random() * 200));
                        } else {
                            throw error;
                        }
                    }
                }
            }

            // 📄 B. Generate Restaurant Invoice (with retry logic for race conditions)
            const existingRestInvoice = await prisma.restaurantOrderInvoice.findUnique({
                where: { orderId: Number(orderId) }
            });

            if (!existingRestInvoice) {
                console.log(`📄 [NO SHOW] Generating restaurant invoice for order ${orderId}...`);

                let invoiceCreated = false;
                let retryCount = 0;
                const maxRetries = 3;

                while (!invoiceCreated && retryCount < maxRetries) {
                    try {
                        const serviceFeeConfig = await prisma.config.findFirst({
                            where: { configKey: "Service Fee Percentage" }
                        });
                        const serviceFeePercent = Number(serviceFeeConfig?.configValue) || 15;
                        const restaurantInvoiceNumber = await getNextOrderInvoiceNumber();

                        const orderItems = order.items.map(item => ({
                            name: item.menu?.name || "Unknown Item",
                            quantity: item.quantity,
                            price: item.price,
                            totalPrice: item.totalPrice
                        }));

                        const { pdfUrl: restaurantPdfUrl } = await generateRestaurantOrderInvoice({
                            invoiceNumber: restaurantInvoiceNumber,
                            order: {
                                orderId: order.orderId,
                                orderNumber: order.orderNumber,
                                totalAmount: order.totalAmount,
                                itemTotal: order.itemTotal
                            },
                            restaurant: {
                                name: order.kitchen.kitchenName,
                                gstin: order.kitchen.kyc?.abnNumber || null
                            },
                            orderItems,
                            serviceFeePercent,
                            createdAt: new Date()
                        });

                        await prisma.restaurantOrderInvoice.create({
                            data: {
                                orderId: Number(orderId),
                                invoiceNumber: restaurantInvoiceNumber,
                                pdfUrl: restaurantPdfUrl,
                                serviceFeePercent
                            }
                        });

                        console.log(`✅ [NO SHOW] Restaurant invoice generated: ${restaurantInvoiceNumber}`);
                        invoiceCreated = true;

                    } catch (error) {
                        if (error.code === 'P2002' && retryCount < maxRetries - 1) {
                            retryCount++;
                            console.log(`⚠️  [NO SHOW] Restaurant invoice number collision for order ${orderId}, retrying... (${retryCount}/${maxRetries})`);
                            // Add small random delay before retry
                            await new Promise(resolve => setTimeout(resolve, 100 + Math.random() * 200));
                        } else {
                            throw error;
                        }
                    }
                }
            }

            // 4️⃣ 📧 Send order completion email (only in production)
            if (process.env.NODE_ENV === 'production' && order.user.email) {
                try {
                    const { sendOrderCompletionEmail } = require('../utils/emailService');
                    await sendOrderCompletionEmail(
                        order.user.email,
                        order.user.name || 'Customer',
                        order.kitchen.kitchenName || 'Restaurant',
                        order.orderId
                    );
                    console.log(`✅ [NO SHOW] Order completion email sent to ${order.user.email}`);
                } catch (emailErr) {
                    console.error("❌ [NO SHOW] Failed to send order completion email:", emailErr.message);
                }
            }

        } catch (invoiceErr) {
            console.error("❌ [NO SHOW] Invoice generation error:", invoiceErr);
        }

    } catch (error) {
        console.error(`❌ [NO SHOW] General error in processNoShow for Order #${orderId}:`, error.message);
    }
}

/**
 * Schedule a job to update order status to NO_SHOW after pickup end time + buffer
 * @param {number} orderId - The order ID
 * @param {string} pickupEndTime - The pickup end time string (HH:mm)
 * @param {number} bufferMinutes - Minutes to wait after pickup end time
 * @param {string} timezoneName - The kitchen's timezone (e.g., "Australia/Sydney")
 */
async function scheduleNoShowCheck(orderId, pickupEndTime, bufferMinutes, timezoneName) {
    try {
        if (!pickupEndTime) {
            console.log(`⚠️  [NO SHOW] No pickup end time for Order #${orderId}, cannot schedule`);
            return;
        }

        const validBufferMinutes = Number(bufferMinutes);
        if (isNaN(validBufferMinutes) || validBufferMinutes < 0 || validBufferMinutes > 525600) {
            bufferMinutes = 30;
        } else {
            bufferMinutes = validBufferMinutes;
        }

        // Cancel existing job for this order if any
        if (scheduledNoShowJobs.has(orderId)) {
            scheduledNoShowJobs.get(orderId).cancel();
            scheduledNoShowJobs.delete(orderId);
        }

        // Calculate when to run the job
        const timezone = timezoneName || "Australia/Sydney";
        const kitchenNow = DateTime.utc().setZone(timezone);

        const [hour, minute] = pickupEndTime.split(":").map(Number);
        let endDateTime = kitchenNow.set({ hour, minute, second: 0, millisecond: 0 });

        const runAt = endDateTime.plus({ minutes: bufferMinutes });

        console.log(`⏰ [NO SHOW] Scheduling check for Order #${orderId} at ${runAt.toString()} (Pickup End: ${pickupEndTime} + ${bufferMinutes} min)`);

        // Schedule the job
        const job = schedule.scheduleJob(runAt.toJSDate(), async () => {
            await processNoShow(orderId);
            scheduledNoShowJobs.delete(orderId);
        });

        // Store the job
        scheduledNoShowJobs.set(orderId, job);

        return {
            success: true,
            orderId,
            scheduledAt: runAt.toString()
        };

    } catch (error) {
        console.error(`❌ [NO SHOW] Error scheduling job for Order #${orderId}:`, error.message);
        return {
            success: false,
            error: error.message
        };
    }
}

/**
 * Check all non-terminal orders and schedule NO_SHOW jobs for them
 * Called when server starts
 */
async function checkExistingOrdersForNoShow() {
    try {
        console.log("🔍 [NO SHOW] Checking existing orders for no-show scheduling on server start...");

        // Get the buffer time from config
        const config = await prisma.config.findFirst({
            where: { configKey: "Max Time to Hold Order Post Pickup End Time" }
        });

        let bufferMinutes = config ? Number(config.configValue) : 30;

        if (isNaN(bufferMinutes) || bufferMinutes < 0 || bufferMinutes > 525600) {
            bufferMinutes = 30;
        }

        // Find all active (non-terminal) orders
        const activeOrders = await prisma.order.findMany({
            where: {
                status: {
                    notIn: ['PICKED', 'CANCELLED', 'REJECTED', 'NO_SHOW', 'PAYMENT_PENDING']
                },
                pickupEndTime: { not: null }
            },
            include: {
                kitchen: {
                    include: {
                        timezone: true
                    }
                }
            }
        });

        console.log(`📦 [NO SHOW] Found ${activeOrders.length} active order(s) to check`);

        let scheduledCount = 0;
        let immediatelyUpdatedCount = 0;

        for (const order of activeOrders) {
            const timezoneName = order.kitchen?.timezone?.name || "Australia/Sydney";
            const kitchenNow = DateTime.utc().setZone(timezoneName);

            const [hour, minute] = order.pickupEndTime.split(":").map(Number);
            let endDateTime = kitchenNow.set({ hour, minute, second: 0, millisecond: 0 });

            const runAt = endDateTime.plus({ minutes: bufferMinutes });

            if (kitchenNow >= runAt) {
                // Already passed the no-show time, update immediately
                await processNoShow(order.orderId);
                immediatelyUpdatedCount++;
            } else {
                // Schedule for remaining time
                await scheduleNoShowCheck(order.orderId, order.pickupEndTime, bufferMinutes, timezoneName);
                scheduledCount++;
            }
        }

        console.log(`✅ [NO SHOW] Server startup check complete:`);
        console.log(`   - Immediately processed: ${immediatelyUpdatedCount}`);
        console.log(`   - Scheduled: ${scheduledCount}`);

        return {
            success: true,
            immediatelyUpdatedCount,
            scheduledCount,
            totalProcessed: activeOrders.length
        };

    } catch (error) {
        console.error("❌ [NO SHOW] Error checking existing orders:", error);
        return {
            success: false,
            error: error.message
        };
    }
}

/**
 * Cancel scheduled no-show check for an order (e.g., when picked up)
 * @param {number} orderId 
 */
function cancelNoShowCheck(orderId) {
    if (scheduledNoShowJobs.has(orderId)) {
        scheduledNoShowJobs.get(orderId).cancel();
        scheduledNoShowJobs.delete(orderId);
        console.log(`🚫 [NO SHOW] Cancelled scheduled check for Order #${orderId}`);
        return true;
    }
    return false;
}

module.exports = {
    scheduleNoShowCheck,
    processNoShow,
    checkExistingOrdersForNoShow,
    cancelNoShowCheck
};
