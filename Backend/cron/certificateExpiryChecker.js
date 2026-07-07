const prisma = require("../utils/prisma");
const { sendNotificationToKitchen } = require("../controllers/handleFactory");

/**
 * Calculate days remaining until expiry
 */
function getDaysUntilExpiry(expireDate) {
    const now = new Date();
    now.setHours(0, 0, 0, 0);

    const expire = new Date(expireDate);
    expire.setHours(0, 0, 0, 0);

    const diffTime = expire - now;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    return diffDays;
}

/**
 * Check if notification was already sent today for this kitchen and days remaining
 */
async function wasNotificationSentToday(kitchenId, daysRemaining) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const existingNotification = await prisma.notification.findFirst({
        where: {
            ownerId: kitchenId,
            ownerType: "KITCHEN",
            createdAt: {
                gte: today,
                lt: tomorrow
            },
            message: {
                contains: daysRemaining === 1
                    ? "will expire in 1 day"
                    : `will expire in ${daysRemaining} days`
            }
        }
    });

    return !!existingNotification;
}

/**
 * Send notification for expiring certificate
 */
async function sendExpiryNotification(kitchen, expireDate, daysRemaining) {
    const kitchenId = kitchen.kitchenId;
    const kitchenName = kitchen.kitchenName;

    // Check if notification already sent today
    const alreadySent = await wasNotificationSentToday(kitchenId, daysRemaining);
    if (alreadySent) {
        console.log(`   ⏭️  Notification already sent today for ${kitchenName} (${daysRemaining} days)`);
        return { notificationSent: false, pushSent: false, adminAlertCreated: false };
    }

    // Determine message based on days remaining
    let title, message, adminMessage;

    if (daysRemaining === 30) {
        title = "Food Certificate Expiring in 30 Days ⚠️";
        message = `Your food certificate will expire in 30 days on ${new Date(expireDate).toLocaleDateString()}. Please plan to renew it soon.`;
        adminMessage = `${kitchenName}'s food certificate will expire in 30 days on ${new Date(expireDate).toLocaleDateString()}`;
    } else if (daysRemaining === 7) {
        title = "Food Certificate Expiring in 7 Days ⚠️";
        message = `Your food certificate will expire in 7 days on ${new Date(expireDate).toLocaleDateString()}. Please renew it soon to avoid service interruption.`;
        adminMessage = `${kitchenName}'s food certificate will expire in 7 days on ${new Date(expireDate).toLocaleDateString()}`;
    } else if (daysRemaining >= 1 && daysRemaining <= 3) {
        const dayText = daysRemaining === 1 ? "1 day" : `${daysRemaining} days`;
        title = `Food Certificate Expiring in ${dayText} 🚨`;
        message = `URGENT: Your food certificate will expire in ${dayText} on ${new Date(expireDate).toLocaleDateString()}. Please renew it immediately!`;
        adminMessage = `URGENT: ${kitchenName}'s food certificate will expire in ${dayText} on ${new Date(expireDate).toLocaleDateString()}`;
    } else if (daysRemaining === 0) {
        title = "Food Certificate Expires Today! 🚨";
        message = `CRITICAL: Your food certificate expires TODAY (${new Date(expireDate).toLocaleDateString()}). Renew immediately to avoid service suspension!`;
        adminMessage = `CRITICAL: ${kitchenName}'s food certificate expires TODAY (${new Date(expireDate).toLocaleDateString()})`;
    } else {
        return { notificationSent: false, pushSent: false, adminAlertCreated: false };
    }

    let notificationSent = false;
    let pushSent = false;
    let adminAlertCreated = false;

    try {
        // 1️⃣ Create vendor notification in database
        await prisma.notification.create({
            data: {
                ownerId: kitchenId,
                ownerType: "KITCHEN",
                title,
                message,
                type: 1, // Type 1 for vendor notifications
                isRead: false
            }
        });
        notificationSent = true;
        console.log(`   ✅ Notification created for ${kitchenName} (${daysRemaining} days)`);

        // 1️⃣.5️⃣ If certificate expired today (daysRemaining === 0), mark kitchen as REJECTED
        if (daysRemaining === 0) {
            // Get certificate details for audit log
            const kycRecord = await prisma.kitchenKyc.findUnique({
                where: { kitchenId },
                select: {
                    expireDate: true,
                    foodCertificateImage: true
                }
            });

            await prisma.kitchen.update({
                where: { kitchenId },
                data: {
                    status: "REJECTED",
                    rejectReason: "Your uploaded Food Certificate has expired. Kindly reapply to continue to ResQ your from getting waste."
                }
            });
            console.log(`   🚫 Kitchen marked as REJECTED - Certificate expired for ${kitchenName}`);

            // 🔍 CREATE AUDIT LOG for certificate expiration
            try {
                const auditLogger = require('../utils/auditLogger');
                await auditLogger.createAuditLog({
                    kitchenId,
                    actorType: 'SYSTEM',
                    actorId: null,
                    actorName: 'System Cron Job',
                    actorRole: null,
                    actionType: 'FOOD_CERTIFICATE_EXPIRED',
                    actionDescription: `Food certificate expired on ${new Date(expireDate).toLocaleDateString()}. Kitchen status changed to REJECTED.`,
                    oldData: 'APPROVED',
                    newData: 'REJECTED',
                    metadata: {
                        expireDate: expireDate.toISOString(),
                        certificateImage: kycRecord?.foodCertificateImage || null,
                        checkedAt: new Date().toISOString(),
                        automatedAction: true
                    }
                });
                console.log(`   📝 Audit log created for certificate expiration - ${kitchenName}`);
            } catch (auditError) {
                console.error(`   ⚠️  Failed to create audit log for ${kitchenName}:`, auditError.message);
                // Don't fail the entire process if audit logging fails
            }
        }

        // 2️⃣ Send push notification to all kitchen devices
        try {
            await sendNotificationToKitchen(
                kitchenId,
                {
                    title,
                    body: message
                }
            );
            pushSent = true;
            console.log(`   📲 Push notifications sent to kitchen ${kitchenName}`);
        } catch (pushError) {
            console.error(`   ⚠️  Failed to send push notifications to ${kitchenName}:`, pushError.message);
        }

        // 3️⃣ Create admin alert
        await prisma.adminAlert.create({
            data: {
                kitchenId,
                alertType: "CERTIFICATE_EXPIRING",
                title: daysRemaining <= 3 ? "URGENT: Food Certificate Expiring Soon" : "Food Certificate Expiring Soon",
                message: adminMessage,
                metadata: {
                    expireDate: expireDate.toISOString(),
                    daysRemaining,
                    checkedAt: new Date().toISOString()
                }
            }
        });
        adminAlertCreated = true;
        console.log(`   🔔 Admin alert created for ${kitchenName}`);

    } catch (error) {
        console.error(` ❌ Error sending notification to ${kitchenName}:`, error.message);
    }

    return { notificationSent, pushSent, adminAlertCreated };
}

