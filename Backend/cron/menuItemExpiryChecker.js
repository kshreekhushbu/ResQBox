const prisma = require("../utils/prisma");
const { DateTime } = require("luxon");

/**
 * Get current kitchen local DateTime (DST-safe)
 * @param {string} timezoneName - e.g. "Australia/Sydney"
 * @returns {DateTime}
 */
function getKitchenNow(timezoneName) {
    return DateTime.utc().setZone(timezoneName || "Australia/Sydney");
}

/**
 * Parse HH:mm time string into a DateTime on the same local day
 * @param {string} timeStr - Time in HH:mm format (e.g., "14:30")
 * @param {DateTime} kitchenNow - Current kitchen DateTime
 * @returns {DateTime|null} - DateTime with parsed time, or null if invalid
 */
function parseLocalTime(timeStr, kitchenNow) {
    if (!timeStr) return null;

    const [hour, minute] = timeStr.split(":").map(Number);
    return kitchenNow.set({ hour, minute, second: 0, millisecond: 0 });
}

/**
 * Parse a date string (YYYY-MM-DD) combined with an optional HH:mm time string
 * into a DateTime in the given kitchen timezone.
 * @param {string} dateStr  - e.g. "2025-12-31"
 * @param {string|null} timeStr - e.g. "14:30" (optional, defaults to "23:59")
 * @param {string} timezoneName
 * @returns {DateTime|null}
 */
function parseDateWithTime(dateStr, timeStr, timezoneName) {
    if (!dateStr) return null;

    const timePart = timeStr || "23:59";
    const [hour, minute] = timePart.split(":").map(Number);
    const [year, month, day] = dateStr.split("-").map(Number);

    return DateTime.fromObject(
        { year, month, day, hour, minute, second: 0, millisecond: 0 },
        { zone: timezoneName || "Australia/Sydney" }
    );
}

/**
 * Determine whether a menu item should be deactivated based on its expiry window.
 *
 * Rules:
 *  1. If endTimeDate is provided → full date+time comparison (date-aware).
 *     endTime is used as the time component; defaults to "23:59" if absent.
 *  2. If only endTime is provided (no date) → time-of-day check (legacy).
 *
 * startTime / startTimeDate are intentionally ignored (removed from frontend).
 *
 * @param {object} item        - MenuItem with endTime, endTimeDate fields
 * @param {string} timezoneName
 * @returns {{ shouldDeactivate: boolean, reason: string|null }}
 */
function evaluateExpiry(item, timezoneName) {
    const kitchenNow = getKitchenNow(timezoneName);

    // ──────────────────────────────────────────────
    // CASE 1: endTimeDate provided → date-aware expiry
    // ──────────────────────────────────────────────
    if (item.endTimeDate) {
        const endDateTime = parseDateWithTime(item.endTimeDate, item.endTime || "23:59", timezoneName);

        if (endDateTime && kitchenNow >= endDateTime) {
            return {
                shouldDeactivate: true,
                reason: `Expired at ${item.endTimeDate} ${item.endTime || "23:59"}`
            };
        }

        return { shouldDeactivate: false, reason: null };
    }

    // ──────────────────────────────────────────────
    // CASE 2: endTime only → time-of-day check (legacy)
    // ──────────────────────────────────────────────
    if (item.endTime) {
        const endDateTime = parseLocalTime(item.endTime, kitchenNow);

        if (endDateTime && kitchenNow >= endDateTime) {
            return {
                shouldDeactivate: true,
                reason: `Service ended at ${item.endTime}`
            };
        }
    }

    return { shouldDeactivate: false, reason: null };
}

/**
 * Check and deactivate expired menu items based on their endTime / endTimeDate and kitchen timezone.
 * Runs as a cron job.
 */
async function checkExpiredMenuItems() {
    try {
        console.log('\n🕐 [MENU] Checking for expired menu items...');

        // Fetch all active menu items that have EITHER an endTime OR an endTimeDate
        const menuItems = await prisma.menuItem.findMany({
            where: {
                isActive: 1,
                OR: [
                    { endTime: { not: null } },
                    { endTimeDate: { not: null } }
                ]
            },
            include: {
                kitchen: {
                    include: {
                        timezone: true
                    }
                }
            }
        });

        console.log(`Found ${menuItems.length} active menu items with endTime / endTimeDate`);

        let deactivatedCount = 0;
        const deactivatedItems = [];

        for (const item of menuItems) {
            try {
                const timezoneName = item.kitchen?.timezone?.name || "Australia/Sydney";
                const { shouldDeactivate, reason } = evaluateExpiry(item, timezoneName);

                if (shouldDeactivate) {
                    await prisma.menuItem.update({
                        where: { id: item.id },
                        data: { isActive: 0 }
                    });

                    console.log(`✅ Deactivated: "${item.name}" (Kitchen: ${item.kitchen?.kitchenName || item.kitchenId})`);
                    console.log(`   Reason: ${reason} | Timezone: ${timezoneName}`);

                    deactivatedCount++;
                    deactivatedItems.push({
                        menuItemId: item.id,
                        menuItemName: item.name,
                        kitchenId: item.kitchenId,
                        kitchenName: item.kitchen?.kitchenName,
                        endTime: item.endTime,
                        endTimeDate: item.endTimeDate,
                        timezone: timezoneName,
                        reason
                    });
                }

            } catch (itemError) {
                console.error(`❌ Error processing menu item ${item.id}:`, itemError.message);
            }
        }

        console.log(`\n========== MENU EXPIRY CHECK SUMMARY ==========`);
        console.log(`Total items checked: ${menuItems.length}`);
        console.log(`Deactivated: ${deactivatedCount}`);
        console.log(`===============================================\n`);

        return {
            success: true,
            totalChecked: menuItems.length,
            deactivatedCount,
            deactivatedItems
        };

    } catch (error) {
        console.error('❌ [MENU] Error checking expired menu items:', error);
        return {
            success: false,
            error: error.message
        };
    }
}

