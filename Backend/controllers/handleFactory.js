const prisma = require("../utils/prisma");

/**
 * Helper to calculate total boxes available for a kitchen today
 * Sums quantites of all active items that haven't reached their endTime
 */
function determineKitchenTotalQuantity(kitchen) {
    if (!Array.isArray(kitchen.items) || kitchen.items.length === 0) return 0;

    // Get current time in kitchen's local time
    const now = new Date();
    const timezoneOffset = kitchen.timezone?.offset || '+10:00';
    const sign = timezoneOffset[0] === '+' ? 1 : -1;
    const [hours, minutes] = timezoneOffset.slice(1).split(':').map(Number);
    const offsetMinutes = sign * (hours * 60 + minutes);
    const kitchenLocalTime = new Date(now.getTime() + offsetMinutes * 60 * 1000);

    return kitchen.items.reduce((total, item) => {
        // Skip if endTime has passed (ignore startTime)
        if (item.endTime) {
            const [endHours, endMinutes] = item.endTime.split(':').map(Number);
            const endDateTime = new Date(kitchenLocalTime);
            endDateTime.setHours(endHours, endMinutes, 0, 0);
            if (kitchenLocalTime >= endDateTime) return total;
        }
        return total + (item.quantity > 0 ? item.quantity : 0);
    }, 0);
}
exports.determineKitchenTotalQuantity = determineKitchenTotalQuantity;


/**
 * Format product with images + owner details (Brand Owner / Wholesaler)
 */
const MENU_S3 = process.env.menu_s3 || "";
const CATEGORY_S3 = process.env.categories_s3 || "";
const CUISINE_S3 = process.env.cuisines_s3 || "";
const KITCHEN_IMG = process.env.kitchen_s3 || "";
const PROFILE_IMG = process.env.user_s3 || "";
const CHEF_IMG = process.env.chef_s3 || "";

exports.formatMenuItem = async (item) => {
    return {
        id: item.id,
        name: item.name,
        quantity: item.quantity,
        price: item.price,
        discountPrice: item.discountPrice,
        description: item.description,
        image: item.image ? `${MENU_S3}${item.image}` : null,
        isVegetarian: item.isVegetarian,
        isSpicy: item.isSpicy,
        rating: item.rating,
        ratingCount: item.ratingCount,
        discountPercentage: item.discountPercentage,
        startTime: item.startTime,
        endTime: item.endTime,
        // ⭐ FIXED - correct kitchen object
        kitchen: item.kitchen
            ? {
                kitchenId: item.kitchen.kitchenId,
                kitchenName: item.kitchen.kitchenName,
                totalItemsQuantity: determineKitchenTotalQuantity(item.kitchen)
            }
            : null,
        // ⭐ Category array instead of single
        categories: Array.isArray(item.categoryIds)
            ? item.categoryIds.map(cat => ({
                id: cat.id,
                name: cat.name,
                image: cat.image ? `${CATEGORY_S3}${cat.image}` : null
            }))
            : [],
        foodtypeIds: Array.isArray(item.foodtypeIds)
            ? item.foodtypeIds.map(ft => ({
                id: ft.id,
                name: ft.name,
                image: ft.image ? `${CATEGORY_S3}${ft.image}` : null
            }))
            : [],
        foodtype: item.foodtypeIds?.[0]
            ? {
                id: item.foodtypeIds[0].id,
                name: item.foodtypeIds[0].name,
                image: item.foodtypeIds[0].image ? `${CATEGORY_S3}${item.foodtypeIds[0].image}` : null
            }
            : null
    };
};

