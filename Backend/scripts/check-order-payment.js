const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkOrderPayment() {
    try {
        // Get the most recent order
        const latestOrder = await prisma.order.findFirst({
            orderBy: { orderId: 'desc' },
            include: {
                payment: true
            }
        });

        if (!latestOrder) {
            console.log("❌ No orders found");
            return;
        }

        console.log("\n📦 Latest Order Details:");
        console.log("   Order ID:", latestOrder.orderId);
        console.log("   Order Status:", latestOrder.status);
        console.log("   Payment Status:", latestOrder.paymentStatus);
        console.log("   Created At:", latestOrder.orderedAt);

        if (latestOrder.payment && latestOrder.payment.length > 0) {
            console.log("\n💳 Payment Details:");
            latestOrder.payment.forEach((p, i) => {
                console.log(`   Payment ${i + 1}:`);
                console.log("      Payment Intent ID:", p.paymentIntentId);
                console.log("      Status:", p.status);
                console.log("      Amount:", p.amount);
            });
        } else {
            console.log("\n⚠️  No payment records found for this order");
        }

        // Check if AUTHORIZED status exists in enum
        console.log("\n🔍 Checking PaymentAttemptStatus enum...");
        const result = await prisma.$queryRaw`
            SELECT unnest(enum_range(NULL::\"PaymentAttemptStatus\")) as status
        `;
        console.log("   Available statuses:", result.map(r => r.status).join(', '));

        const hasAuthorized = result.some(r => r.status === 'AUTHORIZED');
        if (hasAuthorized) {
            console.log("   ✅ AUTHORIZED status exists");
        } else {
            console.log("   ❌ AUTHORIZED status NOT found - you need to run migration!");
            console.log("   Run: npx prisma migrate dev --name add_authorized_payment_status");
        }

    } catch (error) {
        console.error("❌ Error:", error.message);
        if (error.message.includes('AUTHORIZED')) {
            console.log("\n💡 The AUTHORIZED status doesn't exist in your database!");
            console.log("   Run: npx prisma migrate dev --name add_authorized_payment_status");
        }
    } finally {
        await prisma.$disconnect();
    }
}

checkOrderPayment();
