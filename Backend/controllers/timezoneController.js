const catchAsync = require("../utils/catchAsync");
const prisma = require("../utils/prisma");

// ==================== TIMEZONE MANAGEMENT ====================

exports.addTimezone = catchAsync(async (req, res) => {
    const { name, displayName, offset } = req.body;

    if (!name || !displayName || !offset) {
        return res.status(400).json({
            status: 0,
            message: "Name, displayName, and offset are required"
        });
    }

    // Check if timezone already exists
    const existing = await prisma.timezone.findFirst({
        where: { name, isActive: { not: 2 } }
    });

    if (existing) {
        return res.status(400).json({
            status: 0,
            message: "Timezone already exists"
        });
    }

    const newTimezone = await prisma.timezone.create({
        data: { name, displayName, offset }
    });

    res.status(201).json({
        status: 1,
        message: "Timezone added successfully",
        timezone: newTimezone
    });
});

exports.getAllTimezones = catchAsync(async (req, res) => {
    const { search } = req.query;
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const where = {
        isActive: { not: 2 },
        ...(search && {
            OR: [
                { name: { contains: search, mode: 'insensitive' } },
                { displayName: { contains: search, mode: 'insensitive' } }
            ]
        })
    };

    // Total count
    const totalTimezones = await prisma.timezone.count({ where });

    // Fetch paginated data
    const timezones = await prisma.timezone.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" }
    });

    return res.status(200).json({
        status: 1,
        timezones,
        pagination: {
            totalRecords: totalTimezones,
            currentPage: page,
            totalPages: Math.ceil(totalTimezones / limit)
        }
    });
});

exports.getTimezoneById = catchAsync(async (req, res) => {
    const { id } = req.params;

    const timezone = await prisma.timezone.findFirst({
        where: {
            id: Number(id),
            isActive: { not: 2 }
        }
    });

    if (!timezone) {
        return res.status(404).json({
            status: 0,
            message: "Timezone not found"
        });
    }

    res.status(200).json({
        status: 1,
        timezone
    });
});

exports.updateTimezone = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { name, displayName, offset, isActive } = req.body;

    const existing = await prisma.timezone.findFirst({
        where: { id: Number(id), isActive: { not: 2 } }
    });

    if (!existing) {
        return res.status(404).json({
            status: 0,
            message: "Timezone not found"
        });
    }

    // Check for duplicate name if updating name
    if (name && name !== existing.name) {
        const duplicate = await prisma.timezone.findFirst({
            where: {
                name,
                id: { not: Number(id) },
                isActive: { not: 2 }
            }
        });

        if (duplicate) {
            return res.status(400).json({
                status: 0,
                message: "Timezone name already exists"
            });
        }
    }

    const updatedTimezone = await prisma.timezone.update({
        where: { id: Number(id) },
        data: {
            ...(name && { name }),
            ...(displayName && { displayName }),
            ...(offset && { offset }),
            ...(isActive !== undefined && { isActive: Number(isActive) })
        }
    });

    res.status(200).json({
        status: 1,
        message: "Timezone updated successfully",
        timezone: updatedTimezone
    });
});

exports.deleteTimezone = catchAsync(async (req, res) => {
    const { id } = req.params;

    const existing = await prisma.timezone.findFirst({
        where: { id: Number(id), isActive: { not: 2 } }
    });

    if (!existing) {
        return res.status(404).json({
            status: 0,
            message: "Timezone not found"
        });
    }

    // Soft delete
    await prisma.timezone.update({
        where: { id: Number(id) },
        data: { isActive: 2 }
    });

    res.status(200).json({
        status: 1,
        message: "Timezone deleted successfully"
    });
});

// ==================== VENDOR/KITCHEN TIMEZONE FUNCTIONS ====================

exports.getActiveTimezones = catchAsync(async (req, res) => {
    const timezones = await prisma.timezone.findMany({
        where: { isActive: 1 },
        orderBy: { displayName: "asc" },
        select: {
            id: true,
            name: true,
            displayName: true,
            offset: true
        }
    });

    res.status(200).json({
        status: 1,
        timezones
    });
});

exports.updateKitchenTimezone = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen; // From auth middleware
    const { timezoneId } = req.body;

    if (!timezoneId) {
        return res.status(400).json({
            status: 0,
            message: "Timezone ID is required"
        });
    }

    // Verify timezone exists and is active
    const timezone = await prisma.timezone.findFirst({
        where: {
            id: Number(timezoneId),
            isActive: 1
        }
    });

    if (!timezone) {
        return res.status(404).json({
            status: 0,
            message: "Timezone not found or inactive"
        });
    }

    // Update kitchen timezone
    await prisma.kitchen.update({
        where: { kitchenId },
        data: { timezoneId: Number(timezoneId) }
    });

    res.status(200).json({
        status: 1,
        message: "Kitchen timezone updated successfully",
        timezone
    });
});

/**
 * Bulk add timezones - useful for adding new countries
 * Accepts an array of timezone objects
 */
exports.bulkAddTimezones = catchAsync(async (req, res) => {
    const { timezones } = req.body;

    if (!Array.isArray(timezones) || timezones.length === 0) {
        return res.status(400).json({
            status: 0,
            message: "Timezones array is required and must not be empty"
        });
    }

    // Validate each timezone has required fields
    for (const tz of timezones) {
        if (!tz.name || !tz.displayName || !tz.offset) {
            return res.status(400).json({
                status: 0,
                message: "Each timezone must have name, displayName, and offset"
            });
        }
    }

    const results = {
        added: [],
        skipped: [],
        failed: []
    };

    for (const tz of timezones) {
        try {
            // Check if timezone already exists
            const existing = await prisma.timezone.findFirst({
                where: {
                    name: tz.name,
                    isActive: { not: 2 }
                }
            });

            if (existing) {
                results.skipped.push({
                    name: tz.name,
                    reason: "Already exists"
                });
                continue;
            }

            // Create timezone
            const newTimezone = await prisma.timezone.create({
                data: {
                    name: tz.name,
                    displayName: tz.displayName,
                    offset: tz.offset,
                    isActive: 1
                }
            });

            results.added.push(newTimezone);

        } catch (error) {
            results.failed.push({
                name: tz.name,
                error: error.message
            });
        }
    }

    res.status(200).json({
        status: 1,
        message: "Bulk timezone import completed",
        summary: {
            total: timezones.length,
            added: results.added.length,
            skipped: results.skipped.length,
            failed: results.failed.length
        },
        results
    });
});