exports.formatMenuItemWithDistance = async (item, userLat = null, userLng = null) => {
    const KITCHEN_IMG = process.env.kitchen_s3 || "";

    let distance = null;

    if (userLat && userLng && item.kitchen?.address?.latitude && item.kitchen?.address?.longitude) {
        distance = haversineDistance(
            Number(userLat),
            Number(userLng),
            Number(item.kitchen.address.latitude),
            Number(item.kitchen.address.longitude)
        );
    }

    // ⭐ Convert kitchen images JSON to URLs
    const kitchenImages = Array.isArray(item.kitchen?.photos?.kitchenImages)
        ? item.kitchen.photos.kitchenImages.map(img => `${KITCHEN_IMG}${img}`)
        : [];

    return {
        id: item.id,
        name: item.name,
        quantity: item.quantity,
        price: item.price,
        discountPrice: item.discountPrice,
        discountPercentage: item.discountPercentage,
        description: item.description,
        image: item.image ? `${MENU_S3}${item.image}` : null,
        isVegetarian: item.isVegetarian,
        isSpicy: item.isSpicy,
        rating: item.rating,
        ratingCount: item.ratingCount,
        startTime: item.startTime,
        endTime: item.endTime,

        // ⭐ Restaurant info
        // ⭐ Restaurant info
        restaurant: item.kitchen
            ? {
                kitchenId: item.kitchen.kitchenId,
                kitchenName: item.kitchen.kitchenName,
                rating: item.kitchen.rating,
                ratingCount: item.kitchen.ratingCount,
                distanceKm: distance,

                // ⭐ ADDRESS ADDED HERE
                address: item.kitchen.address
                    ? {
                        houseNo: item.kitchen.address.houseNo,
                        street: item.kitchen.address.street,
                        city: item.kitchen.address.city,
                        state: item.kitchen.address.state,
                        country: item.kitchen.address.country,
                        pincode: item.kitchen.address.pincode,
                        latitude: item.kitchen.address.latitude,
                        longitude: item.kitchen.address.longitude
                    }
                    : null,

                // ⭐ Kitchen Photos
                photos: {
                    kitchenProfilePhoto: item.kitchen.photos?.kitchenProfilePhoto
                        ? `${KITCHEN_IMG}${item.kitchen.photos.kitchenProfilePhoto}`
                        : null,
                    kitchenImages: kitchenImages
                },
                totalItemsQuantity: determineKitchenTotalQuantity(item.kitchen)
            }
            : null,
        // ⭐ Category list
        categories: Array.isArray(item.categoryIds)
            ? item.categoryIds.map(cat => ({
                id: cat.id,
                name: cat.name,
                image: cat.image ? `${CATEGORY_S3}${cat.image}` : null
            }))
            : [],
        foodtypeIds: Array.isArray(item.foodtypeIds)
            ? item.foodtypeIds.map(ft => ({
                id: ft.id,
                name: ft.name,
                image: ft.image ? `${CATEGORY_S3}${ft.image}` : null
            }))
            : [],
        foodtype: item.foodtypeIds?.[0]
            ? {
                id: item.foodtypeIds[0].id,
                name: item.foodtypeIds[0].name,
                image: item.foodtypeIds[0].image ? `${CATEGORY_S3}${item.foodtypeIds[0].image}` : null
            }
            : null
    };
};


exports.formatKitchen = async (kitchen, wishlistSet, userLat, userLng) => {
    const KITCHEN_IMG = process.env.kitchen_s3 || "";

    // Convert JSON to array & map URLs
    const kitchenImages = Array.isArray(kitchen.photos?.kitchenImages)
        ? kitchen.photos.kitchenImages.map((img) => `${KITCHEN_IMG}${img}`)
        : [];

    // ⭐ Coordinates from kitchen_address
    const kitchenLat = kitchen.address?.latitude ? Number(kitchen.address.latitude) : null;
    const kitchenLng = kitchen.address?.longitude ? Number(kitchen.address.longitude) : null;

    const distance =
        userLat && userLng && kitchenLat && kitchenLng
            ? haversineDistance(userLat, userLng, kitchenLat, kitchenLng)
            : null;

    // ⭐ Highest discount percentage among items
    let discountPercentage = 0;
    if (Array.isArray(kitchen.items) && kitchen.items.length > 0) {
        discountPercentage = Math.max(
            ...kitchen.items.map(i => i.discountPercentage || 0)
        );
    }
    // ⭐ Calculate total available items quantity and time-active status
    let totalItemsQuantity = 0;
    let hasItemsInTimeWindow = false;

    if (Array.isArray(kitchen.items) && kitchen.items.length > 0) {
        totalItemsQuantity = determineKitchenTotalQuantity(kitchen);

        // Get current time in kitchen's local time for flag check
        const now = new Date();
        const timezoneOffset = kitchen.timezone?.offset || '+10:00';
        const sign = timezoneOffset[0] === '+' ? 1 : -1;
        const [hours, minutes] = timezoneOffset.slice(1).split(':').map(Number);
        const offsetMinutes = sign * (hours * 60 + minutes);
        const kitchenLocalTime = new Date(now.getTime() + offsetMinutes * 60 * 1000);

        // Flag if any items are still valid (not expired)
        hasItemsInTimeWindow = kitchen.items.some(item => {
            if (!item.endTime) return true;
            const [endHours, endMinutes] = item.endTime.split(':').map(Number);
            const endDateTime = new Date(kitchenLocalTime);
            endDateTime.setHours(endHours, endMinutes, 0, 0);
            return kitchenLocalTime < endDateTime;
        });
    }
    return {
        kitchenId: kitchen.kitchenId,
        kitchenName: kitchen.kitchenName,
        email: kitchen.email,
        ownerName: kitchen.ownerName,
        contactNumber: kitchen.contactNumber,
        openingTime: kitchen.openingTime,
        closingTime: kitchen.closingTime,
        description: kitchen.description,
        status: kitchen.status,
        rating: kitchen.rating,
        ratingCount: kitchen.ratingCount,
        isActive: kitchen.isActive,
        createdAt: kitchen.createdAt,
        updatedAt: kitchen.updatedAt,
        isWishlist: wishlistSet.has(kitchen.kitchenId) ? 1 : 0,

        discountPercentage,
        totalItemsQuantity,
        hasItemsInTimeWindow, // ⭐ NEW FIELD

        address: kitchen.address ?? null,

        photos: kitchen.photos
            ? {
                kitchenImages,
                kitchenProfilePhoto: kitchen.photos.kitchenProfilePhoto
                    ? `${KITCHEN_IMG}${kitchen.photos.kitchenProfilePhoto}`
                    : null
            }
            : null,

        distanceKm: distance,
        cuisines: kitchen.cuisines?.map(c => c.name) ?? []
    };
};

