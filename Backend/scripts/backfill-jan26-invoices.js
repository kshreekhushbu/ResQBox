const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { getNextInvoiceNumber, generatePayoutInvoice } = require("../utils/invoiceGenerator");

async function backfill() {
    console.log("🚀 [BACKFILL] Starting invoice recovery for Jan 26 Payouts...");

    // 1. Period we want to recover (Last Monday 12AM to This Monday 12AM)
    const periodStart = new Date("2026-01-19T00:00:00.000Z");
    const periodEnd = new Date("2026-01-26T00:00:00.000Z"); // Exactly 7 days

    console.log(`📅 Targeting Period: ${periodStart.toISOString()} to ${periodEnd.toISOString()}`);

    try {
        // 2. Get all approved kitchens
        const kitchens = await prisma.kitchen.findMany({
            where: { status: "APPROVED", isActive: 1 },
            include: { address: true, kyc: true }
        });

        console.log(`🏪 Found ${kitchens.length} approved kitchens to check.`);

        const serviceFeeConfig = await prisma.config.findFirst({
            where: { configKey: "Service Fee Percentage" }
        });
        const serviceFeePercent = Number(serviceFeeConfig?.configValue) || 15;

        for (const kitchen of kitchens) {
            console.log(`\n--- Checking Kitchen: ${kitchen.kitchenName} (ID: ${kitchen.kitchenId}) ---`);

            // 3. Find eligible orders in that period
            const orders = await prisma.order.findMany({
                where: {
                    kitchenId: kitchen.kitchenId,
                    paymentStatus: "PAID",
                    status: {
                        in: ["ACCEPTED", "PREPARING", "READY", "PICKED", "NO_SHOW"]
                    },
                    orderedAt: {
                        gte: periodStart,
                        lte: periodEnd
                    }
                },
                select: {
                    orderId: true,
                    orderNumber: true,
                    totalAmount: true,
                    platformFee: true,
                    status: true,
                    orderedAt: true,
                    items: { select: { quantity: true } }
                }
            });

            if (orders.length === 0) {
                console.log(`⏭️  No orders found for this kitchen in this period. Skipping.`);
                continue;
            }

            // 4. Check if a payout already exists for this period to avoid duplicates
            // We check if there's a payout created around Jan 26 or after
            const existingPayout = await prisma.kitchenPayout.findFirst({
                where: {
                    kitchenId: kitchen.kitchenId,
                    periodEnd: {
                        gte: new Date("2026-01-26T00:00:00.000Z"),
                        lte: new Date("2026-01-27T23:59:59.000Z")
                    }
                },
                include: { invoice: true }
            });

            let kitchenPayoutId;
            let stripeTransferId = "RECOVERY_JAN26";

            if (existingPayout) {
                console.log(`💡 Payout record already exists (ID: ${existingPayout.payoutId}).`);
                if (existingPayout.invoice) {
                    console.log(`✅ Invoice already exists (${existingPayout.invoice.invoiceNumber}). Skipping.`);
                    continue;
                }
                kitchenPayoutId = existingPayout.payoutId;
                stripeTransferId = existingPayout.stripeTransferId;
            } else {
                console.log(`➕ Creating new KitchenPayout record...`);

                const totalOrderAmount = orders.reduce((sum, o) => sum + Number(o.totalAmount), 0);
                const totalPlatformFees = orders.reduce((sum, o) => sum + Number(o.platformFee), 0);
                const itemTotal = totalOrderAmount - totalPlatformFees;
                const serviceFeeAmount = Number(((itemTotal * serviceFeePercent) / 100).toFixed(2));
                const payoutAmount = totalOrderAmount - totalPlatformFees - serviceFeeAmount;

                const newPayout = await prisma.kitchenPayout.create({
                    data: {
                        kitchenId: kitchen.kitchenId,
                        periodStart,
                        periodEnd,
                        totalOrderAmount,
                        platformFeeAmount: totalPlatformFees,
                        payoutAmount,
                        ordersCount: orders.length,
                        stripeTransferId: "RECOVERY_BACKFILL_" + Date.now()
                    }
                });
                kitchenPayoutId = newPayout.payoutId;

                // ⭐ Update Kitchen Ledger (Debit)
                await prisma.kitchenLedger.create({
                    data: {
                        kitchenId: kitchen.kitchenId,
                        type: "DEBIT",
                        amount: payoutAmount,
                        description: `Weekly payout backfill for period ${periodStart.toLocaleDateString()} - ${periodEnd.toLocaleDateString()}`
                    }
                });
                console.log(`✅ Ledger updated for kitchen ${kitchen.kitchenName}`);
            }

            // 5. Generate and Save Invoice
            console.log(`📄 Generating invoice for Payout ID: ${kitchenPayoutId}...`);

            const totalOrderAmount = orders.reduce((sum, o) => sum + Number(o.totalAmount), 0);
            const totalPlatformFees = orders.reduce((sum, o) => sum + Number(o.platformFee), 0);
            const itemTotal = totalOrderAmount - totalPlatformFees;
            const serviceFeeAmount = Number(((itemTotal * serviceFeePercent) / 100).toFixed(2));
            const payoutAmount = totalOrderAmount - totalPlatformFees - serviceFeeAmount;

            const invoiceNumber = await getNextInvoiceNumber();
            const restaurantCode = "REST" + String(kitchen.kitchenId).padStart(4, "0");

            const invoiceData = {
                invoiceNumber,
                kitchen,
                restaurantCode,
                periodStart,
                periodEnd,
                totalCredits: totalOrderAmount,
                platformFeesDeducted: totalPlatformFees,
                serviceFeeAmount: serviceFeeAmount,
                serviceFeePercent: serviceFeePercent,
                payoutAmount,
                orderCount: orders.length,
                orders: orders.map(o => ({
                    orderId: o.orderId,
                    orderDisplayId: "OD" + String(o.orderNumber),
                    numberOfItems: o.items.reduce((sum, item) => sum + item.quantity, 0),
                    totalAmount: Number(o.totalAmount),
                    status: o.status,
                    orderedAt: o.orderedAt
                })),
                stripeTransferId,
                createdAt: new Date()
            };

            const { pdfUrl } = await generatePayoutInvoice(invoiceData);

            await prisma.payoutInvoice.create({
                data: {
                    payoutId: kitchenPayoutId,
                    invoiceNumber,
                    pdfUrl
                }
            });

            console.log(`✅ Successfully generated invoice: ${invoiceNumber}`);
            console.log(`🔗 URL: ${pdfUrl}`);
        }

    } catch (error) {
        console.error("❌ Fatal error during backfill:", error);
    } finally {
        await prisma.$disconnect();
    }
}

backfill();