/**
 * Check for certificates expiring and send notifications at multiple intervals:
 * - 30 days before expiry
 * - 7 days before expiry
 * - Daily from 3 days before until expiry (3, 2, 1, 0 days)
 */
async function checkExpiringCertificates() {
    console.log("================================================");
    console.log("🔍 [CERT EXPIRY] Starting certificate expiry check...");
    console.log("================================================");

    try {
        const now = new Date();
        now.setHours(0, 0, 0, 0);

        // Calculate future dates for checking
        const thirtyDaysFromNow = new Date(now);
        thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

        const sevenDaysFromNow = new Date(now);
        sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);

        const threeDaysFromNow = new Date(now);
        threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);

        console.log(`📅 [CERT EXPIRY] Checking certificates expiring within 30 days...`);

        // Find all KYC records with certificates expiring within 30 days
        const expiringKycs = await prisma.kitchenKyc.findMany({
            where: {
                expireDate: {
                    gte: now, // From today
                    lte: thirtyDaysFromNow // Up to 30 days from now
                }
            },
            include: {
                kitchen: {
                    select: {
                        kitchenId: true,
                        kitchenName: true,
                        deviceToken: true,
                        deviceTokens: true
                    }
                }
            }
        });

        console.log(`📊 [CERT EXPIRY] Found ${expiringKycs.length} certificate(s) expiring within 30 days`);

        if (expiringKycs.length === 0) {
            console.log("✅ [CERT EXPIRY] No certificates expiring within 30 days");
            return { success: true, count: 0 };
        }

        let totalNotificationsSent = 0;
        let totalPushNotificationsSent = 0;
        let totalAdminAlertsCreated = 0;
        let processedCount = 0;

        // Process each expiring certificate
        for (const kyc of expiringKycs) {
            const { kitchen, expireDate } = kyc;
            const kitchenName = kitchen.kitchenName;
            const daysRemaining = getDaysUntilExpiry(expireDate);

            console.log(`📄 [CERT EXPIRY] Processing: ${kitchenName} - Expires in ${daysRemaining} days (${new Date(expireDate).toLocaleDateString()})`);

            // Determine if we should send notification based on days remaining
            let shouldNotify = false;

            if (daysRemaining === 30) {
                shouldNotify = true;
                console.log(`   📌 30-day notification trigger`);
            } else if (daysRemaining === 7) {
                shouldNotify = true;
                console.log(`   📌 7-day notification trigger`);
            } else if (daysRemaining >= 0 && daysRemaining <= 3) {
                shouldNotify = true;
                console.log(`   📌 ${daysRemaining}-day urgent notification trigger`);
            }

            if (shouldNotify) {
                const result = await sendExpiryNotification(kitchen, expireDate, daysRemaining);

                if (result.notificationSent) {
                    totalNotificationsSent++;
                    processedCount++;
                }
                if (result.pushSent) {
                    totalPushNotificationsSent++;
                }
                if (result.adminAlertCreated) {
                    totalAdminAlertsCreated++;
                }
            } else {
                console.log(`   ⏭️  Skipping (${daysRemaining} days - not a notification trigger point)`);
            }
        }

        console.log("================================================");
        console.log("📊 [CERT EXPIRY] Summary:");
        console.log(`   Total certificates checked: ${expiringKycs.length}`);
        console.log(`   Notifications sent: ${totalNotificationsSent}`);
        console.log(`   Push notifications sent: ${totalPushNotificationsSent}`);
        console.log(`   Admin alerts created: ${totalAdminAlertsCreated}`);
        console.log("================================================");

        return {
            success: true,
            count: processedCount,
            notificationsSent: totalNotificationsSent,
            pushNotificationsSent: totalPushNotificationsSent,
            adminAlertsCreated: totalAdminAlertsCreated
        };

    } catch (error) {
        console.error("❌ [CERT EXPIRY] Error checking expiring certificates:", error);
        return { success: false, error: error.message };
    }
}

module.exports = { checkExpiringCertificates };
