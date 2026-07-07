const prisma = require("./prisma");

/**
 * Log kitchen activity for comprehensive audit trail
 * Tracks ALL kitchen operations except GET requests
 * 
 * @param {Object} params - Activity log parameters
 * @param {number} params.kitchenId - Kitchen ID
 * @param {string} params.activityType - Type of activity (from ActivityType enum)
 * @param {Object} params.admin - Admin who performed the action {adminId, name}
 * @param {Object} params.kitchen - Kitchen who performed the action {kitchenId, name}
 * @param {Object} params.teamMember - Team member who performed the action {id, name}
 * @param {string} params.previousStatus - Previous status
 * @param {string} params.newStatus - New status
 * @param {string} params.reason - Reason for action (e.g., rejection reason)
 * @param {string} params.description - Detailed description
 * @param {string} params.documentType - Type of document (DEPRECATED - use resourceType)
 * @param {string} params.documentName - Name of document (DEPRECATED - use resourceName)
 * @param {string} params.resourceType - Type of resource (menuItem, kyc, photo, teamMember, etc.)
 * @param {number} params.resourceId - ID of the affected resource
 * @param {string} params.resourceName - Name of the resource
 * @param {Object} params.metadata - Additional metadata (changed fields, old/new values)
 * @param {Object} params.request - Express request object (for IP and user agent)
 */
async function logKitchenActivity({
    kitchenId,
    activityType,
    admin = null,
    kitchen = null,
    teamMember = null,
    previousStatus = null,
    newStatus = null,
    reason = null,
    description = null,
    documentType = null, // DEPRECATED - use resourceType
    documentName = null, // DEPRECATED - use resourceName
    resourceType = null,
    resourceId = null,
    resourceName = null,
    metadata = null,
    request = null
}) {
    try {
        const logData = {
            kitchenId: Number(kitchenId),
            activityType,
            previousStatus,
            newStatus,
            reason,
            description,
            // Support both old documentType and new resourceType
            resourceType: resourceType || documentType || null,
            resourceId: resourceId ? Number(resourceId) : null,
            resourceName: resourceName || documentName || null,
            metadata: metadata ? JSON.parse(JSON.stringify(metadata)) : null,
        };

        // Determine who performed the action and their role
        if (admin) {
            logData.performedBy = Number(admin.adminId);
            logData.performedByName = admin.name || admin.emailId || "Admin";
            logData.performedByRole = "ADMIN";
        } else if (kitchen) {
            logData.performedBy = Number(kitchen.kitchenId);
            logData.performedByName = kitchen.kitchenName || kitchen.name || "Kitchen";
            logData.performedByRole = "KITCHEN";
        } else if (teamMember) {
            logData.performedBy = Number(teamMember.id);
            logData.performedByName = `${teamMember.firstName || ""} ${teamMember.lastName || ""}`.trim() || "Team Member";
            logData.performedByRole = "TEAM_MEMBER";
        }

        // Extract IP and user agent from request if provided
        if (request) {
            logData.ipAddress = request.ip || request.connection?.remoteAddress || null;
            logData.userAgent = request.get("user-agent") || null;
        }

        const log = await prisma.kitchenActivityLog.create({
            data: logData
        });

        console.log(`✅ [ACTIVITY LOG] ${activityType} logged for kitchen ${kitchenId}${logData.resourceType ? ` (${logData.resourceType})` : ""}`);
        return log;
    } catch (error) {
        console.error("❌ [ACTIVITY LOG] Error logging activity:", error);
        // Don't throw error - logging should not break the main flow
        return null;
    }
}

/**
 * Get activity logs for a kitchen
 * @param {number} kitchenId - Kitchen ID
 * @param {Object} options - Query options
 * @param {number} options.limit - Number of logs to fetch
 * @param {number} options.offset - Offset for pagination
 * @param {string} options.activityType - Filter by activity type
 */
async function getKitchenActivityLogs(kitchenId, options = {}) {
    const { limit = 50, offset = 0, activityType = null } = options;

    const where = {
        kitchenId: Number(kitchenId)
    };

    if (activityType) {
        where.activityType = activityType;
    }

    const logs = await prisma.kitchenActivityLog.findMany({
        where,
        orderBy: { createdAt: "desc" },
        take: limit,
        skip: offset
    });

    return logs;
}

/**
 * Get activity timeline for a kitchen (formatted for display)
 * @param {number} kitchenId - Kitchen ID
 */
