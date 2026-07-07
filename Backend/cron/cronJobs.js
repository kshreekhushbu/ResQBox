const cron = require("node-cron");
const { checkExpiringCertificates } = require("./certificateExpiryChecker");
const { generateMonthlyInvoicesForAllKitchens } = require("../controllers/adminController");
const { checkExpiredMenuItems } = require("./menuItemExpiryChecker");
const { checkExistingPendingOrders } = require("./orderAcceptanceChecker");
const { checkExistingOrdersForNoShow } = require("./orderNoShowChecker");
const { deleteOldChatRooms } = require("./chatRoomCleaner");
const { checkAndProcessAccountDeletions, checkAndSendDeletionReminders } = require("./accountDeletionChecker");

/**
 * Initialize all cron jobs
 */
function initializeCronJobs() {
    console.log("🕐 [CRON] Initializing cron jobs...");

    // Run account deletion check daily at 1:00 AM UTC
    cron.schedule("0 1 * * *", async () => {
        console.log("🕐 [CRON] Running scheduled account deletion check...");
        try {
            const result = await checkAndProcessAccountDeletions();
            if (result.success) {
                console.log(`✅ [CRON] Account deletion check completed. Processed ${result.count} deletion(s)`);
            } else {
                console.error(`❌ [CRON] Account deletion check failed: ${result.error}`);
            }
        } catch (error) {
            console.error("❌ [CRON] Error in account deletion check:", error);
        }
    }, {
        timezone: "UTC"
    });

    // Send deletion reminder emails daily at 1:30 AM UTC (7 / 3 / 2 / 1 day warnings)
    // ⚠️  Only runs in PRODUCTION to avoid sending real emails during development
    if (process.env.NODE_ENV === "production") {
        cron.schedule("30 1 * * *", async () => {
            console.log("📧 [CRON] Running deletion reminder email check...");
            try {
                const result = await checkAndSendDeletionReminders();
                if (result.success) {
                    console.log(`✅ [CRON] Deletion reminders sent: ${result.emailsSent} email(s)`);
                } else {
                    console.error(`❌ [CRON] Deletion reminder check failed: ${result.error}`);
                }
            } catch (error) {
                console.error("❌ [CRON] Error in deletion reminder check:", error);
            }
        }, {
            timezone: "UTC"
        });
        console.log("   - Deletion reminder emails:     Daily at 01:30 (UTC) — 7/3/2/1-day warnings [PRODUCTION ONLY]");
    } else {
        console.log("   - Deletion reminder emails:     ⏭️  Skipped (NODE_ENV is not 'production')");
    }

    // Run certificate expiry check daily at midnight (00:00)
    cron.schedule("0 0 * * *", async () => {
        console.log("🕐 [CRON] Running scheduled certificate expiry check...");
        try {
            const result = await checkExpiringCertificates();
            if (result.success) {
                console.log(`✅ [CRON] Certificate expiry check completed. Processed ${result.count} certificate(s)`);
            } else {
                console.error(`❌ [CRON] Certificate expiry check failed: ${result.error}`);
            }
        } catch (error) {
            console.error("❌ [CRON] Error in certificate expiry check:", error);
        }
    }, {
        timezone: "UTC" // Universal time
    });

    // Run monthly invoice generation on the 1st of each month at 00:00 UTC
    cron.schedule("0 0 1 * *", async () => {
        console.log("🕐 [CRON] Running scheduled monthly invoice generation...");
        try {
            // Get previous month's details
            const now = new Date();
            const previousMonthDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
            const previousMonth = previousMonthDate.getMonth() + 1; // Convert to 1-indexed (1-12)
            const previousYear = previousMonthDate.getFullYear();

            const result = await generateMonthlyInvoicesForAllKitchens(previousMonth, previousYear);

            if (result.success) {
                console.log(`✅ [CRON] Monthly invoice generation completed.`);
                console.log(`   Successful: ${result.summary.successCount}`);
                console.log(`   Skipped: ${result.summary.skippedCount}`);
                console.log(`   Failed: ${result.summary.failedCount}`);
            } else {
                console.error(`❌ [CRON] Monthly invoice generation failed: ${result.error}`);
            }
        } catch (error) {
            console.error("❌ [CRON] Error in monthly invoice generation:", error);
        }
    }, {
        timezone: "UTC" // Universal time
    });

    // Check for expired menu items every 15 minutes
    cron.schedule("*/15 * * * *", async () => {
        console.log("🕐 [CRON] Running menu item expiry check...");
        try {
            const result = await checkExpiredMenuItems();
            if (result.success) {
                console.log(`✅ [CRON] Menu expiry check completed. Deactivated: ${result.deactivatedCount}`);
            } else {
                console.error(`❌ [CRON] Menu expiry check failed: ${result.error}`);
            }
        } catch (error) {
            console.error("❌ [CRON] Error in menu expiry check:", error);
        }
    }, {
        timezone: "UTC" // Universal time
    });

    // Delete old chat rooms daily at 2:00 AM UTC
    cron.schedule("0 2 * * *", async () => {
        console.log("🕐 [CRON] Running chat room cleanup...");
        try {
            const result = await deleteOldChatRooms();
            if (result.success) {
                console.log(`✅ [CRON] Chat room cleanup completed. Deleted: ${result.deletedCount} room(s)`);
            } else {
                console.error(`❌ [CRON] Chat room cleanup failed: ${result.error}`);
            }
        } catch (error) {
            console.error("❌ [CRON] Error in chat room cleanup:", error);
        }
    }, {
        timezone: "UTC" // Universal time
    });

    // Check existing pending orders on server startup (not a cron job)
    console.log("🕐 [STARTUP] Checking existing orders for acceptance and no-show...");

    // 1. Acceptance check
    checkExistingPendingOrders()
        .then(result => {
            if (result.success) {
                console.log(`✅ [STARTUP] Pending orders check completed.`);
                console.log(`   - Immediately updated: ${result.expiredCount}`);
                console.log(`   - Scheduled: ${result.scheduledCount}`);
            } else {
                console.error(`❌ [STARTUP] Pending orders check failed: ${result.error}`);
            }
        })
        .catch(error => {
            console.error("❌ [STARTUP] Error checking pending orders:", error);
        });

    // 2. No-show check
    checkExistingOrdersForNoShow()
        .then(result => {
            if (result.success) {
                console.log(`✅ [STARTUP] No-show check completed.`);
                console.log(`   - Immediately updated: ${result.immediatelyUpdatedCount}`);
                console.log(`   - Scheduled: ${result.scheduledCount}`);
            } else {
                console.error(`❌ [STARTUP] No-show check failed: ${result.error}`);
            }
        })
        .catch(error => {
            console.error("❌ [STARTUP] Error checking no-show orders:", error);
        });

    console.log("✅ [CRON] Cron jobs initialized successfully");
    console.log("   - Account deletion check:      Daily at 01:00 (UTC)");
    console.log("   - Deletion reminder emails:     Daily at 01:30 (UTC) — 7/3/2/1-day warnings");
    console.log("   - Certificate expiry check:     Daily at 00:00 (UTC)");
    console.log("   - Monthly invoice generation:   1st of each month at 00:00 (UTC)");
    console.log("   - Menu item expiry check:       Every 15 minutes");
    console.log("   - Chat room cleanup:            Daily at 02:00 (UTC)");
    console.log("   - Order acceptance check:       On server startup + scheduled per order");
}

module.exports = { initializeCronJobs };
