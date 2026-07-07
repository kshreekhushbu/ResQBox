const prisma = require("../utils/prisma");

/**
 * Anonymize user details (Final Deletion)
 * Changes names to "ResQBox User" and clears identifying info
 */
const anonymizeUserDetails = async (userId) => {
    return await prisma.user.update({
        where: { userId: Number(userId) },
        data: {
            name: "ResQBox User",
            lastName: "User",
            email: `deleted_${userId}@resqbox.com`, // Avoid null if email is unique
            phoneNumber: "Deleted",
            profilePicture: null,
            deviceToken: null,
            status: "DELETED",
            isActive: 0
        }
    });
};

/**
 * Process all pending user account deletion requests that have passed their scheduled date
 */
const checkAndProcessAccountDeletions = async () => {
    console.log("🔍 [DELETION CHECKER] Checking for scheduled account deletions...");
    const now = new Date();

    try {
        const pendingRequests = await prisma.userAccountRequest.findMany({
            where: {
                status: "PENDING",
                scheduledDeletionAt: { lte: now }
            }
        });

        const results = {
            total: pendingRequests.length,
            success: 0,
            failed: 0
        };

        if (pendingRequests.length === 0) {
            return { success: true, count: 0 };
        }

        for (const request of pendingRequests) {
            try {
                await anonymizeUserDetails(request.userId);

                await prisma.userAccountRequest.update({
                    where: { id: request.id },
                    data: {
                        status: "COMPLETED",
                        completedAt: new Date()
                    }
                });
                console.log(`✅ [DELETION CHECKER] User ${request.userId} anonymized and deleted.`);
                results.success++;
            } catch (err) {
                console.error(`❌ [DELETION CHECKER] Failed to process deletion for user ${request.userId}:`, err.message);
                results.failed++;
            }
        }

        return {
            success: true,
            count: results.success,
            failed: results.failed,
            total: results.total
        };

    } catch (error) {
        console.error("❌ [DELETION CHECKER] Error in deletion checker:", error);
        return { success: false, error: error.message };
    }
};

/**
 * Send deletion reminder emails at the 7 / 3 / 2 / 1 day marks before scheduledDeletionAt.
 * This should be called by a cron job that runs once daily.
 */
const checkAndSendDeletionReminders = async () => {
    console.log("📧 [DELETION REMINDER] Checking for upcoming account deletions to remind...");

    // The reminder milestones in days before deletion
    const REMINDER_DAYS = [7, 3, 2, 1];

    try {
        const { sendUserDeletionReminderEmail } = require("../utils/emailService");

        // Fetch all PENDING inactive requests that haven't been deleted yet
        const pendingRequests = await prisma.userAccountRequest.findMany({
            where: {
                status: "PENDING",
                scheduledDeletionAt: { gt: new Date() }  // Not yet due for deletion
            },
            include: {
                user: {
                    select: {
                        userId: true,
                        name: true,
                        lastName: true,
                        email: true
                    }
                }
            }
        });

        console.log(`📦 [DELETION REMINDER] Found ${pendingRequests.length} pending request(s) to check.`);

        let emailsSent = 0;

        for (const request of pendingRequests) {
            try {
                const user = request.user;
                if (!user?.email) continue;  // Skip users with no email

                const now = new Date();
                const deletionDate = new Date(request.scheduledDeletionAt);

                // Calculate how many full days remain until deletion
                const msRemaining = deletionDate.getTime() - now.getTime();
                const daysRemaining = Math.floor(msRemaining / (1000 * 60 * 60 * 24));

                // Only send if we're at exactly one of the milestone days
                if (!REMINDER_DAYS.includes(daysRemaining)) continue;

                const userName = [user.name, user.lastName].filter(Boolean).join(" ") || "User";

                // Use 'today' label for final day (1 day remaining)
                const daysLabel = daysRemaining === 1 ? 1 : daysRemaining;

                await sendUserDeletionReminderEmail(user.email, userName, daysLabel, request.requestType);

                console.log(`📧 [DELETION REMINDER] Sent ${daysRemaining}-day reminder to user ${user.userId} (${user.email})`);
                emailsSent++;

            } catch (err) {
                console.error(`⚠️ [DELETION REMINDER] Failed for user ${request.userId}:`, err.message);
            }
        }

        console.log(`✅ [DELETION REMINDER] Done. ${emailsSent} reminder email(s) sent.`);
        return { success: true, emailsSent };

    } catch (error) {
        console.error("❌ [DELETION REMINDER] Error in reminder checker:", error);
        return { success: false, error: error.message };
    }
};

module.exports = {
    checkAndProcessAccountDeletions,
    checkAndSendDeletionReminders,
    anonymizeUserDetails
};