async function getKitchenTimeline(kitchenId) {
    const logs = await prisma.kitchenActivityLog.findMany({
        where: { kitchenId: Number(kitchenId) },
        orderBy: { createdAt: "desc" }
    });

    return logs.map(log => ({
        id: log.id,
        type: log.activityType,
        timestamp: log.createdAt,
        performedBy: log.performedByName || "System",
        performedById: log.performedBy,
        status: {
            from: log.previousStatus,
            to: log.newStatus
        },
        reason: log.reason,
        description: log.description,
        document: log.documentType ? {
            type: log.documentType,
            name: log.documentName
        } : null,
        metadata: log.metadata,
        ipAddress: log.ipAddress
    }));
}

/**
 * Helper function to get activity description for display
 * @param {string} activityType - Activity type
 * @param {Object} log - Activity log object
 */
function getActivityDescription(activityType, log) {
    const performedBy = log.performedByName ? ` by ${log.performedByName}` : "";
    const resource = log.resourceName ? ` "${log.resourceName}"` : "";
    const reasonText = log.reason ? `: ${log.reason}` : "";

    const descriptions = {
        // Registration & Onboarding
        KITCHEN_REGISTERED: "Restaurant registered on the platform",
        KITCHEN_PROFILE_CREATED: "Initial profile created",

        // Status Changes
        STATUS_APPROVED: `Restaurant approved${performedBy}`,
        STATUS_REJECTED: `Restaurant rejected${performedBy}${reasonText}`,
        STATUS_RESUBMITTED: "Restaurant resubmitted for review",
        STATUS_PENDING: "Status changed to pending",

        // Menu Item Operations
        MENU_ITEM_CREATED: `Menu item${resource} created${performedBy}`,
        MENU_ITEM_UPDATED: `Menu item${resource} updated${performedBy}`,
        MENU_ITEM_DELETED: `Menu item${resource} deleted${performedBy}`,
        MENU_ITEM_ACTIVATED: `Menu item${resource} activated${performedBy}`,
        MENU_ITEM_DEACTIVATED: `Menu item${resource} deactivated${performedBy}`,
        MENU_ITEM_PRICE_UPDATED: `Menu item${resource} price updated${performedBy}`,
        MENU_ITEM_QUANTITY_UPDATED: `Menu item${resource} quantity updated${performedBy}`,
        MENU_ITEM_IMAGE_UPDATED: `Menu item${resource} image updated${performedBy}`,

        // Document Management
        DOCUMENT_UPLOADED: `Document uploaded: ${log.resourceType || "Unknown"}${performedBy}`,
        DOCUMENT_UPDATED: `Document updated: ${log.resourceType || "Unknown"}${performedBy}`,
        DOCUMENT_DELETED: `Document deleted: ${log.resourceType || "Unknown"}${performedBy}`,
        DOCUMENT_APPROVED: `Document approved: ${log.resourceType || "Unknown"}${performedBy}`,
        DOCUMENT_REJECTED: `Document rejected: ${log.resourceType || "Unknown"}${performedBy}`,

        // Profile Updates
        PROFILE_UPDATED: `Profile information updated${performedBy}`,
        PROFILE_NAME_UPDATED: `Kitchen name updated${performedBy}`,
        PROFILE_CONTACT_UPDATED: `Contact information updated${performedBy}`,
        PROFILE_DESCRIPTION_UPDATED: `Description updated${performedBy}`,
        PROFILE_TIMING_UPDATED: `Opening/closing time updated${performedBy}`,

        // KYC Updates
        KYC_CREATED: `KYC information created${performedBy}`,
        KYC_UPDATED: `KYC information updated${performedBy}`,
        KYC_DELETED: `KYC information deleted${performedBy}`,
        KYC_ABN_UPDATED: `ABN number updated${performedBy}`,
        KYC_ACN_UPDATED: `ACN updated${performedBy}`,
        KYC_FOOD_CERTIFICATE_UPDATED: `Food certificate updated${performedBy}`,
        KYC_FOOD_CERTIFICATE_EXPIRED: "Food certificate expired",

        // Address Updates
        ADDRESS_CREATED: `Address created${performedBy}`,
        ADDRESS_UPDATED: `Address information updated${performedBy}`,
        ADDRESS_DELETED: `Address deleted${performedBy}`,
        ADDRESS_LOCATION_UPDATED: `Location coordinates updated${performedBy}`,

        // Photos Updates
        PHOTOS_CREATED: `Photos created${performedBy}`,
        PHOTOS_UPDATED: `Kitchen photos updated${performedBy}`,
        PHOTOS_DELETED: `Photos deleted${performedBy}`,
        PROFILE_PHOTO_UPDATED: `Profile photo updated${performedBy}`,
        GALLERY_PHOTO_ADDED: `Gallery photo added${performedBy}`,
        GALLERY_PHOTO_REMOVED: `Gallery photo removed${performedBy}`,

        // Team Member Operations
        TEAM_MEMBER_ADDED: `Team member${resource} added${performedBy}`,
        TEAM_MEMBER_UPDATED: `Team member${resource} updated${performedBy}`,
        TEAM_MEMBER_DELETED: `Team member${resource} removed${performedBy}`,
        TEAM_MEMBER_ACTIVATED: `Team member${resource} activated${performedBy}`,
        TEAM_MEMBER_DEACTIVATED: `Team member${resource} deactivated${performedBy}`,
        TEAM_MEMBER_PASSWORD_CHANGED: `Team member${resource} password changed${performedBy}`,

        // Category & Cuisine Operations
        CATEGORY_ASSIGNED: `Category assigned${performedBy}`,
        CATEGORY_REMOVED: `Category removed${performedBy}`,
        CUISINE_ASSIGNED: `Cuisine assigned${performedBy}`,
        CUISINE_REMOVED: `Cuisine removed${performedBy}`,
        FOODTYPE_ASSIGNED: `Food type assigned${performedBy}`,
        FOODTYPE_REMOVED: `Food type removed${performedBy}`,

        // Account Management
        ACCOUNT_ACTIVATED: `Account activated${performedBy}`,
        ACCOUNT_DEACTIVATED: `Account deactivated${performedBy}`,
        ACCOUNT_SUSPENDED: `Account suspended${performedBy}`,
        ACCOUNT_DELETED: `Account deleted${performedBy}`,
        ACCOUNT_RESTORED: `Account restored${performedBy}`,
        PASSWORD_CHANGED: `Password changed${performedBy}`,
        PASSWORD_RESET: `Password reset${performedBy}`,

        // Stripe Integration
        STRIPE_CONNECTED: "Stripe account connected",
        STRIPE_DISCONNECTED: "Stripe account disconnected",
        STRIPE_ONBOARDING_STARTED: "Stripe onboarding started",
        STRIPE_ONBOARDING_COMPLETED: "Stripe onboarding completed",
        STRIPE_ACCOUNT_UPDATED: "Stripe account details updated",

        // Financial Operations
        PAYOUT_CREATED: `Payout created${performedBy}`,
        PAYOUT_PROCESSED: `Payout processed${performedBy}`,
        PAYOUT_FAILED: `Payout failed${reasonText}`,
        LEDGER_ENTRY_CREATED: `Ledger entry created${performedBy}`,
        INVOICE_GENERATED: `Invoice generated${performedBy}`,

        // Order Operations
        ORDER_ACCEPTED: `Order accepted${performedBy}`,
        ORDER_REJECTED: `Order rejected${performedBy}${reasonText}`,
        ORDER_PREPARED: `Order marked as prepared${performedBy}`,
        ORDER_READY: `Order marked as ready${performedBy}`,
        ORDER_CANCELLED: `Order cancelled${performedBy}${reasonText}`,

        // Notification Settings
        NOTIFICATION_SETTINGS_UPDATED: `Notification settings updated${performedBy}`,
        NOTIFICATION_TIME_UPDATED: `Notification time updated${performedBy}`,
        DEVICE_TOKEN_UPDATED: `Device token updated${performedBy}`,
        DEVICE_TOKEN_ADDED: `New device token added${performedBy}`,
        DEVICE_TOKEN_REMOVED: `Device token removed${performedBy}`,

        // Timezone & Location
        TIMEZONE_UPDATED: `Timezone updated${performedBy}`,
        LOCATION_UPDATED: `Location coordinates updated${performedBy}`,

        // Other Operations
        NOTE_ADDED: `Note added${performedBy}`,
        MANUAL_REVIEW_REQUESTED: "Manual review requested",
        BULK_UPDATE_PERFORMED: `Bulk update performed${performedBy}`,
        DATA_EXPORTED: `Data exported${performedBy}`,
        SETTINGS_UPDATED: `Settings updated${performedBy}`
    };

    return descriptions[activityType] || activityType;
}

module.exports = {
    logKitchenActivity,
    getKitchenActivityLogs,
    getKitchenTimeline,
    getActivityDescription
};