// Haversine formula — returns distance in kilometers
function haversineDistance(lat1, lon1, lat2, lon2) {
    if (!lat1 || !lon1 || !lat2 || !lon2) return null;

    const toRad = (v) => (v * Math.PI) / 180;
    const R = 6371; // Earth radius in km
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);

    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) ** 2;

    return Number((R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))).toFixed(2));
}

exports.calculateDistance = (lat1, lon1, lat2, lon2) => {
    function toRad(value) {
        return (value * Math.PI) / 180;
    }

    const R = 6371; // km

    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);

    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    const distance = R * c;

    return Number(distance.toFixed(2));
};
const admin = require("firebase-admin");
const serviceAccount = require("../controllers/resqbox-2740d-firebase-adminsdk-fbsvc-fb62d249ba.json");


admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
}, 'resqbox');

exports.sendNotificationToUser = async (user_id, payload, deviceToken) => {
    console.log("🔔 [Notification] Checking token for user_id:", user_id);
    const messaging = admin.app('resqbox').messaging();
    console.log("🔔 [Notification] Checking token for user_id:", payload);
    const dataPayload = {
        title: String(payload.title || ''),
        body: String(payload.body || ''),
        orderId: String(payload.orderId || ''),
        status: String(payload.status || '')
    };

    const message = {
        token: deviceToken,
        data: dataPayload,
        // android: {
        //   priority: 'high',
        //   notification: {
        //     sound: 'default',
        //     clickAction: 'FLUTTER_NOTIFICATION_CLICK'
        //   }
        // },
        apns: {
            payload: {
                aps: {
                    sound: 'default',
                    badge: 1
                }
            }
        }

    };

    console.log("📦 Payload:", message);

    try {
        const response = await messaging.send(message);
        console.log("📤 [Notification] Sending message to token:", deviceToken);
        console.log("✅ [Notification] Sent successfully:", response);
        return { success: true, response };
    } catch (err) {
        console.error("❌ [Notification] Error sending notification:", err.message);

        // ⭐ Handle specific Firebase errors gracefully
        if (err.code === 'messaging/registration-token-not-registered' ||
            err.code === 'messaging/invalid-registration-token' ||
            err.code === 'messaging/invalid-argument' ||
            err.message?.includes('Requested entity was not found')) {
            console.log("💡 [NOTIFICATION] Device token is invalid/expired. Consider clearing it from database.");
            console.log("   User ID:", user_id);
            console.log("   Token:", deviceToken?.substring(0, 20) + "...");
            console.log("   Error:", err.message);
            // ⭐ Don't throw - just return failure status
            return { success: false, error: 'Invalid or expired token' };
        }

        // ⭐ For other errors, log but don't crash
        console.error("⚠️  [NOTIFICATION] Unexpected notification error:", err);
        return { success: false, error: err.message };
    }
};

/**
 * Send notification to all device tokens of a kitchen
 */
exports.sendNotificationToKitchen = async (kitchenId, payload) => {
    try {
        const kitchen = await prisma.kitchen.findUnique({
            where: { kitchenId: Number(kitchenId) },
            select: { deviceToken: true, deviceTokens: true }
        });

        if (!kitchen) {
            return { success: false, error: "Kitchen not found" };
        }

        // Collect all unique tokens
        const tokens = new Set();
        if (kitchen.deviceToken) tokens.add(kitchen.deviceToken);

        if (Array.isArray(kitchen.deviceTokens)) {
            kitchen.deviceTokens.forEach(t => {
                if (t && typeof t === 'string') tokens.add(t);
            });
        }

        const tokenList = Array.from(tokens);

        if (tokenList.length === 0) {
            return { success: false, error: "No device tokens found" };
        }

        console.log(`🔔 [Notification] Sending to ${tokenList.length} tokens for kitchen ${kitchenId}`);

        const results = await Promise.allSettled(
            tokenList.map(token => exports.sendNotificationToUser(kitchenId, payload, token))
        );

        const successCount = results.filter(r => r.status === 'fulfilled' && r.value.success).length;
        const failureCount = tokenList.length - successCount;

        return {
            success: successCount > 0,
            totalTokens: tokenList.length,
            successCount,
            failureCount
        };
    } catch (error) {
        console.error("❌ [sendNotificationToKitchen] Error:", error);
        return { success: false, error: error.message };
    }
};
