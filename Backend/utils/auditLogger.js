// ========================================
// 🔍 RESTAURANT AUDIT TRAIL UTILITY
// ========================================

const prisma = require('./prisma');

/**
 * Create audit log entry
 */
async function createAuditLog({
    kitchenId,
    actorType,
    actorId = null,
    actorName = null,
    actorRole = null,
    actionType,
    actionDescription = null,
    oldData = null,
    newData = null,
    reason = null,
    notes = null,
    resourceType = null,
    resourceId = null,
    metadata = null,
    ipAddress = null,
    userAgent = null
}) {
    try {
        const log = await prisma.restaurantAuditLog.create({
            data: {
                kitchenId,
                actorType,
                actorId,
                actorName,
                actorRole,
                actionType,
                actionDescription,
                oldData,
                newData,
                reason,
                notes,
                resourceType,
                resourceId,
                metadata,
                ipAddress,
                userAgent
            }
        });
        console.log(`✅ Audit: [${actionType}] Kitchen ${kitchenId} by ${actorType}`);
        return log;
    } catch (error) {
        console.error('❌ Audit log failed:', error.message);
        return null;
    }
}

/**
 * Get audit logs for a kitchen
 */
async function getKitchenAuditLogs(kitchenId, options = {}) {
    const page = Number(options.page) || 1;
    const limit = Number(options.limit) || 50;
    const { actionType, actorType, startDate, endDate } = options;
    const skip = (page - 1) * limit;

    const where = {
        kitchenId,
        ...(actionType && { actionType }),
        ...(actorType && { actorType }),
        ...(startDate || endDate ? {
            createdAt: {
                ...(startDate && { gte: new Date(startDate) }),
                ...(endDate && { lte: new Date(endDate) })
            }
        } : {})
    };

    const [logs, total] = await Promise.all([
        prisma.restaurantAuditLog.findMany({
            where,
            skip,
            take: limit,
            orderBy: { createdAt: 'desc' }
        }),
        prisma.restaurantAuditLog.count({ where })
    ]);

    return {
        logs,
        pagination: {
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit)
        }
    };
}

/**
 * Get all audit logs (admin view)
 */
async function getAllAuditLogs(options = {}) {
    const page = Number(options.page) || 1;
    const limit = Number(options.limit) || 50;
    const { kitchenId, actionType, actorType, search, startDate, endDate } = options;
    const skip = (page - 1) * limit;

    const where = {
        ...(kitchenId && { kitchenId: parseInt(kitchenId) }),
        ...(actionType && { actionType }),
        ...(actorType && { actorType }),
        ...(search && {
            OR: [
                { actorName: { contains: search, mode: 'insensitive' } },
                { actionDescription: { contains: search, mode: 'insensitive' } },
                { reason: { contains: search, mode: 'insensitive' } }
            ]
        }),
        ...(startDate || endDate ? {
            createdAt: {
                ...(startDate && { gte: new Date(startDate) }),
                ...(endDate && { lte: new Date(endDate) })
            }
        } : {})
    };

    const [logs, total] = await Promise.all([
        prisma.restaurantAuditLog.findMany({
            where,
            skip,
            take: limit,
            orderBy: { createdAt: 'desc' }
        }),
        prisma.restaurantAuditLog.count({ where })
    ]);

    return {
        logs,
        pagination: {
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit)
        }
    };
}

/**
 * Helper: Get IP address from request
 */
function getIpAddress(req) {
    return req.headers['x-forwarded-for']?.split(',')[0]?.trim() ||
        req.headers['x-real-ip'] ||
        req.connection?.remoteAddress ||
        req.socket?.remoteAddress ||
        null;
}

/**
 * Helper: Get User Agent from request
 */
function getUserAgent(req) {
    return req.headers['user-agent'] || null;
}

module.exports = {
    createAuditLog,
    getKitchenAuditLogs,
    getAllAuditLogs,
    getIpAddress,
    getUserAgent
};