/**
 * Check if a specific menu item is currently active based on its time / date-time window.
 * This should be called when user tries to add item to cart or place order.
 * @param {number} menuItemId - Menu item ID to check
 * @returns {Promise<{isValid: boolean, reason?: string}>}
 */

async function validateMenuItemTime(menuItemId) {
    try {
        const menuItem = await prisma.menuItem.findUnique({
            where: { id: menuItemId },
            include: {
                kitchen: {
                    include: {
                        timezone: true
                    }
                }
            }
        });

        if (!menuItem) {
            return { isValid: false, reason: "Menu item not found" };
        }

        if (menuItem.isActive !== 1) {
            return { isValid: false, reason: "Menu item is not active" };
        }

        // No time/date restrictions → always valid
        if (!menuItem.endTime && !menuItem.endTimeDate) {
            return { isValid: true };
        }

        const timezoneName = menuItem.kitchen?.timezone?.name || "Australia/Sydney";
        const { shouldDeactivate, reason } = evaluateExpiry(menuItem, timezoneName);

        if (shouldDeactivate) {
            // Deactivate the item immediately
            await prisma.menuItem.update({
                where: { id: menuItemId },
                data: { isActive: 0 }
            });

            return {
                isValid: false,
                reason: `This item is no longer available. ${reason}`
            };
        }

        return { isValid: true };

    } catch (error) {
        console.error('Error validating menu item time:', error);
        return { isValid: false, reason: "Error validating menu item" };
    }
}


/**
 * Filter menu items array by checking their time / date-time windows.
 * Deactivates expired items and returns only valid ones.
 * @param {Array} menuItems - Array of menu items with kitchen.timezone included
 * @returns {Promise<Array>} - Filtered array of valid menu items
 */


async function filterMenuItemsByTime(menuItems) {
    const validItems = [];
    const itemsToDeactivate = [];

    for (const item of menuItems) {
        // No time/date restrictions → always valid
        if (!item.endTime && !item.endTimeDate) {
            validItems.push(item);

            continue;
        }

        const timezoneName = item.kitchen?.timezone?.name || "Australia/Sydney";
        const { shouldDeactivate } = evaluateExpiry(item, timezoneName);

        if (shouldDeactivate) {
            itemsToDeactivate.push(item.id);
        } else {
            validItems.push(item);
        }
    }

    // Deactivate expired items in batch
    if (itemsToDeactivate.length > 0) {
        await prisma.menuItem.updateMany({
            where: { id: { in: itemsToDeactivate } },
            data: { isActive: 0 }
        });
        console.log(`⏰ [MENU] Deactivated ${itemsToDeactivate.length} expired menu items`);
    }

    return validItems;
}

/**
 * Mark expired menu items as inactive but return ALL items (for vendor management).
 * Unlike filterMenuItemsByTime, this doesn't filter out items - just marks them inactive.
 * @param {Array} menuItems - Array of menu items with kitchen.timezone included
 * @returns {Promise<Array>} - All menu items with updated isActive status
 */
async function markExpiredMenuItems(menuItems) {
    const itemsToDeactivate = [];

    for (const item of menuItems) {
        // No time/date restrictions → skip
        if (!item.endTime && !item.endTimeDate) {
            continue;
        }

        const timezoneName = item.kitchen?.timezone?.name || "Australia/Sydney";
        const { shouldDeactivate } = evaluateExpiry(item, timezoneName);

        if (shouldDeactivate && item.isActive === 1) {
            itemsToDeactivate.push(item.id);
            // Update the item object in memory so response reflects the change
            item.isActive = 0;
        }
    }

    // Deactivate expired items in batch
    if (itemsToDeactivate.length > 0) {
        await prisma.menuItem.updateMany({
            where: { id: { in: itemsToDeactivate } },
            data: { isActive: 0 }
        });
        console.log(`⏰ [VENDOR] Marked ${itemsToDeactivate.length} menu items as inactive (outside time/date window)`);
    }

    // Return ALL items (including inactive ones)
    return menuItems;
}

module.exports = {
    checkExpiredMenuItems,
    validateMenuItemTime,
    filterMenuItemsByTime,
    markExpiredMenuItems,
    evaluateExpiry
};
