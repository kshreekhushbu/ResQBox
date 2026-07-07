const { PrismaClient } = require('@prisma/client');
const crypto = require('crypto');

const prisma = new PrismaClient();

async function backfillOrderNumbers() {
    console.log('🔄 Starting backfill of orderNumber and orderUid...\n');

    // Get all orders without orderNumber
    const orders = await prisma.order.findMany({
        where: {
            OR: [
                { orderNumber: null },
                { orderUid: null }
            ]
        },
        select: { orderId: true }
    });

    console.log(`📊 Found ${orders.length} orders to update\n`);

    let updated = 0;
    let failed = 0;

    for (const order of orders) {
        try {
            // Generate unique values
            const orderNumber = Math.floor(10000000 + Math.random() * 90000000);
            const orderUid = crypto.randomBytes(16).toString('hex');

            // Check uniqueness
            const existingNumber = await prisma.order.findUnique({
                where: { orderNumber }
            });
            const existingUid = await prisma.order.findUnique({
                where: { orderUid }
            });

            if (existingNumber || existingUid) {
                console.log(`⚠️  Collision detected for order ${order.orderId}, retrying...`);
                continue; // Will be picked up in next run
            }

            // Update order
            await prisma.order.update({
                where: { orderId: order.orderId },
                data: {
                    orderNumber,
                    orderUid
                }
            });

            updated++;
            if (updated % 10 === 0) {
                console.log(`✅ Updated ${updated}/${orders.length} orders...`);
            }
        } catch (error) {
            console.error(`❌ Failed to update order ${order.orderId}:`, error.message);
            failed++;
        }
    }

    console.log('\n📊 Backfill Summary:');
    console.log(`   ✅ Successfully updated: ${updated}`);
    console.log(`   ❌ Failed: ${failed}`);
    console.log(`   📝 Total processed: ${orders.length}\n`);

    await prisma.$disconnect();
}

backfillOrderNumbers()
    .catch((error) => {
        console.error('❌ Backfill failed:', error);
        process.exit(1);
    });
