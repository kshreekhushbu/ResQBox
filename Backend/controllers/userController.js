const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const catchAsync = require("../utils/catchAsync");
const prisma = require("../utils/prisma");
const handleFactory = require("./handleFactory");
const { noSniff } = require("helmet");
const { config } = require("dotenv");
const { json } = require("express");
const { getIO } = require("../utils/socket");

/**
 * Parse device date string to JavaScript Date object
 * Handles formats like: "2026-01-22 15:07:23.591032"
 */
const parseDeviceDate = (dateString) => {
    if (!dateString) return new Date();

    try {
        // Replace space with 'T' to make it ISO 8601 compatible
        const isoString = dateString.replace(' ', 'T');
        const date = new Date(isoString);

        // Check if date is valid
        if (isNaN(date.getTime())) {
            console.warn('Invalid date string:', dateString, '- using current time');
            return new Date();
        }

        return date;
    } catch (error) {
        console.error('Error parsing device date:', error);
        return new Date();
    }
};

// exports.sendOtp = catchAsync(async (req, res) => {
//     const { email } = req.body;
//     console.log("emailId:", email)
//     if (!email) {
//         return res.status(400).json({
//             status: 0,
//             message: "Email is required"
//         });
//     }
//     // check user is there or not throw error to signup first
//     isExist = await prisma.user.findUnique({
//         where: { email }
//     });
//     if (!isExist) {
//         return res.status(400).json({
//             status: 0,
//             message: "User does not exists, please signup"
//         });
//     }


//     let otp = '123456';
//     if (process.env.NODE_ENV !== 'development') {
//         otp = Math.floor(100000 + Math.random() * 900000).toString();
//     }

//     // Create or update OTP
//     await prisma.verifyEmail.upsert({
//         where: { email },
//         update: {
//             otp,
//             isVerified: 0,
//             status: 1
//         },
//         create: {
//             email,
//             otp
//         }
//     });

//     // ❗ SEND OTP EMAIL HERE

//     return res.status(200).json({
//         status: 1,
//         message: "OTP sent successfully",
//     });
// });


exports.verifyOtp = catchAsync(async (req, res) => {
    const { email, otp, deviceToken } = req.body;

    if (!email || !otp) {
        return res.status(400).json({
            status: 0,
            message: "Email and OTP are required"
        });
    }

    const record = await prisma.verifyEmail.findFirst({
        where: {
            email,
            otp,
            isVerified: 0,
            status: 1
        }
    });

    console.log("record:", record)
    if (!record) {
        return res.status(400).json({
            status: 0,
            message: "Invalid OTP"
        });
    }

    // Mark OTP as verified
    await prisma.verifyEmail.update({
        where: { email },
        data: { isVerified: 1 }
    });

    // Check if user exists
    const user = await prisma.user.findUnique({
        where: { email }
    });

    if (!user) {
        return res.status(200).json({
            status: 1,
            message: "OTP verified successfully, please signup",
            isExist: 0,
            token: null
        });
    }

    // Update device token
    if (deviceToken) {
        await prisma.user.update({
            where: { userId: user.userId },
            data: { deviceToken }
        });
    }

    // Generate login token
    const token = jwt.sign(
        { userId: user.userId },
        process.env.JWT_SECRET_KEY,
        { expiresIn: "10d" }
    );

    // ⭐ Handle Pending Account Requests (e.g., self-deletion appeal)
    const pendingDeleteRequest = await prisma.userAccountRequest.findFirst({
        where: {
            userId: user.userId,
            requestType: "DELETE",
            status: "PENDING"
        }
    });

    if (pendingDeleteRequest) {
        await prisma.userAccountRequest.update({
            where: { id: pendingDeleteRequest.id },
            data: { status: "CANCELLED" }
        });

        await prisma.user.update({
            where: { userId: user.userId },
            data: { status: "ACTIVE", isActive: 1 }
        });
        console.log(`✅ [USER LOGIN] Self-deletion request cancelled for user ${user.userId}`);
    }

    return res.status(200).json({
        status: 1,
        message: "Login successful",
        isExist: 1,
        token,

    });
});

exports.sendSignupOtp = catchAsync(async (req, res) => {
    const { email } = req.body;
    console.log("email:", email)
    if (!email) {
        return res.status(400).json({
            status: 0,
            message: "Email is required"
        });
    }

    isExist = await prisma.user.findUnique({
        where: { email }
    });
    if (isExist) {
        if (isExist.status === "INACTIVE") {
            return res.status(200).json({
                status: 2,
                message: "Your account is inactive. Please contact support."
            });
        }
        return res.status(400).json({
            status: 0,
            message: "User already exists, Please login"
        });
    }

    let otp = '123456';
    if (process.env.NODE_ENV !== 'development') {
        otp = Math.floor(100000 + Math.random() * 900000).toString();
    }

    // Create or update OTP
    await prisma.verifyEmail.upsert({
        where: { email },
        update: {
            otp,
            isVerified: 0,
            status: 1
        },
        create: {
            email,
            otp
        }
    });

    // Send OTP via email (only in production)
    if (process.env.NODE_ENV === 'production') {
        const { sendUserSignupOTP } = require('../utils/emailService');
        const emailResult = await sendUserSignupOTP(email, otp);

        if (emailResult.success) {
            console.log(`✅ Signup OTP sent to ${email}`);
        } else {
            console.error(`❌ Failed to send signup OTP to ${email}:`, emailResult.error);
        }
    } else {
        console.log(`🔐 [USER SIGNUP] OTP for ${email}: ${otp} (Development mode - email not sent)`);
    }

    return res.status(200).json({
        status: 1,
        message: "OTP sent successfully",
    });


});

exports.sendOtp = catchAsync(async (req, res) => {
    const { email } = req.body;
    console.log("emailId:", email)
    if (!email) {
        return res.status(400).json({
            status: 0,
            message: "Email is required"
        });
    }

    // Check user exists or not
    const isExist = await prisma.user.findUnique({
        where: { email }
    });

    if (!isExist) {
        return res.status(400).json({
            status: 0,
            message: "User not found, Please Sign Up."
        });
    }

    // Check if user is INACTIVE (Admin block)
    if (isExist.status === "INACTIVE") {
        return res.status(200).json({
            status: 2,
            message: "Your account is inactive. Please contact support."
        });
    }

    // Generate OTP
    let otp = '123456';

    // Use default OTP for test account or development mode
    if (email !== 'sriharsha@mtouchlabs.com' && process.env.NODE_ENV !== 'development') {
        otp = Math.floor(100000 + Math.random() * 900000).toString();
    }

    // Create or update OTP
    await prisma.verifyEmail.upsert({
        where: { email },
        update: {
            otp,
            isVerified: 0,
            status: 1
        },
        create: {
            email,
            otp
        }
    });

    // Send OTP via email (only in production and not for test account)
    if (process.env.NODE_ENV === 'production' && email !== 'sriharsha@mtouchlabs.com') {
        const { sendUserLoginOTP } = require('../utils/emailService');
        const emailResult = await sendUserLoginOTP(email, otp);

        if (emailResult.success) {
            console.log(`✅ Login OTP sent to ${email}`);
        } else {
            console.error(`❌ Failed to send login OTP to ${email}:`, emailResult.error);
        }
    } else if (email === 'sriharsha@mtouchlabs.com') {
        console.log(`🔐 [TEST ACCOUNT] OTP for ${email}: ${otp} (Email not sent - test account)`);
    } else {
        console.log(`🔐 [USER LOGIN] OTP for ${email}: ${otp} (Development mode - email not sent)`);
    }

    return res.status(200).json({
        status: 1,
        message: "OTP sent successfully",
    });
});

exports.signup = catchAsync(async (req, res) => {
    const { phoneNumber, firstName, lastName, email, profilePicture, deviceToken, otp, countryCode } = req.body;

    console.log("body:", req.body)

    // ⭐ Only email and otp are required
    if (!email || !otp) {
        return res.status(400).json({
            status: 0,
            message: "Email and OTP are required"
        });
    }

    // verify otp
    const verifyOtp = await prisma.verifyEmail.findUnique({
        where: { email }
    });
    if (!verifyOtp || verifyOtp.otp !== otp) {

        return res.status(400).json({
            status: 0,
            message: "Invalid OTP"
        });
    }

    const existing = await prisma.user.findUnique({
        where: { email }
    });

    if (existing) {
        if (existing.status === "INACTIVE") {
            return res.status(200).json({
                status: 2,
                message: "Your account is inactive. Please contact support."
            });
        }
        return res.status(400).json({
            status: 0,
            message: "User already exists"
        });
    }

    const newUser = await prisma.user.create({
        data: {
            phoneNumber: phoneNumber || null,
            name: firstName || null,
            lastName: lastName || null,
            email,
            profilePicture: profilePicture || null,
            deviceToken: deviceToken || null,
            countryCode: countryCode || null
        }
    });

    // Send welcome email (only in production)
    if (process.env.NODE_ENV === 'production') {
        const { sendUserWelcomeEmail } = require('../utils/emailService');
        const userName = firstName || 'User';
        const emailResult = await sendUserWelcomeEmail(email, userName);

        if (emailResult.success) {
            console.log(`✅ Welcome email sent to ${email}`);
        } else {
            console.error(`❌ Failed to send welcome email to ${email}:`, emailResult.error);
        }
    }

    // Generate login token
    const token = jwt.sign(
        { userId: newUser.userId },
        process.env.JWT_SECRET_KEY,
        { expiresIn: "10d" }
    );

    return res.status(200).json({
        status: 1,
        message: "Signup successful",
        token
    });
});


/**
 * Guest Login - Create or retrieve user account based on deviceId
 * All fields except deviceId will be set to "NA"
 */
exports.guestLogin = catchAsync(async (req, res) => {
    const { deviceId, deviceToken } = req.body;

    console.log("Guest Login Request:", { deviceId, deviceToken });

    // Validate deviceId
    if (!deviceId) {
        return res.status(400).json({
            status: 0,
            message: "deviceId is required"
        });
    }

    // Check if user with this deviceId already exists
    let user = await prisma.user.findUnique({
        where: { deviceId }
    });

    // If user exists, update deviceToken if provided and return existing user
    if (user) {
        // Update device token if provided
        if (deviceToken && deviceToken !== user.deviceToken) {
            user = await prisma.user.update({
                where: { userId: user.userId },
                data: { deviceToken }
            });
        }

        // Generate login token
        const token = jwt.sign(
            { userId: user.userId },
            process.env.JWT_SECRET_KEY,
            { expiresIn: "10d" }
        );

        return res.status(200).json({
            status: 1,
            message: "Guest login successful",
            token,
            isNewUser: false,
            userId: user.userId
        });
    }

    // Create new guest user with all fields as "NA" except deviceId
    const newUser = await prisma.user.create({
        data: {
            deviceId,
            phoneNumber: "NA",
            name: "NA",
            lastName: "NA",
            email: null, // Email must be unique, so we keep it null for guests
            profilePicture: "NA",
            deviceToken: deviceToken || null,
            countryCode: "NA",
            authProvider: "GUEST"
        }
    });

    console.log(`✅ New guest user created with deviceId: ${deviceId}, userId: ${newUser.userId}`);

    // Generate login token
    const token = jwt.sign(
        { userId: newUser.userId },
        process.env.JWT_SECRET_KEY,
        { expiresIn: "10d" }
    );

    return res.status(200).json({
        status: 1,
        message: "Guest account created successfully",
        token,
        isNewUser: true,
        userId: newUser.userId
    });
});


exports.getFoodType = catchAsync(async (req, res) => {
    const CATEGORY_S3 = process.env.categories_s3 || "";

    const foodTypes = await prisma.foodtype.findMany({
        where: {
            isActive: 1
        },
        orderBy: { id: "asc" }
    });

    const formatted = foodTypes.map(ft => ({
        id: ft.id,
        name: ft.name,
        image: ft.image ? `${CATEGORY_S3}${ft.image}` : null,
        question: ft.question,
        type: ft.type
    }));

    return res.status(200).json({
        status: 1,
        message: "Food type fetched successfully",
        kitchenFoodType: formatted.filter(ft => ft.type === "KITCHEN"),
        menuFoodType: formatted.filter(ft => ft.type === "MENU")
    });
});

exports.homePage = catchAsync(async (req, res) => {
    const { userId } = req.user || {};
    const { latitude, longitude } = req.query;

    const BANNER_S3 = process.env.banners_s3 || "";
    const CATEGORY_S3 = process.env.categories_s3 || "";
    const CUISINE_S3 = process.env.cuisines_s3 || "";
    const PRODUCT_S3 = process.env.product_s3 || "";

    // ⭐ Update User Location
    if (userId && (latitude || longitude)) {
        await prisma.user.update({
            where: { userId: Number(userId) },
            data: {
                latitude: latitude ? Number(latitude) : undefined,
                longitude: longitude ? Number(longitude) : undefined
            }
        }).catch(() => { });
    }

    // Convert to numbers for distance calculations
    const userLat = latitude ? Number(latitude) : null;
    const userLng = longitude ? Number(longitude) : null;

    // ⭐ Fetch Distance Limit from Config
    const distanceConfig = await prisma.config.findFirst({
        where: { configKey: "Distance Limit" }
    });
    const distanceLimitKm = distanceConfig?.configValue ? Number(distanceConfig.configValue) : 50; // Default 50km

    // ⭐ Categories
    const rawCategories = await prisma.category.findMany({
        where: { isActive: 1, isPopular: 1 },
        select: { id: true, name: true, image: true }
    });

    const categories = rawCategories.map(c => ({
        ...c,
        image: c.image ? `${CATEGORY_S3}${c.image}` : null
    }));

    // ⭐ Banners
    const rawBanners = await prisma.banner.findMany({
        where: { isActive: 1 },
        select: { bannerId: true, banner: true },
        orderBy: { createdAt: "desc" },
    });

    const banners = rawBanners.map(b => ({
        ...b,
        banner: b.banner ? `${BANNER_S3}${b.banner}` : null,
    }));

    // ⭐ Cuisines
    const rawCuisines = await prisma.cuisine.findMany({
        where: { isActive: 1, isPopular: 1 },
        take: 3,
        select: { id: true, name: true, image: true }
    });

    const cuisines = rawCuisines.map(c => ({
        ...c,
        image: c.image ? `${CUISINE_S3}${c.image}` : null
    }));

    // ⭐ Wishlist Kitchens ID List
    let wishlistIds = [];
    if (userId) {
        const wishlist = await prisma.wishlist.findMany({
            where: { userId: Number(userId) },
            select: { kitchenId: true },
        });
        wishlistIds = wishlist.map(w => w.kitchenId);
    }
    const wishlistSet = new Set(wishlistIds);

    // ⭐ Wishlisted Kitchens (Full Detail)
    let wishlistKitchens = [];
    if (wishlistIds.length > 0) {
        const wishlistKitchensRaw = await prisma.kitchen.findMany({
            where: { kitchenId: { in: wishlistIds }, isActive: 1, status: "APPROVED" },
            take: 4,
            include: {
                photos: true,
                address: true,
                cuisines: true,
                timezone: true,  // ⭐ Include timezone for time validation
                items: {
                    where: { isActive: 1 },  // ⭐ Only fetch active items
                    select: {
                        id: true,
                        discountPercentage: true,
                        quantity: true,
                        startTime: true,  // ⭐ Include startTime to check availability
                        endTime: true  // ⭐ Include endTime to check expiry
                    }
                }
            }
        });

        // ⭐ Format kitchens with distance
        let formattedWishlistKitchens = await Promise.all(
            wishlistKitchensRaw.map(k =>
                handleFactory.formatKitchen(k, wishlistSet, userLat, userLng)
            )
        );

        // ⭐ Filter by distance limit (only exclude if distance IS known AND exceeds limit)
        wishlistKitchens = formattedWishlistKitchens.filter(k => {
            return !userLat || !userLng || k.distanceKm === null || k.distanceKm <= distanceLimitKm;
        });

        // ⭐ Sort: Available Boxes first, then by distance
        wishlistKitchens.sort((a, b) => {
            const aHasBoxes = a.totalItemsQuantity > 0 ? 1 : 0;
            const bHasBoxes = b.totalItemsQuantity > 0 ? 1 : 0;
            if (aHasBoxes !== bHasBoxes) return bHasBoxes - aHasBoxes;
            return (a.distanceKm ?? Infinity) - (b.distanceKm ?? Infinity);
        });

        wishlistKitchens = wishlistKitchens.slice(0, 4);
    }

    // // ⭐ Popular Kitchens based on Orders count (Top 6)
    const TOP = 6;

    // ⭐ Popular Products (rating DESC) - Fetch all first, then filter by time and distance
    const { filterMenuItemsByTime } = require("../cron/menuItemExpiryChecker");

    const popularProductsRaw = await prisma.menuItem.findMany({
        where: { isActive: 1 },
        orderBy: { rating: "desc" },
        include: {
            categoryIds: true,
            foodtypeIds: true, // ⭐ Include foodtypes
            kitchen: {
                include: {
                    address: true,
                    photos: true,
                    timezone: true, // ⭐ Include timezone for time validation
                    items: {
                        where: { isActive: 1 },
                        select: {
                            id: true,
                            quantity: true,
                            startTime: true,
                            endTime: true
                        }
                    }
                },
                where: {
                    status: "APPROVED",
                }
            }
        }
    });

    // ⭐ Filter out expired items based on endTime
    const validPopularProducts = await filterMenuItemsByTime(popularProductsRaw);

    // ⭐ Filter out items with 0 quantity
    const availablePopularProducts = validPopularProducts.filter(item => item.quantity > 0);

    // Format with distance and filter by distance limit
    let popularProducts = await Promise.all(
        availablePopularProducts.map(async (item) => await handleFactory.formatMenuItemWithDistance(item, userLat, userLng))
    );

    // Filter by distance limit and sort by nearest first
    if (userLat && userLng) {
        popularProducts = popularProducts
            // Only exclude if distance IS calculated and exceeds the limit
            .filter(item => item.restaurant && (item.restaurant.distanceKm === null || item.restaurant.distanceKm <= distanceLimitKm))
            .sort((a, b) => (a.restaurant?.distanceKm ?? Infinity) - (b.restaurant?.distanceKm ?? Infinity))
            .slice(0, 4);
    } else {
        popularProducts = popularProducts.slice(0, 4);
    }

    // ⭐ Top Rated Products (rating & count priority) - Filter by time and distance
    const topRatedProductsRaw = await prisma.menuItem.findMany({
        where: { isActive: 1 },
        orderBy: [
            { rating: "desc" },
            { ratingCount: "desc" }
        ],
        include: {
            categoryIds: true,
            foodtypeIds: true, // ⭐ Include foodtypes
            kitchen: {
                include: {
                    address: true,
                    photos: true,
                    timezone: true, // ⭐ Include timezone for time validation
                    items: {
                        where: { isActive: 1 },
                        select: {
                            id: true,
                            quantity: true,
                            startTime: true,
                            endTime: true
                        }
                    }
                },
                where: {
                    status: "APPROVED",
                }
            }
        }
    });

    // ⭐ Filter out expired items based on endTime
    const validTopRatedProducts = await filterMenuItemsByTime(topRatedProductsRaw);

    // ⭐ DON'T filter by quantity - show items even with quantity=0 if time is valid

    // Format with distance and filter by distance limit
    let topRatedProducts = await Promise.all(
        validTopRatedProducts.map(async (item) => await handleFactory.formatMenuItemWithDistance(item, userLat, userLng))
    );

    // Filter by distance limit and sort by nearest first
    if (userLat && userLng) {
        topRatedProducts = topRatedProducts
            // Only exclude if distance IS calculated and exceeds the limit
            .filter(item => item.restaurant && (item.restaurant.distanceKm === null || item.restaurant.distanceKm <= distanceLimitKm))
            .sort((a, b) => (a.restaurant?.distanceKm ?? Infinity) - (b.restaurant?.distanceKm ?? Infinity))
            .slice(0, TOP);
    } else {
        topRatedProducts = topRatedProducts.slice(0, TOP);
    }


    // ⭐ Active Restaurants - Fetch all first, then filter by distance
    const activeRestaurantsRaw = await prisma.kitchen.findMany({
        where: { isActive: 1, status: "APPROVED" },
        include: {
            photos: true,
            address: true,
            cuisines: true,
            timezone: true,  // ⭐ Include timezone for time validation
            items: {
                where: { isActive: 1 },  // ⭐ Only fetch active items
                select: {
                    id: true,
                    discountPercentage: true,
                    quantity: true,
                    startTime: true,  // ⭐ Include startTime to check availability
                    endTime: true  // ⭐ Include endTime to check expiry
                }
            }
        }
    });

    // Format with distance and filter by distance limit
    let activeRestaurants = await Promise.all(
        activeRestaurantsRaw.map(k =>
            handleFactory.formatKitchen(k, wishlistSet, userLat, userLng)
        )
    );

    // ⭐ Apply distance limit restriction (only exclude if distance IS known AND exceeds limit)
    activeRestaurants = activeRestaurants.filter(k => {
        return !userLat || !userLng || k.distanceKm === null || k.distanceKm <= distanceLimitKm;
    });

    // ⭐ Custom Sorting:
    // 1. Nearby + Available boxes
    // 2. Available Boxes (km < limit)
    // 3. Nearby + 0 Boxes
    // 4. 0 Boxes
    activeRestaurants.sort((a, b) => {
        const aHasBoxes = a.totalItemsQuantity > 0 ? 1 : 0;
        const bHasBoxes = b.totalItemsQuantity > 0 ? 1 : 0;

        // Condition 1 & 2 vs 3 & 4 (Available boxes vs 0 boxes)
        if (aHasBoxes !== bHasBoxes) return bHasBoxes - aHasBoxes;

        // If both have boxes OR both have 0 boxes, sort by distance (Nearby first)
        return (a.distanceKm ?? Infinity) - (b.distanceKm ?? Infinity);
    });

    activeRestaurants = activeRestaurants.slice(0, 4);

    //two keys i have to give 1-- howmany order he order, and howmuch discount he get

    let totalOrders = 0;
    let totalDiscount = 0;

    if (userId) {
        const orderStats = await prisma.order.aggregate({
            where: {
                userId: Number(userId),
                status: {
                    not: "REJECTED"
                }
            },
            _count: {
                orderId: true
            },
            _sum: {
                discount: true
            }
        });

        totalOrders = orderStats._count.orderId || 0;
        totalDiscount = orderStats._sum.discount || 0;
    }


    let co2Message = null;
    let discountMessage = null;

    if (totalOrders > 0) {
        const co2SavedKg = totalOrders; // 1 order = 1kg CO₂ (adjust if needed)

        // co2Message = `Great job! Your order of ${totalOrders} boxes saved ${co2SavedKg}kg of CO₂ 🌳`;
        co2Message = `Small action, big impact! You helped aviod ${co2SavedKg}kg of CO₂e emissions from your orders 🌳`;

        if (totalDiscount > 0) {
            discountMessage = `You saved $${totalDiscount} on your orders! Keep Ordering Keep Saving.....🎉`;
        }
    }

    // ⭐ Final Output
    res.json({
        status: 1,
        message: "Home page data fetched successfully",
        categories,
        cuisines,
        wishlistKitchens,
        popularProducts,
        topRatedProducts,      // 🏆 NEW
        activeRestaurants,
        co2Message,
        discountMessage
    });
});

exports.getActiveRestaurants = catchAsync(async (req, res) => {
    const { userId, latitude: storedLat, longitude: storedLng } = req.user || {};
    const { latitude: queryLat, longitude: queryLng } = req.query;

    // Use user's stored location if available, otherwise fall back to query params
    const latitude = storedLat || queryLat;
    const longitude = storedLng || queryLng;

    // ⭐ Update user location (optional, same as home)
    if (userId && (latitude || longitude)) {
        await prisma.user.update({
            where: { userId: Number(userId) },
            data: {
                latitude: latitude ? Number(latitude) : undefined,
                longitude: longitude ? Number(longitude) : undefined
            }
        }).catch(() => { });
    }

    // Convert to numbers for distance calculations
    const userLat = latitude ? Number(latitude) : null;
    const userLng = longitude ? Number(longitude) : null;

    // ⭐ Fetch Distance Limit from Config
    const distanceConfig = await prisma.config.findFirst({
        where: { configKey: "Distance Limit" }
    });
    const distanceLimitKm = distanceConfig?.configValue ? Number(distanceConfig.configValue) : 50; // Default 50km

    // ⭐ Wishlist kitchens
    let wishlistIds = [];
    if (userId) {
        const wishlist = await prisma.wishlist.findMany({
            where: { userId: Number(userId) },
            select: { kitchenId: true }
        });
        wishlistIds = wishlist.map(w => w.kitchenId);
    }
    const wishlistSet = new Set(wishlistIds);

    // ⭐ Active Restaurants
    const activeRestaurantsRaw = await prisma.kitchen.findMany({
        where: { isActive: 1, status: "APPROVED" },
        include: {
            photos: true,
            address: true,
            cuisines: true,
            timezone: true,  // ⭐ Include timezone for time validation
            items: {
                where: { isActive: 1 },  // ⭐ Only fetch active items
                select: {
                    id: true,
                    discountPercentage: true,
                    quantity: true,
                    startTime: true,  // ⭐ Include startTime to check availability
                    endTime: true  // ⭐ Include endTime to check expiry
                }
            }
        }
    });

    // ⭐ Format all restaurants (don't filter by quantity - frontend will handle display)
    let activeRestaurants = await Promise.all(
        activeRestaurantsRaw.map(k =>
            handleFactory.formatKitchen(k, wishlistSet, userLat, userLng)
        )
    );

    // ⭐ Apply distance limit restriction
    activeRestaurants = activeRestaurants.filter(k => {
        return !userLat || !userLng || (k.distanceKm !== null && k.distanceKm <= distanceLimitKm);
    });

    // ⭐ Custom Sorting (same as homePage):
    // 1. Available boxes first (quantity > 0)
    // 2. Then by distance (nearest first)
    // 3. Then 0 boxes (greyed out on frontend)
    activeRestaurants.sort((a, b) => {
        const aHasBoxes = a.totalItemsQuantity > 0 ? 1 : 0;
        const bHasBoxes = b.totalItemsQuantity > 0 ? 1 : 0;

        // If both have boxes OR both have 0 boxes, sort by distance
        if (aHasBoxes !== bHasBoxes) return bHasBoxes - aHasBoxes;

        // Sort by distance (nearest first)
        return (a.distanceKm ?? Infinity) - (b.distanceKm ?? Infinity);
    });

    return res.json({
        status: 1,
        message: "Active restaurants fetched successfully",
        data: activeRestaurants
    });
});


exports.getPopularProducts = catchAsync(async (req, res) => {
    const { latitude: storedLat, longitude: storedLng } = req.user || {};
    const { latitude: queryLat, longitude: queryLng } = req.query;

    // Use user's stored location if available, otherwise fall back to query params
    const latitude = storedLat || queryLat;
    const longitude = storedLng || queryLng;
    const TOP = 6;
    const { filterMenuItemsByTime } = require("../cron/menuItemExpiryChecker");

    // Convert to numbers for distance calculations
    const userLat = latitude ? Number(latitude) : null;
    const userLng = longitude ? Number(longitude) : null;

    // ⭐ Fetch Distance Limit from Config
    const distanceConfig = await prisma.config.findFirst({
        where: { configKey: "Distance Limit" }
    });
    const distanceLimitKm = distanceConfig?.configValue ? Number(distanceConfig.configValue) : 50; // Default 50km

    // ⭐ Popular Products (rating DESC)
    const popularProductsRaw = await prisma.menuItem.findMany({
        where: { isActive: 1 },
        orderBy: { rating: "desc" },
        include: {
            categoryIds: true,
            foodtypeIds: true,
            kitchen: {
                include: {
                    address: true,
                    photos: true,
                    timezone: true, // ⭐ Include timezone for time validation
                    items: {
                        where: { isActive: 1 },
                        select: {
                            id: true,
                            quantity: true,
                            startTime: true,
                            endTime: true
                        }
                    }
                },
                where: {
                    status: "APPROVED",
                }
            }
        }
    });

    // ⭐ Filter out expired items based on endTime
    const validPopularProducts = await filterMenuItemsByTime(popularProductsRaw);

    // ⭐ Filter out items with 0 quantity
    const availablePopularProducts = validPopularProducts.filter(item => item.quantity > 0);

    let popularProducts = await Promise.all(
        availablePopularProducts.map(item =>
            handleFactory.formatMenuItemWithDistance(item, userLat, userLng)
        )
    );

    // Filter by distance limit and sort by nearest first
    if (userLat && userLng) {
        popularProducts = popularProducts
            .filter(item => item.restaurant && item.restaurant.distanceKm !== null && item.restaurant.distanceKm <= distanceLimitKm)
            .sort((a, b) => (a.restaurant?.distanceKm ?? Infinity) - (b.restaurant?.distanceKm ?? Infinity))
            .slice(0, TOP);
    } else {
        popularProducts = popularProducts.slice(0, TOP);
    }

    return res.json({
        status: 1,
        message: "Popular products fetched successfully",
        data: popularProducts
    });
});




exports.getAllCategories = catchAsync(async (req, res) => {

    const CATEGORY_S3 = process.env.categories_s3 || "";

    // Fetch active categories with their menu items
    const categories = await prisma.category.findMany({
        where: { isActive: 1 },
        orderBy: { id: "asc" },
        include: {
            items: {
                where: { isActive: 1 },
                select: { id: true }
            }
        }
    });

    // Filter categories that have at least one active menu item
    const categoriesWithProducts = categories.filter(cat =>
        cat.items && cat.items.length > 0
    );

    // Format response (attach image URL)
    const formatted = categoriesWithProducts.map(cat => ({
        id: cat.id,
        name: cat.name,
        image: cat.image ? `${CATEGORY_S3}${cat.image}` : null,
        isActive: cat.isActive,
        createdAt: cat.createdAt,
        updatedAt: cat.updatedAt
    }));

    return res.status(200).json({
        status: 1,
        message: "Categories fetched successfully",
        categories: formatted
    });
});

exports.getAllCuisine = catchAsync(async (req, res) => {
    const CUISINES_S3 = process.env.cuisines_s3 || "";

    // Fetch active categories
    const categories = await prisma.category.findMany({
        where: { isActive: 1 },
        orderBy: { id: "asc" }
    });

    // Format response (attach image URL)
    const formatted = categories.map(cat => ({
        id: cat.id,
        name: cat.name,
        image: cat.image ? `${CUISINES_S3}${cat.image}` : null,
        isActive: cat.isActive,
        createdAt: cat.createdAt,
        updatedAt: cat.updatedAt
    }));

    return res.status(200).json({
        status: 1,
        message: "Cuisines fetched successfully",
        categories: formatted
    });
});

// exports.getMenu = catchAsync(async (req, res) => {
//     const { kitchenId, categoryId, foodtypeId } = req.query;
//     const { userId, latitude: storedLat, longitude: storedLng } = req.user || {};
//     const { latitude: queryLat, longitude: queryLng } = req.query;

//     // Use user's stored location if available, otherwise fall back to query params
//     const latitude = storedLat || queryLat;
//     const longitude = storedLng || queryLng;
//     const BASE_URL = process.env.menu_s3 || "";
//     const { filterMenuItemsByTime } = require("../cron/menuItemExpiryChecker");

//     // Convert to numbers for distance calculations
//     const userLat = latitude ? Number(latitude) : null;
//     const userLng = longitude ? Number(longitude) : null;

//     // ⭐ Fetch Distance Limit from Config
//     const distanceConfig = await prisma.config.findFirst({
//         where: { configKey: "Distance Limit" }
//     });
//     const distanceLimitKm = distanceConfig?.configValue ? Number(distanceConfig.configValue) : 50; // Default 50km

//     // ⭐ Build where condition
//     const where = {
//         isActive: 1,
//         kitchen: {
//             status: "APPROVED"
//         }
//     };

//     if (kitchenId) where.kitchenId = Number(kitchenId);

//     // ⭐ If multiple categories received (comma separated)
//     if (categoryId) {
//         const ids = categoryId.split(",").map(id => Number(id.trim()));

//         where.categoryIds = {
//             some: { id: { in: ids } }
//         };
//     }

//     // ⭐ Filter by kitchen's foodtype (not menuItem's foodtype)
//     if (foodtypeId) {
//         where.kitchen = {
//             ...where.kitchen,
//             foodtypes: {
//                 some: { id: Number(foodtypeId) }
//             }
//         };
//     }

//     // ⭐ Fetch Menu Items with timezone for time validation
//     const menuItems = await prisma.menuItem.findMany({
//         where,
//         orderBy: { createdAt: "desc" },
//         include: {
//             categoryIds: { select: { id: true, name: true, image: true } },
//             foodtypeIds: { select: { id: true, name: true, image: true } },
//             kitchen: {
//                 include: {
//                     address: true,
//                     photos: true,
//                     foodtypes: true, // ⭐ Include kitchen's foodtypes
//                     timezone: true, // ⭐ Include timezone for time validation
//                     items: {
//                         where: { isActive: 1 },
//                         select: {
//                             id: true,
//                             quantity: true,
//                             startTime: true,
//                             endTime: true
//                         }
//                     }
//                 },
//                 where: {
//                     status: "APPROVED",
//                 }
//             }
//         }
//     });

//     // ⭐ Filter out expired menu items based on endTime and kitchen timezone
//     const validMenuItems = await filterMenuItemsByTime(menuItems);

//     // ⭐ DON'T filter by quantity - show items even with quantity=0 if time is valid

//     // ⭐ Format with distance
//     let formatted = [];
//     for (const item of validMenuItems) {
//         const formattedItem = await handleFactory.formatMenuItemWithDistance(item, userLat, userLng);
//         formatted.push(formattedItem);
//     }

//     // Filter by distance limit if user location is provided
//     if (userLat && userLng) {
//         formatted = formatted.filter(item =>
//             item.restaurant && item.restaurant.distanceKm !== null && item.restaurant.distanceKm <= distanceLimitKm
//         );
//     }

//     return res.status(200).json({
//         status: 1,
//         message: "Menu items fetched successfully",
//         kitchenId: kitchenId ? Number(kitchenId) : null,
//         categoryId: categoryId ? categoryId.split(",").map(Number) : null,
//         foodtypeId: foodtypeId ? Number(foodtypeId) : null,
//         menuItems: formatted
//     });
// });
exports.getMenu = catchAsync(async (req, res) => {
    const { kitchenId, categoryId, foodtypeId, kitchenTypeId } = req.query;
    const { userId, latitude: storedLat, longitude: storedLng } = req.user || {};
    const { latitude: queryLat, longitude: queryLng } = req.query;

    // Use user's stored location if available, otherwise fall back to query params
    const latitude = storedLat || queryLat;
    const longitude = storedLng || queryLng;
    const BASE_URL = process.env.menu_s3 || "";
    const { filterMenuItemsByTime } = require("../cron/menuItemExpiryChecker");

    // Convert to numbers for distance calculations
    const userLat = latitude ? Number(latitude) : null;
    const userLng = longitude ? Number(longitude) : null;

    // ⭐ Fetch Distance Limit from Config
    const distanceConfig = await prisma.config.findFirst({
        where: { configKey: "Distance Limit" }
    });
    const distanceLimitKm = distanceConfig?.configValue ? Number(distanceConfig.configValue) : 50; // Default 50km

    // ⭐ Build where condition
    const where = {
        isActive: 1,
        kitchen: {
            status: "APPROVED"
        }
    };

    if (kitchenId) where.kitchenId = Number(kitchenId);

    // ⭐ If multiple categories received (comma separated)
    if (categoryId) {
        const ids = categoryId.split(",").map(id => Number(id.trim()));

        where.categoryIds = {
            some: { id: { in: ids } }
        };
    }

    // ⭐ Filter by kitchen's foodtype (KITCHEN type)
    if (kitchenTypeId) {
        const ids = String(kitchenTypeId).split(",").map(id => Number(id.trim()));
        where.kitchen = {
            ...where.kitchen,
            foodtypes: {
                some: { id: { in: ids } }
            }
        };
    }

    // ⭐ Filter by menuItem's foodtype (MENU type)
    if (foodtypeId) {
        const ids = String(foodtypeId).split(",").map(id => Number(id.trim()));
        where.foodtypeIds = {
            some: { id: { in: ids } }
        };
    }

    // ⭐ Fetch Menu Items with timezone for time validation
    const menuItems = await prisma.menuItem.findMany({
        where,
        orderBy: { createdAt: "desc" },
        include: {
            categoryIds: { select: { id: true, name: true, image: true } },
            foodtypeIds: { select: { id: true, name: true, image: true } },
            kitchen: {
                include: {
                    address: true,
                    photos: true,
                    foodtypes: true, // ⭐ Include kitchen's foodtypes
                    timezone: true, // ⭐ Include timezone for time validation
                    items: {
                        where: { isActive: 1 },
                        select: {
                            id: true,
                            quantity: true,
                            startTime: true,
                            endTime: true
                        }
                    }
                },
                where: {
                    status: "APPROVED",
                }
            }
        }
    });

    // ⭐ Filter out expired menu items based on endTime and kitchen timezone
    const validMenuItems = await filterMenuItemsByTime(menuItems);

    // ⭐ DON'T filter by quantity - show items even with quantity=0 if time is valid

    // ⭐ Format with distance
    let formatted = [];
    for (const item of validMenuItems) {
        const formattedItem = await handleFactory.formatMenuItemWithDistance(item, userLat, userLng);
        formatted.push(formattedItem);
    }

    // Filter by distance limit if user location is provided
    if (userLat && userLng) {
        formatted = formatted.filter(item =>
            item.restaurant && item.restaurant.distanceKm !== null && item.restaurant.distanceKm <= distanceLimitKm
        );
    }

    return res.status(200).json({
        status: 1,
        message: "Menu items fetched successfully",
        kitchenId: kitchenId ? Number(kitchenId) : null,
        categoryId: categoryId ? categoryId.split(",").map(Number) : null,
        foodtypeId: foodtypeId ? String(foodtypeId).split(",").map(Number) : null,
        kitchenTypeId: kitchenTypeId ? String(kitchenTypeId).split(",").map(Number) : null,
        menuItems: formatted
    });
});

exports.getKitchenDetailsById = catchAsync(async (req, res) => {
    const { kitchenId } = req.params;
    const { latitude: storedLat, longitude: storedLng } = req.user || {};
    const { latitude: queryLat, longitude: queryLng } = req.query;

    // Use user's stored location if available, otherwise fall back to query params
    const latitude = storedLat || queryLat;
    const longitude = storedLng || queryLng;
    console.log("latitude, longitude", latitude, longitude)
    const PROFILE_IMG = process.env.user_s3 || "";
    const KITCHEN_IMG = process.env.kitchen_s3 || "";
    const KYC_IMG = process.env.kyc_s3 || "";

    // ⭐ Fetch Kitchen + relations
    const kitchen = await prisma.kitchen.findUnique({
        where: { kitchenId: Number(kitchenId), status: "APPROVED" },
        include: {
            address: true,
            kyc: true,
            photos: true,
            cuisines: true,
            timezone: true,  // ⭐ Include timezone for time validation
            items: {
                where: { isActive: 1 },  // ⭐ Only fetch active items
                select: {
                    id: true,
                    quantity: true,
                    discountPrice: true,
                    discountPercentage: true,
                    startTime: true,  // ⭐ Include startTime to check availability
                    endTime: true  // ⭐ Include endTime to check expiry
                }
            }
        }
    });

    if (!kitchen) {
        return res.status(404).json({ status: 0, message: "Kitchen not found" });
    }

    // ⭐ Calculate distance
    let distanceKm = null;
    if (
        latitude && longitude &&
        kitchen.address?.latitude && kitchen.address?.longitude
    ) {
        distanceKm = handleFactory.calculateDistance(
            Number(latitude),
            Number(longitude),
            Number(kitchen.address.latitude),
            Number(kitchen.address.longitude)
        );
    }

    console.log("distanceKm:", distanceKm)

    // ⭐ Reviews
    const reviews = await prisma.kitchenReview.findMany({
        where: { kitchenId: Number(kitchenId), review: { not: null } },
        orderBy: { createdAt: "desc" },
        include: { user: { select: { name: true, profilePicture: true } } }
    });

    const formattedReviews = reviews.map(r => ({
        id: r.id,
        rating: r.rating,
        review: r.review,
        createdAt: r.createdAt,
        user: r.user ? {
            name: r.user.name,
            profilePicture: r.user.profilePicture
                ? (r.user.profilePicture.startsWith('http') ? r.user.profilePicture : `${USER_IMG}${r.user.profilePicture}`)
                : null
        } : null
    }));

    // ⭐ Kitchen Images
    const kitchenImages = Array.isArray(kitchen.photos?.kitchenImages)
        ? kitchen.photos.kitchenImages.map(img => `${KITCHEN_IMG}${img}`)
        : [];

    // ⭐ Highest Discount
    const kitchenDiscountPercentage =
        kitchen.items.length > 0
            ? Math.max(...kitchen.items.map(i => i.discountPercentage || 0))
            : 0;

    // ⭐ Calculate total available items quantity (sum of all boxes not yet expired)
    const totalItemsQuantity = handleFactory.determineKitchenTotalQuantity(kitchen);

    return res.status(200).json({
        status: 1,
        message: "Kitchen details fetched successfully",

        kitchen: {
            // TOP CARD FIELDS
            kitchenId: kitchen.kitchenId,
            kitchenName: kitchen.kitchenName,
            rating: kitchen.rating,
            ratingCount: kitchen.ratingCount,

            // ⭐ FIX: distanceKm is ALWAYS null or number, NEVER {}
            distanceKm: distanceKm ?? null,

            discountPercentage: kitchenDiscountPercentage,
            totalItemsQuantity,

            // BASIC DETAILS
            email: kitchen.email,
            ownerName: kitchen.ownerName,
            contactNumber: kitchen.contactNumber,
            openingTime: kitchen.openingTime,
            closingTime: kitchen.closingTime,
            description: kitchen.description,
            createdAt: kitchen.createdAt,
            updatedAt: kitchen.updatedAt,
            status: kitchen.status,
            isActive: kitchen.isActive,
            rejectReason: kitchen.rejectReason,

            cuisines: kitchen.cuisines?.map(c => c.name) || [],

            // ADDRESS SECTION
            address: kitchen.address,

            // KYC SECTION
            kyc: kitchen.kyc ? {
                abnNumber: kitchen.kyc.abnNumber,
                acn: kitchen.kyc.acn,
                foodCertificateNumber: kitchen.kyc.foodCertificateNumber,
                foodCertificateImage: kitchen.kyc.foodCertificateImage
                    ? `${KYC_IMG}${kitchen.kyc.foodCertificateImage}`
                    : null,
                expireDate: kitchen.kyc.expireDate,
                fssaiNumber: kitchen.kyc.fssaiNumber,
            } : null,

            // PHOTOS TAB
            photos: kitchen.photos ? {
                kitchenImages,
                kitchenProfilePhoto: kitchen.photos.kitchenProfilePhoto
                    ? `${KITCHEN_IMG}${kitchen.photos.kitchenProfilePhoto}`
                    : null
            } : null,

            // REVIEWS TAB
            reviews: formattedReviews
        }
    });
});


exports.getMenuById = catchAsync(async (req, res) => {
    const { id } = req.params;
    const MENU_IMG = process.env.menu_s3 || "";
    const { userId, latitude: storedLat, longitude: storedLng } = req.user || {};
    const { latitude: queryLat, longitude: queryLng } = req.query;

    // Use user's stored location if available, otherwise fall back to query params
    const latitude = storedLat || queryLat;
    const longitude = storedLng || queryLng;

    // ⭐ Fetch main menu item
    const menuItem = await prisma.menuItem.findUnique({
        where: { id: Number(id) },
        include: {
            categoryIds: { select: { id: true, name: true, image: true } },
            foodtypeIds: { select: { id: true, name: true, image: true } },
            kitchen: {
                include: {
                    address: true,
                    photos: true,
                    timezone: true,
                    items: {
                        where: { isActive: 1 },
                        select: {
                            id: true,
                            quantity: true,
                            startTime: true,
                            endTime: true
                        }
                    }
                }
            }
        }
    });

    if (!menuItem) {
        return res.status(404).json({
            status: 0,
            message: "Menu item not found"
        });
    }

    // ⭐ Format main item with distance
    const formattedItem = await handleFactory.formatMenuItemWithDistance(
        menuItem,
        latitude,
        longitude
    );

    // ⭐ Fetch recommended items: same kitchen + same categories (exclude 0 quantity)
    const recommended = await prisma.menuItem.findMany({
        where: {
            kitchenId: menuItem.kitchenId,
            isActive: 1,
            quantity: { gt: 0 },
            NOT: { id: menuItem.id },
            categoryIds: {
                some: { id: { in: menuItem.categoryIds.map(c => c.id) } }
            }
        },
        take: 5,
        include: {
            categoryIds: true,
            foodtypeIds: true,
            kitchen: {
                include: { address: true, photos: true },
                where: {
                    status: "APPROVED",
                }
            }
        }
    });

    const recommendedFormatted = await Promise.all(
        recommended.map(item =>
            handleFactory.formatMenuItem(item)
        )
    );

    return res.status(200).json({
        status: 1,
        message: "Menu item details fetched successfully",
        menuItem: formattedItem,
        recommendedItems: recommendedFormatted
    });
});


exports.getUserDetails = catchAsync(async (req, res) => {
    const { userId } = req.user;
    const USER_S3 = process.env.user_s3;

    const user = await prisma.user.findUnique({
        where: { userId }
    });

    if (!user) {
        return res.status(404).json({
            status: 0,
            message: "User not found"
        });
    }

    // Calculate order stats for CO2 and discount messages
    let totalOrders = 0;
    let totalDiscount = 0;

    const orderStats = await prisma.order.aggregate({
        where: {
            userId: Number(userId),
            status: {
                not: "REJECTED"
            }
        },
        _count: {
            orderId: true
        },
        _sum: {
            discount: true
        }
    });

    totalOrders = orderStats._count.orderId || 0;
    totalDiscount = orderStats._sum.discount || 0;

    let co2Message = null;
    let discountMessage = null;

    if (totalOrders > 0) {
        const co2SavedKg = totalOrders; // 1 order = 1kg CO₂ (adjust if needed)
        co2Message = `Small action, big impact! You helped aviod ${co2SavedKg}kg of CO₂e emissions from your orders 🌳`;
        if (totalDiscount > 0) {
            // discountMessage = `Woohoo! You saved $${totalDiscount} on your orders! 🎉`;
            discountMessage = `You saved $${totalDiscount} on your orders! Keep Ordering Keep Saving.....🎉`;

        }
    }

    return res.status(200).json({
        status: 1,
        message: "User details fetched",
        user: {
            userId: user.userId,
            name: user.name,
            lastName: user.lastName || '',
            phoneNumber: user.phoneNumber,
            email: user.email,
            profilePicture: user.profilePicture
                ? (user.profilePicture.startsWith('http') ? user.profilePicture : `${USER_S3}${user.profilePicture}`)
                : null,
            deviceToken: user.deviceToken,
            countryCode: user.countryCode
        },
        co2Message,
        discountMessage
    });
});


exports.updateUserDetails = catchAsync(async (req, res) => {
    const { userId } = req.user;
    const { name, email, profilePicture, deviceToken, lastName, phoneNumber, countryCode } = req.body;

    const USER_S3 = process.env.user_s3;

    const data = {};

    if (name !== undefined) data.name = name;
    if (email !== undefined) data.email = email;
    if (deviceToken !== undefined) data.deviceToken = deviceToken;
    if (lastName !== undefined) data.lastName = lastName;
    if (phoneNumber !== undefined) data.phoneNumber = phoneNumber;
    if (countryCode !== undefined) data.countryCode = countryCode;
    // If new profile picture uploaded
    if (profilePicture) {
        data.profilePicture = profilePicture; // only file name
    }

    const updatedUser = await prisma.user.update({
        where: { userId },
        data
    });

    return res.status(200).json({
        status: 1,
        message: "User updated successfully"
    });
});

exports.addToWishlist = catchAsync(async (req, res) => {
    const { userId } = req.user;
    const { kitchenId } = req.body;

    if (!kitchenId) {
        return res.status(400).json({ status: 0, message: "kitchenId is required" });
    }

    // Check kitchen exists
    const kitchen = await prisma.kitchen.findUnique({ where: { kitchenId: Number(kitchenId) } });
    if (!kitchen) {
        return res.status(404).json({ status: 0, message: "Kitchen not found" });
    }

    // Add to wishlist (prevents duplicates automatically because of unique constraint)
    await prisma.wishlist.upsert({
        where: {
            userId_kitchenId: {
                userId,
                kitchenId: Number(kitchenId)
            }
        },
        update: {}, // nothing to update
        create: {
            userId,
            kitchenId: Number(kitchenId)
        }
    });

    return res.status(200).json({
        status: 1,
        message: "Added to wishlist successfully"
    });
});

exports.removeFromWishlist = catchAsync(async (req, res) => {
    const { userId } = req.user;
    const { kitchenId } = req.params;

    await prisma.wishlist.deleteMany({
        where: { userId, kitchenId: Number(kitchenId) }
    });

    return res.status(200).json({
        status: 1,
        message: "Removed from wishlist successfully"
    });
});

exports.getWishlist = catchAsync(async (req, res) => {
    // ⭐ Check if user is authenticated
    if (!req.user) {
        return res.status(200).json({
            status: 1,
            message: "No user logged in",
            kitchens: []
        });
    }

    const { userId, latitude: storedLat, longitude: storedLng } = req.user || {};
    const { latitude: queryLat, longitude: queryLng } = req.query;

    // Use user's stored location if available, otherwise fall back to query params
    const latitude = storedLat || queryLat;
    const longitude = storedLng || queryLng;

    // ⭐ Fetch Distance Limit from Config
    const distanceConfig = await prisma.config.findFirst({
        where: { configKey: "Distance Limit" }
    });
    const distanceLimitKm = distanceConfig?.configValue ? Number(distanceConfig.configValue) : 50; // Default 50km

    // ⭐ Step 1: Fetch wishlist
    const wishlist = await prisma.wishlist.findMany({
        where: { userId: Number(userId) },
        select: { kitchenId: true }
    });

    const kitchenIds = wishlist.map(w => w.kitchenId);

    if (kitchenIds.length === 0) {
        return res.status(200).json({
            status: 1,
            message: "No wishlist kitchens found",
            kitchens: []
        });
    }

    // ⭐ Step 2: Fetch kitchens with necessary relations
    const kitchens = await prisma.kitchen.findMany({
        where: {
            kitchenId: { in: kitchenIds },
            isActive: 1,
            status: "APPROVED"
        },
        include: {
            address: true,
            photos: true,
            cuisines: true,
            timezone: true,  // ⭐ Include timezone for time validation
            items: {
                where: { isActive: 1 },  // ⭐ Only fetch active items
                select: {
                    id: true,
                    discountPercentage: true,
                    quantity: true,
                    startTime: true,  // ⭐ Include startTime to check availability
                    endTime: true  // ⭐ Include endTime to check expiry
                }
            }
        }
    });

    // Create wishlist set for formatKitchen helper
    const wishlistSet = new Set(kitchenIds);

    // ⭐ Step 3: Format using common formatter
    let formattedKitchens = await Promise.all(
        kitchens.map(k =>
            handleFactory.formatKitchen(k, wishlistSet, latitude, longitude)
        )
    );

    // ⭐ Filter by distance limit
    formattedKitchens = formattedKitchens.filter(k => {
        return !latitude || !longitude || (k.distanceKm !== null && k.distanceKm <= distanceLimitKm);
    });

    // ⭐ Sort: Available Boxes first, then by distance
    formattedKitchens.sort((a, b) => {
        const aHasBoxes = a.totalItemsQuantity > 0 ? 1 : 0;
        const bHasBoxes = b.totalItemsQuantity > 0 ? 1 : 0;
        if (aHasBoxes !== bHasBoxes) return bHasBoxes - aHasBoxes;
        return (a.distanceKm ?? Infinity) - (b.distanceKm ?? Infinity);
    });

    // ⭐ Force isWishlist = 1 for all returned entries (optional override)
    formattedKitchens.forEach(k => k.isWishlist = 1);

    // ⭐ Step 4: Send Response
    return res.status(200).json({
        status: 1,
        message: "Wishlist kitchens fetched successfully",
        kitchens: formattedKitchens
    });
});




exports.getAllKitchens = catchAsync(async (req, res) => {
    const { cuisineId, search } = req.query;
    const { userId, latitude: storedLat, longitude: storedLng } = req.user || {};
    const { latitude: queryLat, longitude: queryLng } = req.query;

    // Use user's stored location if available, otherwise fall back to query params
    const latitude = storedLat || queryLat;
    const longitude = storedLng || queryLng;

    // ⭐ Wishlist kitchens for logged in users only
    const wishlist = userId ? await prisma.wishlist.findMany({
        where: { userId: Number(userId) },
        select: { kitchenId: true }
    }) : [];

    const wishlistIdsSet = new Set(wishlist.map(w => w.kitchenId));

    // ⭐ Build dynamic where condition
    let whereCondition = {
        isActive: 1,
        status: "APPROVED",
    };

    // ⭐ Filter by cuisine if provided
    if (cuisineId) {
        const ids = cuisineId.split(",").map(id => Number(id.trim()));
        whereCondition.cuisines = {
            some: { id: { in: ids } }
        };
    }
    if (search && search.trim() !== "") {
        whereCondition.kitchenName = {
            contains: search
        };
    }

    // ⭐ Fetch Distance Limit from Config
    const distanceConfig = await prisma.config.findFirst({
        where: { configKey: "Distance Limit" }
    });
    const distanceLimitKm = distanceConfig?.configValue ? Number(distanceConfig.configValue) : 50; // Default 50km

    // ⭐ Fetch kitchens
    const kitchens = await prisma.kitchen.findMany({
        where: whereCondition,
        orderBy: { kitchenId: "desc" },
        include: {
            address: true,
            photos: true,
            cuisines: true,
            timezone: true,  // ⭐ Include timezone for time validation
            items: {
                where: { isActive: 1 },  // ⭐ Only fetch active items
                select: {
                    id: true,
                    discountPercentage: true,
                    quantity: true,
                    startTime: true,  // ⭐ Include startTime
                    endTime: true  // ⭐ Include endTime
                }
            }
        }
    });

    // ⭐ Format using helper
    let formattedKitchens = await Promise.all(
        kitchens.map(k =>
            handleFactory.formatKitchen(k, wishlistIdsSet, latitude, longitude)
        )
    );

    // ⭐ Filter by distance limit
    formattedKitchens = formattedKitchens.filter(k => {
        return !latitude || !longitude || (k.distanceKm !== null && k.distanceKm <= distanceLimitKm);
    });

    // ⭐ Sort: Available Boxes first, then by distance
    formattedKitchens.sort((a, b) => {
        const aHasBoxes = a.totalItemsQuantity > 0 ? 1 : 0;
        const bHasBoxes = b.totalItemsQuantity > 0 ? 1 : 0;
        if (aHasBoxes !== bHasBoxes) return bHasBoxes - aHasBoxes;
        return (a.distanceKm ?? Infinity) - (b.distanceKm ?? Infinity);
    });

    return res.status(200).json({
        status: 1,
        message: "Kitchens fetched successfully",
        cuisineFilter: cuisineId ? cuisineId.split(",").map(Number) : null,
        kitchens: formattedKitchens
    });
});

exports.kitchenSearch = catchAsync(async (req, res) => {
    const { search, cuisineId, kitchenTypeId, foodtypeId } = req.query;
    const { userId, latitude: storedLat, longitude: storedLng } = req.user || {};
    const { latitude: queryLat, longitude: queryLng } = req.query;
    const { filterMenuItemsByTime } = require("../cron/menuItemExpiryChecker");

    // Use user's stored location if available, otherwise fall back to query params
    const latitude = storedLat || queryLat;
    const longitude = storedLng || queryLng;

    // ✅ If search is not provided, and no filters are provided, return empty list
    if ((!search || search.trim() === "") && !cuisineId && !kitchenTypeId && !foodtypeId) {
        return res.status(200).json({
            status: 1,
            message: "Kitchens fetched successfully",
            kitchens: [],
            menu: []
        });
    }

    // ⭐ Fetch wishlist for logged-in users
    let wishlistIds = [];
    if (userId) {
        const wishlist = await prisma.wishlist.findMany({
            where: { userId: Number(userId) },
            select: { kitchenId: true }
        });
        wishlistIds = wishlist.map(w => w.kitchenId);
    }
    const wishlistSet = new Set(wishlistIds);

    // ⭐ Build where condition with filters for Kitchens
    const where = {
        isActive: 1,
        status: "APPROVED"
    };

    if (search && search.trim() !== "") {
        where.kitchenName = {
            contains: search,
            mode: 'insensitive'  // ✅ Case-insensitive search
        };
    }

    if (cuisineId) {
        const ids = String(cuisineId).split(",").map(id => Number(id.trim()));
        where.cuisines = {
            some: { id: { in: ids } }
        };
    }

    if (kitchenTypeId) {
        const ids = String(kitchenTypeId).split(",").map(id => Number(id.trim()));
        where.foodtypes = {
            some: { id: { in: ids } }
        };
    }

    // ⭐ Build where condition for Menu Items
    const menuItemWhere = {
        isActive: 1,
        kitchen: {
            isActive: 1,
            status: "APPROVED"
        }
    };

    if (search && search.trim() !== "") {
        menuItemWhere.name = {
            contains: search,
            mode: 'insensitive'
        };
    }

    if (cuisineId) {
        const ids = String(cuisineId).split(",").map(id => Number(id.trim()));
        menuItemWhere.kitchen.cuisines = { some: { id: { in: ids } } };
    }

    if (kitchenTypeId) {
        const ids = String(kitchenTypeId).split(",").map(id => Number(id.trim()));
        menuItemWhere.kitchen.foodtypes = { some: { id: { in: ids } } };
    }

    if (foodtypeId) {
        const ids = String(foodtypeId).split(",").map(id => Number(id.trim()));
        menuItemWhere.foodtypeIds = { some: { id: { in: ids } } };
    }

    // ⭐ Fetch Distance Limit from Config
    const distanceConfig = await prisma.config.findFirst({
        where: { configKey: "Distance Limit" }
    });
    const distanceLimitKm = distanceConfig?.configValue ? Number(distanceConfig.configValue) : 50; // Default 50km

    // 📦 Fetch kitchens (ONLY if foodtypeId or kitchenTypeId is NOT provided)
    let kitchens = [];
    if (!foodtypeId && !kitchenTypeId) {
        kitchens = await prisma.kitchen.findMany({
            where,
            orderBy: { kitchenId: "desc" },
            include: {
                address: true,
                photos: true,
                cuisines: true,
                timezone: true,  // ⭐ Include timezone for time validation
                items: {
                    where: { isActive: 1 },  // ⭐ Only fetch active items
                    select: {
                        id: true,
                        discountPercentage: true,
                        quantity: true,
                        startTime: true,  // ⭐ Include startTime
                        endTime: true  // ⭐ Include endTime
                    }
                }
            }
        });
    }

    // 📦 Fetch menu items matching search and filters
    const menuItems = await prisma.menuItem.findMany({
        where: menuItemWhere,
        include: {
            categoryIds: { select: { id: true, name: true, image: true } },
            foodtypeIds: { select: { id: true, name: true, image: true } },
            kitchen: {
                include: {
                    address: true,
                    photos: true,
                    timezone: true,
                    items: {
                        where: { isActive: 1 },
                        select: {
                            id: true,
                            quantity: true,
                            startTime: true,
                            endTime: true
                        }
                    }
                }
            }
        }
    });

    // ⭐ Filter out expired menu items based on endTime and kitchen timezone
    const validMenuItems = await filterMenuItemsByTime(menuItems);

    // ⭐ Format collections using helpers
    let formattedKitchens = await Promise.all(
        kitchens.map(k =>
            handleFactory.formatKitchen(k, wishlistSet, latitude, longitude)
        )
    );

    let formattedMenuItems = await Promise.all(
        validMenuItems.map(item =>
            handleFactory.formatMenuItemWithDistance(item, latitude, longitude)
        )
    );

    // ⭐ Filter both by distance limit
    formattedKitchens = formattedKitchens.filter(k => {
        return !latitude || !longitude || (k.distanceKm !== null && k.distanceKm <= distanceLimitKm);
    });

    formattedMenuItems = formattedMenuItems.filter(item => {
        const dist = item.restaurant?.distanceKm;
        return !latitude || !longitude || (dist !== null && dist <= distanceLimitKm);
    });

    // ⭐ Sort: Kitchens (Available Boxes first, then by distance)
    formattedKitchens.sort((a, b) => {
        const aHasBoxes = a.totalItemsQuantity > 0 ? 1 : 0;
        const bHasBoxes = b.totalItemsQuantity > 0 ? 1 : 0;
        if (aHasBoxes !== bHasBoxes) return bHasBoxes - aHasBoxes;
        return (a.distanceKm ?? Infinity) - (b.distanceKm ?? Infinity);
    });

    // ⭐ Sort: Menu Items (Available first, then by distance)
    formattedMenuItems.sort((a, b) => {
        const aAvailable = a.quantity > 0 ? 1 : 0;
        const bAvailable = b.quantity > 0 ? 1 : 0;
        if (aAvailable !== bAvailable) return bAvailable - aAvailable;
        return (a.restaurant?.distanceKm ?? Infinity) - (b.restaurant?.distanceKm ?? Infinity);
    });

    return res.status(200).json({
        status: 1,
        message: "Kitchens fetched successfully",
        cuisineFilter: cuisineId ? String(cuisineId).split(",").map(Number) : null,
        kitchenTypeFilter: kitchenTypeId ? String(kitchenTypeId).split(",").map(Number) : null,
        foodtypeFilter: foodtypeId ? String(foodtypeId).split(",").map(Number) : null,
        kitchens: formattedKitchens,
        menu: formattedMenuItems
    });
});

// ✅ Get all config
exports.getConfig = catchAsync(async (req, res) => {
    try {
        console.log("Fetching all configs...");
        const config = await prisma.config.findMany({
            select: {
                configId: true,
                configKey: true,
                configValue: true,
            },
        });
        console.log("Configs found:", config);

        // Force no caching
        res.set({
            "Cache-Control": "no-cache, no-store, must-revalidate",
            Pragma: "no-cache",
            Expires: "0",
        });

        return res.json({
            status: 1,
            message: "Config fetched successfully",
            config,
        });
    } catch (error) {
        console.error("Error fetching configs:", error);
        return res.status(500).json({
            status: 0,
            message: "Error fetching configs",
            error: error.message,
        });
    }
});



exports.getKitchenReviews = catchAsync(async (req, res) => {
    const { kitchenId } = req.params;
    const { rating } = req.query;   // optional (1,2,3,4,5)

    if (!kitchenId) {
        return res.status(400).json({
            status: 0,
            message: "kitchenId is required"
        });
    }

    // ⭐ Base URL for user profile pics
    const USER_IMG = process.env.user_s3 || "";

    // ⭐ Filter object
    let filter = { kitchenId: Number(kitchenId), review: { not: null } };

    if (rating) {
        filter.rating = Number(rating); // ⭐ filter only if provided
    }

    // ⭐ Fetch reviews + user data
    const reviews = await prisma.kitchenReview.findMany({
        where: filter,
        orderBy: { createdAt: "desc" },
        include: {
            user: {
                select: {
                    name: true,
                    profilePicture: true
                }
            }
        }
    });

    // ⭐ Format reviews
    const formattedReviews = reviews.map(r => ({
        id: r.id,
        rating: Number(r.rating),
        review: r.review,
        createdAt: r.createdAt,

        user: r.user ? {
            name: r.user.name,
            profilePicture: r.user.profilePicture
                ? (r.user.profilePicture.startsWith('http') ? r.user.profilePicture : `${USER_IMG}${r.user.profilePicture}`)
                : null
        } : null
    }));

    // ⭐ rating summary
    const totalReviews = await prisma.kitchenReview.count({
        where: { kitchenId: Number(kitchenId) }
    });

    const avgRatingData = await prisma.kitchenReview.aggregate({
        where: { kitchenId: Number(kitchenId) },
        _avg: { rating: true }
    });

    return res.json({
        status: 1,
        message: "Kitchen reviews fetched successfully",
        summary: {
            totalReviews,
            avgRating: avgRatingData._avg.rating
                ? Number(avgRatingData._avg.rating.toFixed(2))
                : 0
        },
        reviews: formattedReviews
    });
});


exports.addToCart = catchAsync(async (req, res) => {
    const { menuItemId, quantity } = req.body; // +1 or -1
    const { userId } = req.user;
    console.log("userID", userId);
    console.log("menuItemId", menuItemId);
    console.log("quantity", quantity);
    if (!menuItemId || ![1, -1].includes(quantity)) {
        return res.status(400).json({
            status: 0,
            message: "menuItemId and quantity (+1 or -1) required"
        });
    }

    // ⭐ Fetch menu item WITH quantity and timezone for validation
    const menuItem = await prisma.menuItem.findFirst({
        where: { id: Number(menuItemId), isActive: 1 },
        select: {
            kitchenId: true,
            quantity: true,
            kitchen: {
                select: {
                    timezone: {
                        select: {
                            offset: true
                        }
                    }
                }
            }
        }
    });

    if (!menuItem) {
        return res.status(404).json({
            status: 0,
            message: "Menu item not found"
        });
    }

    // ⭐ Validate menu item time window (check if expired)
    const { validateMenuItemTime } = require("../cron/menuItemExpiryChecker");
    const timeValidation = await validateMenuItemTime(Number(menuItemId));

    if (!timeValidation.isValid) {
        return res.status(400).json({
            status: 0,
            message: timeValidation.reason || "This item is no longer available"
        });
    }

    // 🚫 Out of stock check (VERY IMPORTANT)
    if (menuItem.quantity <= 0) {
        return res.status(400).json({
            status: 0,
            message: "Item is out of stock"
        });
    }

    // ⭐ Get active cart
    let cart = await prisma.cart.findFirst({
        where: { userId, isActive: 1 },
        include: {
            items: {
                include: { menu: { select: { kitchenId: true } } }
            }
        }
    });

    if (!cart) {
        cart = await prisma.cart.create({
            data: { userId, isActive: 1 }
        });
        // Initialize items as empty array for newly created cart
        cart.items = [];
    }

    // ⭐ Kitchen conflict check
    if (cart.items && cart.items.length > 0) {
        const existingKitchenId = cart.items[0].menu.kitchenId;
        if (existingKitchenId !== menuItem.kitchenId) {
            return res.status(400).json({
                status: 0,
                message: "Your cart contains items from another kitchen. Clear cart first."
            });
        }
    }

    // ⭐ Check existing cart item
    const existingItem = await prisma.cartItem.findFirst({
        where: {
            cartId: cart.cartId,
            menuItemId: Number(menuItemId)
        }
    });

    // ======================
    // ➕ INCREASE / ➖ DECREASE
    // ======================
    if (existingItem) {
        const newQty = existingItem.quantity + quantity;

        if (newQty <= 0) {
            await prisma.cartItem.delete({
                where: { cartItemId: existingItem.cartItemId }
            });

            return res.json({
                status: 1,
                message: "Item removed from cart"
            });
        }

        // 🚫 Stock limit check
        if (newQty > menuItem.quantity) {
            return res.status(400).json({
                status: 0,
                message: "Requested quantity exceeds available stock"
            });
        }

        await prisma.cartItem.update({
            where: { cartItemId: existingItem.cartItemId },
            data: { quantity: newQty }
        });

        return res.json({
            status: 1,
            message: "Quantity updated"
        });
    }

    // ======================
    // 🆕 ADD NEW ITEM
    // ======================
    if (quantity === 1) {
        if (menuItem.quantity < 1) {
            return res.status(400).json({
                status: 0,
                message: "Item is out of stock"
            });
        }

        await prisma.cartItem.create({
            data: {
                cartId: cart.cartId,
                menuItemId: Number(menuItemId),
                quantity: 1
            }
        });

        return res.json({
            status: 1,
            message: "Item added to cart"
        });
    }

    // ❌ Cannot reduce non-existing item
    return res.status(400).json({
        status: 0,
        message: "Cannot reduce quantity for a new item"
    });
});


exports.getCart = catchAsync(async (req, res) => {
    // ⭐ Check if user is authenticated
    if (!req.user) {
        return res.status(200).json({
            status: 1,
            cartItems: [],
            kitchen: null,
            priceDetails: null
        });
    }

    const { userId, latitude, longitude } = req.user;

    console.log("latitude:", latitude);
    console.log("longitude:", longitude);
    const MENU_IMG = process.env.menu_s3;
    console.log("userId:", userId);

    const userLat = latitude ? Number(latitude) : null;
    const userLng = longitude ? Number(longitude) : null;

    // ⭐ Fetch cart with kitchen details (include address for distance check)
    const cart = await prisma.cart.findFirst({
        where: { userId, isActive: 1 },
        include: {
            items: {
                include: {
                    menu: {
                        include: {
                            kitchen: {
                                select: {
                                    kitchenId: true,
                                    kitchenName: true,
                                    address: true,
                                    photos: { select: { kitchenProfilePhoto: true } }
                                }
                            }
                        }
                    }
                }
            }
        }
    });

    console.log("cart:", cart);
    if (!cart || cart.items.length === 0) {
        return res.status(200).json({
            status: 1,
            cartItems: [],
            kitchen: null,
            priceDetails: null
        });
    }

    // ⭐ Filter out inactive menu items and DELETE them from cart
    const inactiveCartItems = cart.items.filter(ci => !ci.menu || ci.menu.isActive !== 1);
    const activeCartItems = cart.items.filter(ci => ci.menu && ci.menu.isActive === 1);

    // ⭐ Delete inactive items from database
    if (inactiveCartItems.length > 0) {
        const inactiveCartItemIds = inactiveCartItems.map(ci => ci.cartItemId);
        await prisma.cartItem.deleteMany({
            where: {
                cartItemId: { in: inactiveCartItemIds }
            }
        });
        console.log(`🗑️ Removed ${inactiveCartItems.length} inactive items from cart`);
    }

    if (activeCartItems.length === 0) {
        return res.status(200).json({
            status: 1,
            cartItems: [],
            kitchen: null,
            priceDetails: null
        });
    }

    // ⭐ Distance check (only if user provided their location)
    const kitchen = activeCartItems[0].menu.kitchen;
    let distanceKm = null;
    let withinDistance = true; // default: allow if no location provided

    if (userLat && userLng) {
        // Fetch Distance Limit from config
        const distanceConfig = await prisma.config.findFirst({
            where: { configKey: "Distance Limit" }
        });
        const distanceLimitKm = distanceConfig?.configValue
            ? Number(distanceConfig.configValue)
            : 50; // default 50km
        console.log("distanceLimitKm:", distanceLimitKm);
        const kitchenLat = kitchen.address?.latitude ? Number(kitchen.address.latitude) : null;
        const kitchenLng = kitchen.address?.longitude ? Number(kitchen.address.longitude) : null;

        if (kitchenLat && kitchenLng) {
            distanceKm = handleFactory.calculateDistance(userLat, userLng, kitchenLat, kitchenLng);
            withinDistance = distanceKm <= distanceLimitKm;
            console.log("distanceKm:", distanceKm);
            console.log("withinDistance:", withinDistance);
            if (!withinDistance) {
                console.log(`🚫 [CART] User is ${distanceKm}km away — exceeds limit of ${distanceLimitKm}km. Clearing cart...`);

                // ⭐ Clear all items from the cart silently
                await prisma.cartItem.deleteMany({
                    where: { cartId: cart.cartId }
                });
                console.log(`🗑️ [CART] Cart cleared for user ${userId} due to distance restriction`);

                return res.status(200).json({
                    status: 1,
                    cartItems: [],
                    kitchen: null,
                    priceDetails: null
                });
            }
        }
    }

    // ⭐ Get platform fee & tax from config
    const config = await prisma.config.findMany({
        where: {
            configKey: { in: ["GST Percentage", "Platform Fee Percentage"] }
        }
    });

    const TAX_PERCENT = Number(config.find(c => c.configKey === "GST Percentage")?.configValue) || 10;
    const PLATFORM_FEE_PERCENTAGE = Number(config.find(c => c.configKey === "Platform Fee Percentage")?.configValue) || 1;

    // ⭐ Calculate items total
    let itemTotal = 0;

    // ⭐ total unique items (not dependent on quantity)
    const totalItems = activeCartItems.length;

    const items = activeCartItems.map(ci => {
        itemTotal += ci.quantity * (ci.menu.discountPrice > 0 ? ci.menu.discountPrice : ci.menu.price);

        return {
            cartItemId: ci.cartItemId,
            menuItemId: ci.menuItemId,
            name: ci.menu.name,
            quantity: ci.quantity,
            actualPrice: ci.menu.price,
            discountPrice: ci.menu.discountPrice,
            image: ci.menu.image ? `${MENU_IMG}${ci.menu.image}` : null
        };
    });

    // ⭐ REVERSE GST CALCULATION (GST is already included in the price)
    const GST_RATE = TAX_PERCENT / 100;
    const itemTotalNet = Number((itemTotal / (1 + GST_RATE)).toFixed(2));
    const taxAmount = Number((itemTotal - itemTotalNet).toFixed(2));

    // ⭐ Platform fee calculation (percentage of itemTotal)
    const platformFee = Number(((itemTotal * PLATFORM_FEE_PERCENTAGE) / 100).toFixed(2));

    // ⭐ Total amount calculation (itemTotal already includes GST)
    const totalAmount = itemTotal + platformFee;

    return res.status(200).json({
        status: 1,
        cartItems: items,
        kitchen: {
            kitchenId: kitchen.kitchenId,
            kitchenName: kitchen.kitchenName,
            kitchenProfilePhoto: kitchen.photos?.kitchenProfilePhoto
                ? `${process.env.kitchen_s3}${kitchen.photos.kitchenProfilePhoto}`
                : null,
            address: kitchen.address
        },
        priceDetails: {
            totalItems,
            itemTotal,
            taxPercent: TAX_PERCENT,
            taxAmount,
            platformFee,
            totalAmount
        }
    });
});


exports.removeCartItem = catchAsync(async (req, res) => {
    const { id } = req.params; // cartItemId

    const exists = await prisma.cartItem.findUnique({
        where: { cartItemId: Number(id) }
    });

    if (!exists) {
        return res.status(404).json({
            status: 0,
            message: "Cart item not found"
        });
    }

    await prisma.cartItem.delete({
        where: { cartItemId: Number(id) }
    });

    return res.status(200).json({
        status: 1,
        message: "Cart item deleted"
    });
});

exports.clearCart = catchAsync(async (req, res) => {
    const { userId } = req.user;

    const cart = await prisma.cart.findFirst({
        where: { userId, isActive: 1 }
    });

    if (!cart) {
        return res.status(200).json({ status: 1, message: "Cart already empty" });
    }

    await prisma.cartItem.deleteMany({
        where: { cartId: cart.cartId }
    });

    return res.status(200).json({
        status: 1,
        message: "Cart cleared"
    });
});

exports.placeOrder = catchAsync(async (req, res) => {
    const { userId } = req.user;

    const {
        kitchenId,
        items = [],
        itemTotal,
        taxAmount,
        platformFee,
        totalAmount,
        placedAt,
        cardId // OPTIONAL: Saved card ID from getSavedCards API
    } = req.body;
    console.log("PlacingOrder:", req.body);
    // 🔐 Stripe only
    const paymentMethod = "ONLINE";
    console.log("Placing  at placedAt:", placedAt);
    if (!kitchenId || items.length === 0) {
        return res.status(400).json({
            status: 0,
            message: "kitchenId and items are required"
        });
    }

    // ⭐ VALIDATE ALL ITEMS BEFORE PROCEEDING
    const { validateMenuItemTime } = require("../cron/menuItemExpiryChecker");

    for (const item of items) {
        const menuItem = await prisma.menuItem.findUnique({
            where: { id: Number(item.menuItemId) },
            select: {
                id: true,
                name: true,
                quantity: true,
                isActive: true
            }
        });

        // Check if item exists and is active
        if (!menuItem || menuItem.isActive !== 1) {
            return res.status(400).json({
                status: 0,
                message: `Menu item "${menuItem?.name || item.menuItemId}" is not available`
            });
        }

        // Check if item is in stock
        if (menuItem.quantity <= 0) {
            return res.status(400).json({
                status: 0,
                message: `"${menuItem.name}" is out of stock`
            });
        }

        // Check if requested quantity exceeds available stock
        if (item.quantity > menuItem.quantity) {
            return res.status(400).json({
                status: 0,
                message: `Only ${menuItem.quantity} units of "${menuItem.name}" available`
            });
        }

        // Validate time window (check if expired)
        const timeValidation = await validateMenuItemTime(Number(item.menuItemId));
        if (!timeValidation.isValid) {
            return res.status(400).json({
                status: 0,
                message: timeValidation.reason || `"${menuItem.name}" is no longer available`
            });
        }
    }

    // ⭐ Calculate overall discount
    let totalDiscount = 0;
    items.forEach(i => {
        totalDiscount += (i.actualPrice - i.discountPrice) * i.quantity;
    });

    // ⭐ Generate pickupId
    const pickupId = "RSQB" + Math.floor(1000 + Math.random() * 9000);

    // =========================
    // 🕒 CALCULATE PICKUP TIMES
    // =========================
    let pickupStartTime = null;
    let pickupEndTime = null;

    for (const it of items) {
        const menu = await prisma.menuItem.findUnique({
            where: { id: Number(it.menuItemId) },
            select: { startTime: true, endTime: true }
        });

        if (menu?.startTime && (!pickupStartTime || menu.startTime > pickupStartTime)) {
            pickupStartTime = menu.startTime;
        }

        if (menu?.endTime && (!pickupEndTime || menu.endTime > pickupEndTime)) {
            pickupEndTime = menu.endTime;
        }
    }

    // =========================
    // 🧾 CREATE ORDER (PENDING)
    // =========================

    // Generate random 8-digit order number (e.g., 12345678)
    const generateOrderNumber = () => {
        return Math.floor(10000000 + Math.random() * 90000000); // 8-digit number
    };

    // Generate unique order UID for admin URL (e.g., a1b2c3d4e5f6g7h8)
    const generateOrderUid = () => {
        const crypto = require('crypto');
        return crypto.randomBytes(16).toString('hex'); // 32 character hex string
    };

    let orderNumber = generateOrderNumber();
    let orderUid = generateOrderUid();

    // Ensure uniqueness (retry if collision)
    let attempts = 0;
    while (attempts < 5) {
        const existingNumber = await prisma.order.findUnique({
            where: { orderNumber }
        });
        const existingUid = await prisma.order.findUnique({
            where: { orderUid }
        });

        if (!existingNumber && !existingUid) break;

        if (existingNumber) orderNumber = generateOrderNumber();
        if (existingUid) orderUid = generateOrderUid();
        attempts++;
    }

    const order = await prisma.order.create({
        data: {
            orderNumber,
            orderUid,
            userId,
            kitchenId,
            deliveryType: "PICKUP",
            status: "PAYMENT_PENDING",
            paymentMethod,
            paymentStatus: "PENDING",
            itemTotal,
            gstAmount: taxAmount,
            platformFee,
            totalAmount,
            pickupId,
            discount: totalDiscount,
            pickupStartTime,
            pickupEndTime,
            orderedAt: placedAt ? parseDeviceDate(placedAt) : new Date()
            //2026-01-22 15:07:23.591032
        }
    });

    const orderDisplayId = "OD" + String(order.orderNumber);

    // =========================
    // 📦 CREATE ORDER ITEMS
    // =========================
    for (const it of items) {
        await prisma.orderItem.create({
            data: {
                orderId: order.orderId,
                menuItemId: it.menuItemId,
                quantity: it.quantity,
                price: it.discountPrice,
                totalPrice: it.quantity * it.discountPrice
            }
        });
    }

    // =========================
    // 📦 RESPONSE ITEMS
    // =========================
    const responseItems = await Promise.all(
        items.map(async (it) => {
            const menu = await prisma.menuItem.findUnique({
                where: { id: Number(it.menuItemId) },
                select: {
                    name: true,
                    startTime: true,
                    endTime: true,
                    kitchen: {
                        select: {
                            kitchenId: true,
                            kitchenName: true,
                            address: true,
                            timezone: {
                                select: {
                                    id: true,
                                    name: true,
                                    displayName: true,
                                    offset: true
                                }
                            }
                        }
                    }
                }
            });

            return {
                name: menu.name,
                quantity: it.quantity,
                startTime: menu.startTime,
                endTime: menu.endTime,
                kitchenId: menu.kitchen.kitchenId,
                kitchenName: menu.kitchen.kitchenName,
                address: menu.kitchen.address,
                timezone: menu.kitchen.timezone || null
            };
        })
    );

    // =========================
    // 💳 STRIPE PAYMENT INTENT WITH CONNECT SPLIT
    // =========================
    console.log("\n========== STRIPE PAYMENT INTENT CREATION ==========");
    console.log("📊 Payment Details:");
    console.log("   Total Amount (AUD): $", totalAmount.toFixed(2));
    console.log("   Amount in cents:", Math.round(totalAmount * 100));
    console.log("   Currency: aud");
    console.log("   Order ID:", order.orderId);
    console.log("   Kitchen ID:", kitchenId);
    console.log("   User ID:", userId);
    console.log("====================================================");

    try {
        // 🔍 Get kitchen's Stripe Connect account
        const kitchen = await prisma.kitchen.findUnique({
            where: { kitchenId: Number(kitchenId) },
            select: {
                stripeAccountId: true,
                kitchenName: true,
                stripeOnboardingCompleted: true
            }
        });

        // Validate kitchen has completed Stripe onboarding
        if (!kitchen?.stripeAccountId || !kitchen.stripeOnboardingCompleted) {
            // Delete order items first (foreign key constraint)
            await prisma.orderItem.deleteMany({
                where: { orderId: order.orderId }
            });

            // Then delete the order
            await prisma.order.delete({ where: { orderId: order.orderId } });

            return res.status(400).json({
                status: 0,
                message: kitchen?.stripeAccountId
                    ? "Kitchen's Stripe onboarding is not complete. Please complete onboarding to accept orders."
                    : "Kitchen must complete Stripe Connect onboarding before accepting orders"
            });
        }

        // Fetch Fees from config
        const feeConfigs = await prisma.config.findMany({
            where: {
                configKey: {
                    in: ["Service Fee Percentage", "Stripe Fee (% of Order Value)", "Stripe Fixed Fee"]
                }
            }
        });

        const serviceFeePercent = Number(feeConfigs.find(c => c.configKey === "Service Fee Percentage")?.configValue) || 15;
        const stripeFeePercent = Number(feeConfigs.find(c => c.configKey === "Stripe Fee (% of Order Value)")?.configValue) || 1.7;
        const stripeFixedFee = Number(feeConfigs.find(c => c.configKey === "Stripe Fixed Fee")?.configValue) || 0.30;

        // Calculate service fee on item total (excluding platform fee)
        const serviceFee = Number(((itemTotal * serviceFeePercent) / 100).toFixed(2));

        // ResQBox should get: (Platform Fee + Service Fee) - Stripe Fee
        const resqboxGrossRevenue = platformFee + serviceFee; // Total ResQBox revenue before Stripe fee
        const stripeFeeEstimate = (totalAmount * (stripeFeePercent / 100)) + stripeFixedFee;
        const resqboxNetCommission = Math.max(0, resqboxGrossRevenue - stripeFeeEstimate); // ResQBox net after Stripe fee

        // Kitchen gets: Total - Platform Fee - Service Fee
        const kitchenAmount = totalAmount - platformFee - serviceFee;

        // Application fee = ResQBox's gross revenue (Platform Fee + Service Fee)
        // Stripe will deduct their fee from this, leaving ResQBox with the net commission
        const resqboxApplicationFee = resqboxGrossRevenue;

        console.log("💸 Payment Split Calculation:");
        console.log("   Item Total: $", itemTotal.toFixed(2));
        console.log("   Platform Fee: $", platformFee.toFixed(2));
        console.log("   Service Fee (" + serviceFeePercent + "%): $", serviceFee.toFixed(2));
        console.log("   ResQBox Gross Revenue (Platform + Service): $", resqboxGrossRevenue.toFixed(2));
        console.log("   Stripe Fee (Estimate): $", stripeFeeEstimate.toFixed(2));
        console.log("   ResQBox Net Commission (after Stripe): $", resqboxNetCommission.toFixed(2));
        console.log("   Kitchen Amount (goes to Connect): $", kitchenAmount.toFixed(2));
        console.log("   Kitchen Stripe Account:", kitchen.stripeAccountId);
        console.log("====================================================");

        // ========================================
        // 💳 SAVED CARD VALIDATION (if cardId provided)
        // ========================================
        let savedCard = null;

        if (cardId) {
            console.log("🔐 [SAVED CARD] Card ID provided:", cardId);

            // Fetch saved card from database
            savedCard = await prisma.savedCard.findUnique({
                where: { cardId: Number(cardId) }
            });

            // Validate card exists and belongs to user
            if (!savedCard) {
                console.error("❌ [SAVED CARD] Card not found:", cardId);

                // Delete order since payment failed
                await prisma.orderItem.deleteMany({ where: { orderId: order.orderId } });
                await prisma.order.delete({ where: { orderId: order.orderId } });

                return res.status(400).json({
                    status: 0,
                    message: "Saved card not found"
                });
            }

            if (savedCard.userId !== userId) {
                console.error("❌ [SAVED CARD] Card does not belong to user");
                console.error("   Card User ID:", savedCard.userId);
                console.error("   Request User ID:", userId);

                // Delete order since payment failed
                await prisma.orderItem.deleteMany({ where: { orderId: order.orderId } });
                await prisma.order.delete({ where: { orderId: order.orderId } });

                return res.status(403).json({
                    status: 0,
                    message: "Unauthorized: This card does not belong to you"
                });
            }

            console.log("✅ [SAVED CARD] Card validated successfully");
            console.log("   Card Brand:", savedCard.cardBrand);
            console.log("   Card Last4:", savedCard.cardLast4);
            console.log("   Payment Method ID:", savedCard.stripePaymentMethodId);
        } else {
            console.log("🆕 [NEW CARD] No cardId provided - new card flow");
        }

        // 🎯 Create Payment Intent with Stripe Connect split
        const paymentIntentData = {
            amount: Math.round(totalAmount * 100), // Customer pays full amount
            currency: "aud",
            capture_method: "manual",   // 🔥 REQUIRED
            transfer_data: {
                destination: kitchen.stripeAccountId, // Kitchen gets remaining amount (weekly payout)
            },
            metadata: {
                orderId: order.orderId.toString(),
                kitchenId: kitchenId.toString(),
                userId: userId.toString(),
                kitchenAmount: kitchenAmount.toString(),
                platformFee: platformFee.toString(),
                serviceFee: serviceFee.toString(),
                resqboxGrossRevenue: resqboxGrossRevenue.toString(),
                resqboxNetCommission: resqboxNetCommission.toString(),
                cardId: cardId ? cardId.toString() : 'new_card'
            }
        };

        // Add application fee (Platform Fee + Service Fee)
        // Stripe will deduct their processing fee from this
        if (resqboxApplicationFee > 0) {
            paymentIntentData.application_fee_amount = Math.round(resqboxApplicationFee * 100);
        }

        // ========================================
        // 💳 CONFIGURE FOR SAVED CARD (if applicable)
        // ========================================
        if (savedCard) {
            console.log("🔐 [SAVED CARD] Configuring Payment Intent for saved card");

            // Fetch user's Stripe customer ID
            const user = await prisma.user.findUnique({
                where: { userId },
                select: { stripeCustomerId: true }
            });

            if (!user?.stripeCustomerId) {
                console.error("❌ [SAVED CARD] User has no Stripe customer ID");

                // Delete order since payment failed
                await prisma.orderItem.deleteMany({ where: { orderId: order.orderId } });
                await prisma.order.delete({ where: { orderId: order.orderId } });

                return res.status(400).json({
                    status: 0,
                    message: "Payment setup incomplete. Please add a new card."
                });
            }

            paymentIntentData.customer = user.stripeCustomerId; // 🔥 REQUIRED for saved cards
            paymentIntentData.payment_method = savedCard.stripePaymentMethodId;
            paymentIntentData.confirm = true;        // Auto-confirm payment
            paymentIntentData.off_session = true;    // Off-session payment
            console.log("   Customer ID:", user.stripeCustomerId);
            console.log("   Payment Method:", savedCard.stripePaymentMethodId);
            console.log("   Confirm: true (auto-confirm)");
            console.log("   Off Session: true");
        }

        const paymentIntent = await stripe.paymentIntents.create(paymentIntentData);

        console.log("✅ Payment Intent Created Successfully (Stripe Connect)");
        console.log("   Payment Intent ID:", paymentIntent.id);
        console.log("   Client Secret:", paymentIntent.client_secret ? "Generated ✓" : "Missing ✗");
        console.log("   Status:", paymentIntent.status);
        console.log("   Destination Account:", kitchen.stripeAccountId);
        console.log("   Application Fee: $", resqboxNetCommission.toFixed(2));
        console.log("====================================================\n");

        await prisma.orderPayment.create({
            data: {
                orderId: order.orderId,
                paymentIntentId: paymentIntent.id,
                amount: totalAmount,
                currency: "aud",
                status: paymentIntent.status === 'requires_action' ? 'REQUIRES_ACTION' :
                    paymentIntent.status === 'requires_capture' ? 'AUTHORIZED' :
                        paymentIntent.status === 'requires_confirmation' ? 'AUTHORIZED' : 'CREATED'
            }
        });

        console.log("✅ Order Payment Record Created");
        console.log("====================================================\n");

        // ========================================
        // ✅ RESPONSE BASED ON PAYMENT STATUS
        // ========================================

        // Handle different payment statuses
        if (paymentIntent.status === 'requires_action') {
            // 3D Secure authentication required (can happen with saved cards)
            console.log("⚠️  [PAYMENT] Payment requires 3DS authentication");

            return res.status(200).json({
                status: 1,
                message: "Payment requires authentication",
                requiresPayment: true,
                requiresAction: true,  // 🆕 Flag for 3DS
                paymentIntent: paymentIntent.id,
                clientSecret: paymentIntent.client_secret,
                publishableKey: process.env.STRIPE_PUBLISHABLE_KEY_VENDORS,
                cardUsed: savedCard ? {
                    cardBrand: savedCard.cardBrand,
                    cardLast4: savedCard.cardLast4
                } : null,
                orderDetails: {
                    orderId: order.orderId,
                    orderDisplayId,
                    pickupId,
                    kitchenId,
                    items: responseItems,
                    pickupStartTime: order.pickupStartTime,
                    pickupEndTime: order.pickupEndTime,
                    totalPaid: totalAmount,
                    discount: totalDiscount,
                    orderedAt: order.orderedAt,
                    timezone: responseItems[0]?.timezone || null
                }
            });
        } else if (paymentIntent.status === 'requires_payment_method' && savedCard) {
            // Saved card was declined (only treat as error if using saved card)
            console.log("❌ [PAYMENT] Saved card payment method declined");

            return res.status(400).json({
                status: 0,
                message: "Payment failed. Please try a different card.",
                error: "Card was declined",
                orderDetails: {
                    orderId: order.orderId,
                    orderDisplayId
                }
            });
        } else if (paymentIntent.status === 'requires_capture' || paymentIntent.status === 'requires_confirmation') {
            // Payment authorized successfully (saved card success)
            console.log("✅ [PAYMENT] Payment authorized successfully");

            // 🛒 Inactivate cart
            await prisma.cart.updateMany({
                where: { userId, isActive: 1 },
                data: { isActive: 0 }
            });
            console.log("✅ [CART] Cart inactivated for user", userId);

            return res.status(200).json({
                status: 1,
                message: "Order placed and payment authorized",
                requiresPayment: false,  // ✅ No further action needed
                paymentIntent: paymentIntent.id,
                cardUsed: savedCard ? {
                    cardBrand: savedCard.cardBrand,
                    cardLast4: savedCard.cardLast4
                } : null,
                orderDetails: {
                    orderId: order.orderId,
                    orderDisplayId,
                    pickupId,
                    kitchenId,
                    items: responseItems,
                    pickupStartTime: order.pickupStartTime,
                    pickupEndTime: order.pickupEndTime,
                    totalPaid: totalAmount,
                    discount: totalDiscount,
                    orderedAt: order.orderedAt,
                    timezone: responseItems[0]?.timezone || null
                }
            });
        } else {
            // Default response (new card flow or other statuses)
            console.log("🆕 [PAYMENT] Standard response - requires confirmation");

            return res.status(200).json({
                status: 1,
                message: "Order created. Complete payment to confirm.",
                requiresPayment: true,
                paymentIntent: paymentIntent.id,
                clientSecret: paymentIntent.client_secret,
                publishableKey: process.env.STRIPE_PUBLISHABLE_KEY_VENDORS,
                customer: paymentIntent.customer || null,
                ephemeralKey: null,
                orderDetails: {
                    orderId: order.orderId,
                    orderDisplayId,
                    pickupId,
                    kitchenId,
                    items: responseItems,
                    pickupStartTime: order.pickupStartTime,
                    pickupEndTime: order.pickupEndTime,
                    totalPaid: totalAmount,
                    discount: totalDiscount,
                    orderedAt: order.orderedAt,
                    timezone: responseItems[0]?.timezone || null
                }
            });
        }
    } catch (stripeError) {
        console.error("\n❌ ========== STRIPE PAYMENT INTENT ERROR ==========");
        console.error("Error Type:", stripeError.type);
        console.error("Error Code:", stripeError.code);
        console.error("Error Message:", stripeError.message);
        console.error("Raw Error:", stripeError.raw);
        console.error("====================================================\n");

        // Delete the order since payment failed
        // First delete order items (foreign key constraint)
        await prisma.orderItem.deleteMany({
            where: { orderId: order.orderId }
        });

        // Then delete the order
        await prisma.order.delete({ where: { orderId: order.orderId } });

        return res.status(400).json({
            status: 0,
            message: "Payment initialization failed",
            error: stripeError.message,
            errorCode: stripeError.code,
            details: {
                amount: totalAmount,
                amountInCents: Math.round(totalAmount * 100)
            }
        });
    }
});

const Stripe = require("stripe");
// Use VENDORS account - kitchens are onboarded here
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY_VENDORS);


exports.stripeWebhook = catchAsync(async (req, res) => {
    const sig = req.headers["stripe-signature"];
    const isV2 = req.headers["stripe-event-version"] === "v2";

    // 🔥 PERMANENT DEBUG LOG (Check 'stripe_webhooks.log' later)
    const fs = require('fs');
    try {
        const logMsg = `[${new Date().toLocaleString()}] HIT: ${req.headers['stripe-signature']?.substring(0, 10)}... | V2: ${isV2}\n`;
        fs.appendFileSync('stripe_webhooks.log', logMsg);
    } catch (e) { }

    console.log("================================================");
    console.log("🔔 [WEBHOOK] Stripe webhook received");
    console.log("================================================");
    console.log("🔍 [DEBUG] Body type:", typeof req.body);
    console.log("🔍 [DEBUG] Body is Buffer?:", Buffer.isBuffer(req.body));
    console.log("🔍 [DEBUG] Body length:", req.body?.length || 0);
    console.log("🔍 [DEBUG] Signature present?:", !!sig);
    console.log("🔍 [DEBUG] Webhook secret configured?:", !!process.env.STRIPE_WEBHOOK_SECRET);
    console.log("🔍 [DEBUG] Webhook secret starts with:", process.env.STRIPE_WEBHOOK_SECRET?.substring(0, 10));
    console.log("🔍 [DEBUG] Request URL:", req.originalUrl);
    console.log("🔍 [DEBUG] Content-Type:", req.headers["content-type"]);

    // Ensure we have a buffer
    if (!Buffer.isBuffer(req.body)) {
        console.error("❌ [WEBHOOK] Body is not a Buffer! This will cause signature verification to fail.");
        console.error("   Body type:", typeof req.body);
        console.error("   Body constructor:", req.body?.constructor?.name);

        // Try to recover if it's a string or object
        if (typeof req.body === 'string') {
            req.body = Buffer.from(req.body);
            console.log("⚠️  [WEBHOOK] Converted string to Buffer");
        } else if (typeof req.body === 'object' && req.rawBody) {
            req.body = Buffer.from(req.rawBody);
            console.log("⚠️  [WEBHOOK] Using rawBody as Buffer");
        } else {
            return res.status(400).send('Webhook Error: Request body must be a Buffer for signature verification');
        }
    }

    let event;
    try {
        if (isV2) {
            // 🔥 V2 (Thin) events → Log to DB and skip
            const body = JSON.parse(req.body.toString());
            console.log("ℹ️  [WEBHOOK] V2 event received - logging and skipping");

            await prisma.stripeEventLog.create({
                data: {
                    eventType: body.type || "v2_unknown",
                    eventId: body.id,
                    isV2: true,
                    status: "SKIPPED_V2",
                    body: body
                }
            }).catch(err => console.error("❌ [DB_LOG_ERROR] V2:", err.message));

            return res.json({ received: true, message: "V2 events logged but not processed" });
        } else {
            // 🔐 Snapshot events → MUST verify
            const webhookSecrets = [
                process.env.STRIPE_WEBHOOK_SECRET,
                process.env.STRIPE_WEBHOOK_SECRET_2,
                process.env.STRIPE_WEBHOOK_SECRET_CONNECT,
                process.env.STRIPE_WEBHOOK_SECRET_CONNECT_2,
                process.env.STRIPE_WEBHOOK_SECRET_PAYOUT
            ].filter(Boolean);

            let lastError;
            let verified = false;

            for (let i = 0; i < webhookSecrets.length; i++) {
                try {
                    const secret = webhookSecrets[i];
                    const secretName = i === 0 ? "MAIN" : i === 1 ? "MAIN_2" : i === 2 ? "CONNECT" : i === 3 ? "CONNECT_2" : "PAYOUT";

                    event = stripe.webhooks.constructEvent(req.body, sig, secret);

                    console.log(`✅ [WEBHOOK] Verified with secret #${i + 1} (${secretName})`);

                    // 🔥 SAVE TO DATABASE (Permanent Record)
                    await prisma.stripeEventLog.create({
                        data: {
                            eventId: event.id,
                            eventType: event.type,
                            account: event.account || null,
                            body: event,
                            isV2: false,
                            status: "RECEIVED"
                        }
                    }).catch(err => console.error("❌ [DB_LOG_ERROR] V1:", err.message));

                    // 🔥 FILE LOG
                    try {
                        const fs = require('fs');
                        fs.appendFileSync('stripe_webhooks.log', `[${new Date().toLocaleString()}] VERIFIED: ${event.type} | ID: ${event.id} | Account: ${event.account || 'Standard'}\n`);
                    } catch (e) { }

                    verified = true;
                    break;
                } catch (err) {
                    lastError = err;
                    console.log(`⚠️  [DEBUG] Secret #${i + 1} failed:`, err.message);
                    continue;
                }
            }

            // If none of the secrets worked, throw the last error
            if (!verified) {
                console.error("❌ [WEBHOOK] ALL SECRETS FAILED VERIFICATION");
                throw lastError;
            }
        }
    } catch (err) {
        console.error("❌ Stripe webhook error:", err.message);
        console.error("   Error type:", err.constructor.name);
        console.error("   Signature:", sig?.substring(0, 50) + "...");
        console.error("   Body preview:", req.body.toString().substring(0, 100) + "...");
        console.error("💡 [TIP] Make sure:");
        console.error("   1. The webhook secret matches the one in your Stripe dashboard");
        console.error("   2. You're using the raw request body (not parsed JSON)");
        console.error("   3. The request is coming directly from Stripe (not forwarded)");
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }
    switch (event.type) {
        // case "payment_intent.succeeded": {
        //     console.log("💰 [PAYMENT] Payment intent succeeded");
        //     const pi = event.data.object;

        //     const orderId = Number(pi.metadata.orderId);
        //     const kitchenId = Number(pi.metadata.kitchenId);
        //     const amount = pi.amount_received / 100;

        //     console.log("📦 [ORDER] Order ID:", orderId);
        //     console.log("🏪 [KITCHEN] Kitchen ID:", kitchenId);
        //     console.log("💵 [AMOUNT] Amount received: AUD", amount.toFixed(2));
        //     console.log("🆔 [STRIPE] Payment Intent ID:", pi.id);

        //     // 1️⃣ Update payment
        //     console.log("📝 [PAYMENT] Updating payment status to SUCCEEDED...");
        //     await prisma.orderPayment.update({
        //         where: { paymentIntentId: pi.id },
        //         data: { status: "SUCCEEDED" }
        //     });
        //     console.log("✅ [PAYMENT] Payment status updated");

        //     // 2️⃣ Update order
        //     console.log("📝 [ORDER] Updating order payment status to PAID...");
        //     const order = await prisma.order.update({
        //         where: { orderId },
        //         data: { paymentStatus: "PAID", status: "PENDING" },
        //         include: {
        //             kitchen: { select: { kitchenName: true } },
        //             items: {
        //                 include: {
        //                     menu: { select: { name: true, startTime: true, endTime: true } }
        //                 }
        //             }
        //         }
        //     });
        //     console.log("✅ [ORDER] Order status updated to PAID");
        //     console.log("🍽️  [ORDER] Items count:", order.items.length);

        //     // 3️⃣ Ledger CREDIT - Store kitchen's actual earning
        //     const kitchenEarning = order.totalAmount - order.platformFee;
        //     console.log("💰 [LEDGER] Creating ledger entry...");
        //     console.log("   Total Amount: AUD", order.totalAmount.toFixed(2));
        //     console.log("   Platform Fee: AUD", order.platformFee.toFixed(2));
        //     console.log("   Kitchen Earning: AUD", kitchenEarning.toFixed(2));

        //     await prisma.kitchenLedger.create({
        //         data: {
        //             kitchenId,
        //             orderId,
        //             type: "CREDIT",
        //             amount: kitchenEarning, // Kitchen's earning after platform fee
        //             description: `Order #${orderId} payment`
        //         }
        //     });
        //     console.log("✅ [LEDGER] Ledger entry created");

        //     // 4️⃣ � REDUCE MENU ITEM QUANTITIES
        //     console.log("📦 [INVENTORY] Reducing menu item quantities...");
        //     for (const item of order.items) {
        //         const menuItem = await prisma.menuItem.findUnique({
        //             where: { id: item.menuItemId },
        //             select: { id: true, name: true, quantity: true }
        //         });

        //         if (menuItem) {
        //             const newQuantity = Math.max(0, menuItem.quantity - item.quantity);

        //             await prisma.menuItem.update({
        //                 where: { id: item.menuItemId },
        //                 data: { quantity: newQuantity }
        //             });

        //             console.log(`   ✅ [INVENTORY] ${menuItem.name}: ${menuItem.quantity} → ${newQuantity} (reduced by ${item.quantity})`);
        //         } else {
        //             console.log(`   ⚠️  [INVENTORY] Menu item ${item.menuItemId} not found`);
        //         }
        //     }
        //     console.log("✅ [INVENTORY] All quantities updated");

        //     // 5️⃣ �📲 SEND PUSH NOTIFICATION TO VENDOR
        //     console.log("📲 [NOTIFICATION] Fetching kitchen device token...");
        //     const kitchen = await prisma.kitchen.findUnique({
        //         where: { kitchenId },
        //         select: { deviceToken: true, kitchenName: true }
        //     });

        //     if (kitchen?.deviceToken) {
        //         console.log("✅ [NOTIFICATION] Device token found for:", kitchen.kitchenName);
        //         const { sendNotificationToUser } = require("./handleFactory");
        //         const orderDisplayId = "OD" + String(orderId).padStart(8, "0");

        //         console.log("📤 [NOTIFICATION] Sending push notification...");
        //         console.log("   Title: New Order Received! 🎉");
        //         console.log("   Body: Order", orderDisplayId, "- AUD", amount.toFixed(2));

        //         await sendNotificationToUser(
        //             kitchenId,
        //             {
        //                 title: "New Order Received! 🎉",
        //                 body: `Order ${orderDisplayId} - AUD ${amount.toFixed(2)}`
        //             },
        //             kitchen.deviceToken
        //         );
        //         console.log("✅ [NOTIFICATION] Push notification sent");

        //         // Save notification to database
        //         console.log("💾 [NOTIFICATION] Saving notification to database...");
        //         await prisma.notification.create({
        //             data: {
        //                 ownerId: kitchenId,
        //                 ownerType: "KITCHEN",
        //                 title: "New Order Received! 🎉",
        //                 message: `Order ${orderDisplayId} - AUD ${amount.toFixed(2)}`,
        //                 type: 1 // 1 = Order notification
        //             }
        //         });
        //         console.log("✅ [NOTIFICATION] Notification saved to database");
        //     } else {
        //         console.log("⚠️  [NOTIFICATION] No device token found for kitchen:", kitchenId);
        //     }

        //     // 6️⃣ 🔥 SOCKET EMIT
        //     console.log("🔌 [SOCKET] Emitting newOrder event to kitchen_" + kitchenId);
        //     const io = getIO();
        //     io.to(`kitchen_${kitchenId}`).emit("newOrder", order);
        //     console.log("✅ [SOCKET] Event emitted successfully");

        //     // 7️⃣ ⏰ SCHEDULE ORDER ACCEPTANCE CHECK
        //     console.log("⏰ [ORDER ACCEPTANCE] Scheduling acceptance check...");
        //     try {
        //         const { scheduleOrderAcceptanceCheck } = require("../cron/orderAcceptanceChecker");

        //         // Get the maximum time to accept order from config
        //         const acceptanceConfig = await prisma.config.findFirst({
        //             where: { configKey: "Maximum time to Accept Order" }
        //         });

        //         if (acceptanceConfig) {
        //             const delayMinutes = Number(acceptanceConfig.configValue);
        //             if (!isNaN(delayMinutes) && delayMinutes > 0) {
        //                 await scheduleOrderAcceptanceCheck(orderId, delayMinutes);
        //                 console.log(`✅ [ORDER ACCEPTANCE] Scheduled check for Order #${orderId} in ${delayMinutes} minutes`);
        //             } else {
        //                 console.log("⚠️  [ORDER ACCEPTANCE] Invalid config value:", acceptanceConfig.configValue);
        //             }
        //         } else {
        //             console.log("⚠️  [ORDER ACCEPTANCE] Config 'Maximum time to Accept Order' not found");
        //         }
        //     } catch (scheduleError) {
        //         console.error("❌ [ORDER ACCEPTANCE] Error scheduling check:", scheduleError.message);
        //         // Don't fail the webhook if scheduling fails
        //     }

        //     console.log("================================================");
        //     console.log("✅ [WEBHOOK] Payment succeeded processing complete");
        //     console.log("================================================");
        //     break;
        // }
        case "payment_intent.amount_capturable_updated": {
            // Money is AUTHORIZED (user placed order) - NOT YET CAPTURED
            console.log("💰 [PAYMENT] Payment authorized (amount_capturable_updated)");
            const pi = event.data.object;

            const orderId = Number(pi.metadata.orderId);
            const kitchenId = Number(pi.metadata.kitchenId);
            const amount = pi.amount_capturable / 100;

            console.log("📦 [ORDER] Order ID:", orderId);
            console.log("🏪 [KITCHEN] Kitchen ID:", kitchenId);
            console.log("💵 [AMOUNT] Amount authorized: AUD", amount.toFixed(2));
            console.log("🆔 [STRIPE] Payment Intent ID:", pi.id);

            // 1️⃣ Update payment status to AUTHORIZED
            console.log("📝 [PAYMENT] Updating payment status to AUTHORIZED...");
            await prisma.orderPayment.update({
                where: { paymentIntentId: pi.id },
                data: { status: "AUTHORIZED" }
            });
            console.log("✅ [PAYMENT] Payment status updated to AUTHORIZED");

            // 2️⃣ Update order status to PENDING (waiting for vendor acceptance)
            console.log("📝 [ORDER] Updating order status to PENDING...");
            const order = await prisma.order.update({
                where: { orderId },
                data: { status: "PENDING" },
                select: {
                    orderId: true,
                    orderNumber: true,
                    totalAmount: true,
                    platformFee: true,
                    pickupEndTime: true,
                    kitchen: {
                        select: {
                            kitchenName: true,
                            timezone: { select: { name: true } }
                        }
                    },
                    items: {
                        include: {
                            menu: { select: { name: true, startTime: true, endTime: true } }
                        }
                    }
                }
            });
            console.log("✅ [ORDER] Order status updated to PENDING");
            console.log("🍽️  [ORDER] Items count:", order.items.length);

            // 3️⃣ Ledger CREDIT - Store kitchen's potential earning (will be finalized on capture)
            const kitchenEarning = order.totalAmount - order.platformFee;
            console.log("💰 [LEDGER] Creating ledger entry...");
            console.log("   Total Amount: AUD", order.totalAmount.toFixed(2));
            console.log("   Platform Fee: AUD", order.platformFee.toFixed(2));
            console.log("   Kitchen Earning: AUD", kitchenEarning.toFixed(2));

            await prisma.kitchenLedger.create({
                data: {
                    kitchenId,
                    orderId,
                    type: "CREDIT",
                    amount: kitchenEarning,
                    description: `Order #${orderId} payment authorized`
                }
            });
            console.log("✅ [LEDGER] Ledger entry created");

            // 4️⃣ REDUCE MENU ITEM QUANTITIES
            console.log("📦 [INVENTORY] Reducing menu item quantities...");
            for (const item of order.items) {
                const menuItem = await prisma.menuItem.findUnique({
                    where: { id: item.menuItemId },
                    select: { id: true, name: true, quantity: true }
                });

                if (menuItem) {
                    const newQuantity = Math.max(0, menuItem.quantity - item.quantity);

                    await prisma.menuItem.update({
                        where: { id: item.menuItemId },
                        data: { quantity: newQuantity }
                    });

                    console.log(`   ✅ [INVENTORY] ${menuItem.name}: ${menuItem.quantity} → ${newQuantity} (reduced by ${item.quantity})`);
                } else {
                    console.log(`   ⚠️  [INVENTORY] Menu item ${item.menuItemId} not found`);
                }
            }
            console.log("✅ [INVENTORY] All quantities updated");

            // 🛒 Inactivate cart
            const userId = Number(pi.metadata.userId);
            if (userId) {
                await prisma.cart.updateMany({
                    where: { userId, isActive: 1 },
                    data: { isActive: 0 }
                });
                console.log(`✅ [CART] Cart inactivated for user ${userId} via webhook`);
            }

            // 5️⃣ SEND PUSH NOTIFICATION TO VENDOR
            console.log("📲 [NOTIFICATION] Fetching kitchen device token...");
            const kitchen = await prisma.kitchen.findUnique({
                where: { kitchenId },
                select: { deviceToken: true, kitchenName: true }
            });

            if (kitchen?.deviceToken) {
                console.log("✅ [NOTIFICATION] Device token found for:", kitchen.kitchenName);
                const { sendNotificationToUser } = require("./handleFactory");
                const orderDisplayId = "OD" + String(order.orderNumber);

                console.log("📤 [NOTIFICATION] Sending push notification...");
                console.log("   Title: New Order Received! 🎉");
                console.log("   Body: Order", orderDisplayId, "- AUD", amount.toFixed(2));

                const notificationResult = await require("./handleFactory").sendNotificationToKitchen(
                    kitchenId,
                    {
                        title: "New Order Received! 🎉",
                        body: `Order ${orderDisplayId} - AUD ${amount.toFixed(2)}`,
                        orderId: orderId.toString(),
                        status: "PENDING"
                    }
                );

                if (notificationResult.success) {
                    console.log(`✅ [NOTIFICATION] Push notification sent to ${notificationResult.successCount} devices`);
                } else {
                    console.log("⚠️  [NOTIFICATION] Push notification failed:", notificationResult.error);
                }

                // Save notification to database (even if push fails)
                console.log("💾 [NOTIFICATION] Saving notification to database...");
                await prisma.notification.create({
                    data: {
                        ownerId: kitchenId,
                        ownerType: "KITCHEN",
                        title: "New Order Received! 🎉",
                        message: `Order ${orderDisplayId} - AUD ${amount.toFixed(2)}`,
                        orderId: orderId,
                        type: 1
                    }
                });
                console.log("✅ [NOTIFICATION] Notification saved to database");
            } else {
                console.log("⚠️  [NOTIFICATION] No device token found for kitchen:", kitchenId);
            }

            // 6️⃣ SOCKET EMIT
            console.log("🔌 [SOCKET] Emitting newOrder event to kitchen_" + kitchenId);
            const io = getIO();
            io.to(`kitchen_${kitchenId}`).emit("newOrder", order);
            console.log("✅ [SOCKET] Event emitted successfully");

            // 7️⃣ ⏰ SCHEDULE ORDER ACCEPTANCE CHECK
            console.log("⏰ [ORDER ACCEPTANCE] Scheduling acceptance check...");
            try {
                const { scheduleOrderAcceptanceCheck } = require("../cron/orderAcceptanceChecker");

                // Get the maximum time to accept order from config
                const acceptanceConfig = await prisma.config.findFirst({
                    where: { configKey: "Maximum time to Accept Order" }
                });

                if (acceptanceConfig) {
                    const delayMinutes = Number(acceptanceConfig.configValue);
                    if (!isNaN(delayMinutes) && delayMinutes > 0) {
                        await scheduleOrderAcceptanceCheck(orderId, delayMinutes);
                        console.log(`✅ [ORDER ACCEPTANCE] Scheduled check for Order #${orderId} in ${delayMinutes} minutes`);
                    } else {
                        console.log("⚠️  [ORDER ACCEPTANCE] Invalid config value:", acceptanceConfig.configValue);
                    }
                } else {
                    console.log("⚠️  [ORDER ACCEPTANCE] Config 'Maximum time to Accept Order' not found");
                }
            } catch (scheduleError) {
                console.error("❌ [ORDER ACCEPTANCE] Error scheduling check:", scheduleError.message);
                // Don't fail the webhook if scheduling fails
            }

            // 8️⃣ ⏰ SCHEDULE NO SHOW CHECK
            console.log("⏰ [NO SHOW] Scheduling no-show check...");
            try {
                const { scheduleNoShowCheck } = require("../cron/orderNoShowChecker");

                const noShowConfig = await prisma.config.findFirst({
                    where: { configKey: "Max Time to Hold Order Post Pickup End Time" }
                });

                const bufferMinutes = noShowConfig ? Number(noShowConfig.configValue) : 30;
                const timezoneName = order.kitchen?.timezone?.name || "Australia/Sydney";

                if (order.pickupEndTime) {
                    await scheduleNoShowCheck(orderId, order.pickupEndTime, bufferMinutes, timezoneName);
                    console.log(`✅ [NO SHOW] Scheduled check for Order #${orderId} at ${order.pickupEndTime} + ${bufferMinutes} min`);
                }
            } catch (noShowError) {
                console.error("❌ [NO SHOW] Error scheduling check:", noShowError.message);
            }

            console.log("================================================");
            console.log("✅ [WEBHOOK] Payment authorization processing complete");
            console.log("================================================");
            break;
        }

        case "payment_intent.succeeded": {
            // Money is CAPTURED (kitchen accepted)
            console.log("💰 [PAYMENT] Payment captured (succeeded)");
            await prisma.orderPayment.update({
                where: { paymentIntentId: event.data.object.id },
                data: { status: "SUCCEEDED" }
            });

            await prisma.order.update({
                where: { orderId: Number(event.data.object.metadata.orderId) },
                data: { paymentStatus: "PAID" }
            });

            console.log("✅ [PAYMENT] Payment captured and order marked as PAID");
            break;
        }
        case "payment_intent.payment_failed": {
            console.log("❌ [PAYMENT] Payment intent failed");
            const pi = event.data.object;
            const orderId = Number(pi.metadata.orderId);

            console.log("📦 [ORDER] Order ID:", orderId);
            console.log("🆔 [STRIPE] Payment Intent ID:", pi.id);
            console.log("⚠️  [ERROR] Failure reason:", pi.last_payment_error?.message || "Unknown");

            // Update payment + order
            console.log("📝 [PAYMENT] Updating payment status to FAILED...");
            await prisma.orderPayment.update({
                where: { paymentIntentId: pi.id },
                data: {
                    status: "FAILED",
                    failureReason: pi.last_payment_error?.message
                }
            });
            console.log("✅ [PAYMENT] Payment status updated to FAILED");

            // Option A: mark failed
            console.log("📝 [ORDER] Marking order as FAILED...");
            await prisma.order.update({
                where: { orderId },
                data: { paymentStatus: "FAILED" }
            });
            console.log("✅ [ORDER] Order marked as FAILED");

            // Option B (optional): delete order
            // await prisma.order.delete({ where: { orderId } });

            console.log("================================================");
            console.log("❌ [WEBHOOK] Payment failed processing complete");
            console.log("================================================");
            break;
        }
        case "payout.paid": {
            try {
                console.log("\n================================================");
                console.log("💰 [PAYOUT] Payout paid event received");
                console.log("================================================");
                const payout = event.data.object;
                const stripeAccountId = event.account; // 🔥 Connect Account ID

                console.log("🆔 [PAYOUT] Stripe Payout ID:", payout.id);
                console.log("🏦 [PAYOUT] Stripe Account ID (Connect):", stripeAccountId);
                console.log("💵 [PAYOUT] Amount:", payout.amount / 100, payout.currency);

                if (!stripeAccountId) {
                    console.error("❌ [PAYOUT] No stripeAccountId (event.account) found in event metadata!");
                    console.log("🔍 [DEBUG] Full event data object keys:", Object.keys(event));
                    break;
                }

                // 1️⃣ Find kitchen with full details
                console.log("🔍 [PAYOUT] Searching for kitchen with account ID:", stripeAccountId);
                const kitchen = await prisma.kitchen.findFirst({
                    where: { stripeAccountId },
                    include: {
                        address: true,
                        kyc: true  // Include KYC data for ABN
                    }
                });

                if (!kitchen) {
                    console.error("⚠️ [PAYOUT] Kitchen not found for Stripe account:", stripeAccountId);
                    break;
                }

                console.log("🏪 [PAYOUT] Kitchen found:", kitchen.kitchenName, "(ID:", kitchen.kitchenId + ")");

                // 2️⃣ Check if this payout has already been processed
                const existingPayout = await prisma.kitchenPayout.findFirst({
                    where: { stripeTransferId: payout.id }
                });

                if (existingPayout) {
                    console.log("⚠️ [PAYOUT] Payout already processed in our DB:", payout.id);
                    break;
                }

                // 3️⃣ Get the last payout to determine the period start
                const lastPayout = await prisma.kitchenPayout.findFirst({
                    where: { kitchenId: kitchen.kitchenId },
                    orderBy: { periodEnd: "desc" }
                });

                console.log("📊 [PAYOUT] Proceeding with period calculation...");

                // Period start logic:
                // - If previous payout exists: use day after last payout ended
                // - If no previous payout: use Monday 12 AM of current week
                // let periodStart;
                // if (lastPayout?.periodEnd) {
                //     // Use day after last payout ended
                //     periodStart = new Date(lastPayout.periodEnd.getTime() + 86400000); // Add 1 day
                // } else {
                //     // Use Monday 12 AM of current week
                //     const now = new Date(payout.created * 1000);
                //     const dayOfWeek = now.getDay(); // 0 = Sunday, 1 = Monday, ..., 6 = Saturday

                //     // Calculate days to subtract to get to Monday (1 = Monday)
                //     const daysToMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;

                //     periodStart = new Date(now);
                //     periodStart.setDate(periodStart.getDate() - daysToMonday);
                //     periodStart.setHours(0, 0, 0, 0); // Set to 12 AM

                //     console.log("📅 [PAYOUT] No previous payout found, using Monday 12 AM:", periodStart.toISOString());
                // }

                //   // Period end: payout creation time
                // const periodEnd = new Date(payout.created * 1000);

                // console.log("📅 [PAYOUT] Period Start:", periodStart.toISOString());
                // console.log("📅 [PAYOUT] Period End:", periodEnd.toISOString());

                let periodStart;
                const creationDate = new Date(payout.created * 1000);
                // // ✅ Snap End Date to the MOST RECENT Monday 12:00 AM
                // const endDay = creationDate.getDay();
                // const endDaysSinceMonday = endDay === 0 ? 6 : endDay - 1;
                // ✅ Snap End Date to the MOST RECENT Monday 00:00 UTC
                // Stripe payout timestamps are UTC — use UTC day methods to avoid server TZ issues
                const endDayUTC = creationDate.getUTCDay(); // 0=Sun, 1=Mon, …, 6=Sat
                const endDaysSinceMonday = endDayUTC === 0 ? 6 : endDayUTC - 1;

                const periodEnd = new Date(creationDate);
                //          periodEnd.setDate(creationDate.getDate() - endDaysSinceMonday);
                // periodEnd.setHours(0, 0, 0, 0);
                periodEnd.setUTCDate(creationDate.getUTCDate() - endDaysSinceMonday);
                periodEnd.setUTCHours(0, 0, 0, 0); // Monday 00:00:00 UTC

                if (lastPayout?.periodEnd) {
                    // ✅ Normal weekly continuation — start exactly where last period ended
                    periodStart = new Date(lastPayout.periodEnd);
                } else {
                    // ✅ First payout ever → 7 days before this Monday
                    periodStart = new Date(periodEnd);
                    // periodStart.setDate(periodEnd.getDate() - 7);
                    // periodStart.setHours(0, 0, 0, 0);
                    periodStart.setUTCDate(periodEnd.getUTCDate() - 7);
                    periodStart.setUTCHours(0, 0, 0, 0);
                }

                console.log("📅 [PAYOUT] Period Start (Locked to Monday UTC):", periodStart.toISOString());
                console.log("📅 [PAYOUT] Period End   (Locked to Monday UTC):", periodEnd.toISOString());

                // 4️⃣ Fetch ONLY eligible paid orders in the payout period
                // ⭐ CRITICAL: Only include orders that kitchen should be paid for
                // ✅ Include: ACCEPTED, PREPARING, READY, PICKED (completed orders)
                // ❌ Exclude: REJECTED, PENDING, CANCELLED, NO_SHOW, PAYMENT_PENDING
                const orders = await prisma.order.findMany({
                    where: {
                        kitchenId: kitchen.kitchenId,
                        paymentStatus: "PAID",
                        status: {
                            in: ["ACCEPTED", "PREPARING", "READY", "PICKED", "NO_SHOW"]  // ⭐ ONLY eligible statuses
                        },
                        // orderedAt: {
                        //     gte: periodStart,
                        //     lte: periodEnd
                        // }
                        orderedAt: {
                            gt: periodStart,
                            lte: periodEnd
                        }

                    },
                    select: {
                        orderId: true,
                        orderNumber: true,
                        totalAmount: true,
                        platformFee: true,
                        status: true,
                        orderedAt: true,
                        items: {
                            select: {
                                quantity: true
                            }
                        }
                    }
                });

                console.log("📦 [PAYOUT] Orders found:", orders.length);

                if (orders.length === 0) {
                    console.log("⚠️ [PAYOUT] No paid orders in period — recording zero-payout and continuing");
                    // Still record the payout period to prevent gaps / re-processing
                    await prisma.kitchenPayout.create({
                        data: {
                            kitchenId: kitchen.kitchenId,
                            periodStart,
                            periodEnd,
                            totalOrderAmount: 0,
                            platformFeeAmount: 0,
                            payoutAmount: 0,
                            ordersCount: 0,
                            stripeTransferId: payout.id
                        }
                    });
                    await prisma.stripeEventLog.update({
                        where: { eventId: event.id },
                        data: { status: "PROCESSED" }
                    }).catch(() => { });
                    console.log("✅ [PAYOUT] Zero-payout period recorded, no invoice generated");
                    break;
                }

                // 5️⃣ Calculate totals from ALL orders
                const totalOrderAmount = orders.reduce((sum, o) => sum + Number(o.totalAmount), 0);
                const totalPlatformFees = orders.reduce((sum, o) => sum + Number(o.platformFee), 0);

                console.log("💰 [PAYOUT] Total Order Amount:", totalOrderAmount);
                console.log("💰 [PAYOUT] Total Platform Fees:", totalPlatformFees);

                // Get Service Fee Percentage from config
                const serviceFeeConfig = await prisma.config.findFirst({
                    where: { configKey: "Service Fee Percentage" }
                });
                const serviceFeePercent = Number(serviceFeeConfig?.configValue) || 15;

                // Calculate item total (excluding platform fees)
                const itemTotal = totalOrderAmount - totalPlatformFees;

                // Service fee is calculated on item total (product amount only)
                const serviceFeeAmount = Number(((itemTotal * serviceFeePercent) / 100).toFixed(2));

                // Calculate actual payout amount
                const payoutAmount = totalOrderAmount - totalPlatformFees - serviceFeeAmount;

                console.log("💰 [PAYOUT] Item Total:", itemTotal);
                console.log("💰 [PAYOUT] Service Fee (" + serviceFeePercent + "%):", serviceFeeAmount);
                console.log("💰 [PAYOUT] Net Payout Amount:", payoutAmount);

                // 6️⃣ Save KitchenPayout record
                const kitchenPayout = await prisma.kitchenPayout.create({
                    data: {
                        kitchenId: kitchen.kitchenId,
                        periodStart,
                        periodEnd,
                        totalOrderAmount,
                        platformFeeAmount: totalPlatformFees,
                        payoutAmount,
                        ordersCount: orders.length,
                        stripeTransferId: payout.id // Use payout ID as reference
                    }
                });

                console.log("✅ [PAYOUT] Kitchen payout record created (ID:", kitchenPayout.payoutId + ")");

                // 6.5️⃣ Update Kitchen Ledger (Debit)
                await prisma.kitchenLedger.create({
                    data: {
                        kitchenId: kitchen.kitchenId,
                        type: "DEBIT",
                        amount: payoutAmount,
                        description: `Weekly payout for period ${periodStart.toLocaleDateString()} - ${periodEnd.toLocaleDateString()}. Ref: ${payout.id}`
                    }
                });
                console.log("✅ [LEDGER] Kitchen ledger updated (DEBIT)");

                // 7️⃣ Generate invoice
                const { getNextInvoiceNumber, generatePayoutInvoice } = require("../utils/invoiceGenerator");

                const invoiceNumber = await getNextInvoiceNumber();
                const restaurantCode = "REST" + String(kitchen.kitchenId).padStart(4, "0");

                console.log("📄 [INVOICE] Generating invoice:", invoiceNumber);
                console.log("📄 [INVOICE] Restaurant Code:", restaurantCode);

                const invoiceData = {
                    invoiceNumber,
                    kitchen,
                    restaurantCode,
                    periodStart,
                    periodEnd,
                    totalCredits: totalOrderAmount,
                    platformFeesDeducted: totalPlatformFees,
                    serviceFeeAmount: serviceFeeAmount,
                    serviceFeePercent: serviceFeePercent,
                    payoutAmount,
                    orderCount: orders.length,
                    orders: orders.map(o => ({
                        orderId: o.orderId,
                        orderDisplayId: "OD" + String(o.orderNumber),
                        numberOfItems: o.items.reduce((sum, item) => sum + item.quantity, 0),
                        totalAmount: Number(o.totalAmount),
                        status: o.status,
                        orderedAt: o.orderedAt
                    })),
                    stripeTransferId: payout.id,
                    createdAt: new Date()
                };

                const { pdfUrl } = await generatePayoutInvoice(invoiceData);

                console.log("✅ [INVOICE] Invoice PDF generated:", pdfUrl);

                // 8️⃣ Save invoice record
                const invoice = await prisma.payoutInvoice.create({
                    data: {
                        payoutId: kitchenPayout.payoutId,
                        invoiceNumber,
                        pdfUrl
                    }
                });

                console.log("✅ [INVOICE] Invoice record saved (ID:", invoice.invoiceId + ")");

                // ✅ UPDATE LOG STATUS TO PROCESSED
                await prisma.stripeEventLog.update({
                    where: { eventId: event.id },
                    data: { status: "PROCESSED" }
                }).catch(() => { });

                console.log("================================================");
                console.log("✅ [PAYOUT] Payout processing complete for kitchen", kitchen.kitchenId);
                console.log("   - Payout Amount:", payoutAmount);
                console.log("   - Orders Count:", orders.length);
                console.log("   - Invoice Number:", invoiceNumber);
                console.log("   - Invoice URL:", pdfUrl);
                console.log("================================================");
            } catch (error) {
                console.error("❌ [PAYOUT] Error processing payout.paid webhook:", error);

                // ✅ UPDATE LOG STATUS TO FAILED
                await prisma.stripeEventLog.update({
                    where: { eventId: event.id },
                    data: {
                        status: "FAILED",
                        errorMessage: error.message
                    }
                }).catch(() => { });

                console.error("   Error details:", error.message);
                console.error("   Stack trace:", error.stack);
            }
            break;
        }
        case "account.updated": {
            const account = event.data.object;
            const stripeAccountId = account.id;

            console.log("🏪 [STRIPE] Account updated (v1):", stripeAccountId);

            const isCompleted =
                account.details_submitted === true &&
                account.capabilities?.card_payments === "active" &&
                account.capabilities?.transfers === "active" &&
                (!account.requirements?.currently_due ||
                    account.requirements.currently_due.length === 0);

            await prisma.kitchen.updateMany({
                where: { stripeAccountId },
                data: {
                    stripeOnboardingCompleted: isCompleted
                }
            });

            console.log("✅ [STRIPE] Onboarding status updated:", isCompleted);

            // 📡 Trigger socket to kitchen to update UI
            if (isCompleted) {
                try {
                    const kitchen = await prisma.kitchen.findFirst({
                        where: { stripeAccountId },
                        select: { kitchenId: true }
                    });
                    if (kitchen) {
                        const io = getIO();
                        io.to(`kitchen_${kitchen.kitchenId}`).emit("stripe-onboarding-completed", {
                            success: true,
                            message: "Stripe onboarding completed successfully"
                        });
                        console.log(`📡 [SOCKET] Notified kitchen ${kitchen.kitchenId} about onboarding completion via webhook`);
                    }
                } catch (socketError) {
                    console.error(`⚠️ [SOCKET] Failed to notify kitchen about onboarding completion:`, socketError.message);
                }
            }
            break;
        }

        case "v2.core.account.updated": {
            const account = event.data.object;

            console.log("🏪 [STRIPE] Account updated (v2):", account.id);

            const isCompleted =
                account.details_submitted === true &&
                account.charges_enabled === true &&
                account.payouts_enabled === true &&
                account.capabilities?.transfers === 'active';

            await prisma.kitchen.updateMany({
                where: { stripeAccountId: account.id },
                data: {
                    stripeOnboardingCompleted: isCompleted
                }
            });

            console.log("✅ [STRIPE] Onboarding status updated:", isCompleted);

            // 📡 Trigger socket to kitchen to update UI
            if (isCompleted) {
                try {
                    const kitchen = await prisma.kitchen.findFirst({
                        where: { stripeAccountId: account.id },
                        select: { kitchenId: true }
                    });
                    if (kitchen) {
                        const io = getIO();
                        io.to(`kitchen_${kitchen.kitchenId}`).emit("stripe-onboarding-completed", {
                            success: true,
                            message: "Stripe onboarding completed successfully"
                        });
                        console.log(`📡 [SOCKET] Notified kitchen ${kitchen.kitchenId} about onboarding completion via v2 webhook`);
                    }
                } catch (socketError) {
                    console.error(`⚠️ [SOCKET] Failed to notify kitchen about onboarding completion:`, socketError.message);
                }
            }
            break;
        }

        default:
            console.log("ℹ️  [WEBHOOK] Unhandled event type:", event.type);
    }


    console.log("✅ [WEBHOOK] Responding with success");
    res.json({ received: true });
});

exports.getMyOrders = catchAsync(async (req, res) => {
    const { userId } = req.user;
    const { type } = req.query;

    let filterStatus = {};

    if (type == 1) {
        filterStatus = {
            status: { in: ["PENDING", "ACCEPTED", "PREPARING", "READY"] }
        };
    } else if (type == 2) {
        filterStatus = {
            status: { in: ["PICKED", "REJECTED", "NO_SHOW", "CANCELLED"] }
        };
    }

    const orders = await prisma.order.findMany({
        where: { userId, ...filterStatus },
        orderBy: { orderedAt: "desc" },
        include: {
            kitchen: {
                select: {
                    kitchenName: true, address: {   // 👈 include KitchenAddress
                        select: {
                            houseNo: true,
                            street: true,
                            pincode: true,
                            state: true,
                            city: true,
                            country: true,
                            landmark: true,
                            latitude: true,
                            longitude: true
                        }
                    }
                }
            },
            items: {
                include: {
                    menu: { select: { name: true, image: true } }
                }
            },
            orderInvoice: true  // ⭐ Include invoice data
        }
    });

    const formattedOrders = orders.map(order => {

        // OD00000007 format
        const orderDisplayId = "OD" + String(order.orderNumber);

        const itemsList = order.items.map(i => ({
            menuItemId: i.menuItemId,
            name: i.menu.name,
            quantity: i.quantity,
            // 👇 Add full S3 image URL
            image: i.menu.image
                ? process.env.menu_s3 + i.menu.image
                : null
        }));

        return {
            orderId: order.orderId,
            rating: order.rating,
            orderDisplayId,
            title: itemsList[0]?.name || "",
            items: itemsList,
            restaurantName: order.kitchen?.kitchenName || "",
            address: order.kitchen?.address || null,   // 👈 full address object
            amount: order.totalAmount,
            status: order.status,
            orderedAt: order.orderedAt,   // raw value
            // ⭐ Add invoice information
            invoice: order.orderInvoice ? {
                invoiceNumber: order.orderInvoice.invoiceNumber,
                pdfUrl: order.orderInvoice.pdfUrl,
                createdAt: order.orderInvoice.createdAt
            } : null
        };
    });

    return res.json({
        status: 1,
        message: "Orders fetched successfully",
        orders: formattedOrders
    });
});

exports.getOrderDetails = catchAsync(async (req, res) => {
    const { userId } = req.user;
    const { orderId } = req.params;
    console.log(orderId);

    const MENU_IMG = process.env.menu_s3;
    const KITCHEN_IMG = process.env.kitchen_s3;

    const order = await prisma.order.findFirst({
        where: { orderId: Number(orderId), userId }, //  orderId: Number(orderId), or orderUid: orderId
        include: {
            kitchen: {
                include: {
                    photos: true,
                    address: true,
                    timezone: {
                        select: {
                            id: true,
                            name: true,
                            displayName: true,
                            offset: true
                        }
                    }
                }
            },
            items: {
                include: {
                    menu: true
                }
            },
            orderInvoice: true // Include invoice data (only for picked restaurants)
        }
    });

    if (!order) {
        return res.status(404).json({
            status: 0,
            message: "Order not found"
        });
    }

    // 👇 Format Order ID like OD00000125
    const orderDisplayId = "OD" + String(order.orderNumber);

    // ⭐ Format items
    const formattedItems = order.items.map((oi) => ({
        menuItemId: oi.menuItemId,
        name: oi.menu?.name,
        quantity: oi.quantity,
        image: oi.menu?.image ? `${MENU_IMG}${oi.menu.image}` : null,
        startTime: oi.menu?.startTime,
        endTime: oi.menu?.endTime
    }));

    // take gst percentage from config 

    const config = await prisma.config.findMany({
        where: {
            configKey: { in: ["GST Percentage"] }
        }
    });

    const TAX_PERCENT = Number(config.find(c => c.configKey === "GST Percentage")?.configValue) || 5;

    return res.json({
        status: 1,
        message: "Order details fetched successfully",
        order: {
            orderDisplayId,
            ...order,
            taxPercent: TAX_PERCENT,
            items: formattedItems,
            kitchen: {
                kitchenId: order.kitchen.kitchenId,
                kitchenName: order.kitchen.kitchenName,
                kitchenImage: order.kitchen.photos?.kitchenProfilePhoto
                    ? `${KITCHEN_IMG}${order.kitchen.photos.kitchenProfilePhoto}`
                    : null,
                address: order.kitchen.address,
                timezone: order.kitchen.timezone || null
            }
        }
    });
});

exports.cancelOrder = catchAsync(async (req, res) => {
    const { userId } = req.user;
    const { orderId, reason } = req.body;

    if (!orderId) {
        return res.status(400).json({ status: 0, message: "orderId is required" });
    }

    // 1️⃣ Fetch the order & verify it belongs to the user
    const order = await prisma.order.findFirst({
        where: {
            orderId: Number(orderId),
            userId: Number(userId)
        }
    });

    if (!order) {
        return res.status(404).json({ status: 0, message: "Order not found" });
    }

    // 2️⃣ Allowed statuses for user to cancel
    const allowCancel = ["PENDING", "ACCEPTED"];

    if (!allowCancel.includes(order.status)) {
        return res.status(400).json({
            status: 0,
            message: "You cannot cancel this order at this stage"
        });
    }

    // 3️⃣ Update order status
    const updatedOrder = await prisma.order.update({
        where: { orderId: Number(orderId) },
        data: {
            status: "CANCELLED",
            cancelledAt: new Date(),
            cancelReason: reason || null
        }
    });

    return res.json({
        status: 1,
        message: "Order cancelled successfully",
        order: updatedOrder
    });
});


// exports.homePage = catchAsync(async (req, res) => {
//     const { userId } = req.user || {};
//     const { latitude, longitude } = req.query;
//     const BANNER_S3 = process.env.banners_s3 || "";
//     const CATEGORY_S3 = process.env.categories_s3 || "";

//     if (userId && (latitude || longitude)) {
//         await prisma.user.update({
//             where: { userId: Number(userId) },
//             data: {
//                 latitude: latitude ? Number(latitude) : undefined,
//                 longitude: longitude ? Number(longitude) : undefined,
//             },
//         }).catch(() => { });
//     }

//     const userLat = latitude ? Number(latitude) : null;
//     const userLng = longitude ? Number(longitude) : null;

//     // ⭐ Categories (append full image URL)
//     const rawCategories = await prisma.category.findMany({
//         where: { isActive: 1 },
//         select: { id: true, name: true, image: true }
//     });

//     const categories = rawCategories.map(c => ({
//         ...c,
//         image: c.image ? `${CATEGORY_S3}${c.image}` : null
//     }));

//     // ⭐ Banners (append full image URL)
//     const rawBanners = await prisma.banner.findMany({
//         where: { isActive: 1 },
//         select: { bannerId: true, banner: true },
//         orderBy: { createdAt: "desc" },
//     });

//     const banners = rawBanners.map(b => ({
//         ...b,
//         banner: b.banner ? `${BANNER_S3}${b.banner}` : null
//     }));


//     // (Remaining unchanged logic) -------------------------
//     let wishlistIdsSet = new Set();
//     if (userId) {
//         const wishlist = await prisma.wishlist.findMany({
//             where: { userId: Number(userId) },
//             select: { kitchenId: true },
//         });
//         wishlistIdsSet = new Set(wishlist.map((w) => w.kitchenId));
//     }

//     const TOP_K = 6;

//     const popularGroups = await prisma.order.groupBy({
//         by: ["kitchenId"],
//         _count: { kitchenId: true },
//         take: TOP_K,
//         orderBy: { _count: { kitchenId: "desc" } },
//     });

//     const popularKitchenIds = popularGroups.map((g) => g.kitchenId);

//     let popularKitchens = [];
//     if (popularKitchenIds.length) {
//         const kitchens = await prisma.kitchen.findMany({
//             where: { kitchenId: { in: popularKitchenIds }, isActive: 1 },
//             include: { photos: true, address: true },
//         });

//         const byId = new Map(kitchens.map((k) => [k.kitchenId, k]));

//         popularKitchens = await Promise.all(
//             popularKitchenIds
//                 .filter((id) => byId.has(id))
//                 .map((id) =>
//                     handleFactory.formatKitchen(
//                         byId.get(id),
//                         wishlistIdsSet,
//                         userLat,
//                         userLng
//                     )
//                 )
//         );
//     }

//     const storeProductsRaw = await prisma.menuItem.findMany({
//         where: { isActive: 1 },
//         orderBy: { createdAt: "desc" },
//         take: 4,
//         include: { categoryIds: true, cuisine: true },
//     });

//     const store99 = await Promise.all(
//         storeProductsRaw.map((item) => handleFactory.formatMenuItem(item))
//     );

//     const topRatedKitchensRaw = await prisma.kitchen.findMany({
//         where: { isActive: 1 },
//         orderBy: { rating: "desc" },
//         take: TOP_K,
//         include: { photos: true, address: true },
//     });

//     const topRatedKitchens = await Promise.all(
//         topRatedKitchensRaw.map((k) =>
//             handleFactory.formatKitchen(k, wishlistIdsSet, userLat, userLng)
//         )
//     );

//     res.json({
//         status: 1,
//         message: "Home page data fetched successfully",
//         banners,
//         categories,
//         popularKitchens,
//         store99,
//         topRatedKitchens,
//     });
// });

exports.rateOrderAndKitchen = catchAsync(async (req, res) => {
    const { orderId, orderRating, kitchenRating, kitchenReview } = req.body;
    const { userId } = req.user;
    console.log(orderId, orderRating, kitchenRating, kitchenReview, userId);
    // Basic validations
    if (!orderId || orderRating == null || kitchenRating == null) {
        return res.status(400).json({
            status: 0,
            message: "orderId, orderRating and kitchenRating are required"
        });
    }

    const orderRate = Number(orderRating);
    const kitchenRate = Number(kitchenRating);

    if (orderRate < 1 || orderRate > 5 || kitchenRate < 1 || kitchenRate > 5) {
        return res.status(400).json({
            status: 0,
            message: "Ratings must be between 1 and 5"
        });
    }

    // 1️⃣ Fetch order
    const order = await prisma.order.findUnique({
        where: { orderId: Number(orderId) },
        include: { items: true }
    });

    if (!order) {
        return res.status(404).json({ status: 0, message: "Order not found" });
    }

    if (order.userId !== userId) {
        return res.status(403).json({ status: 0, message: "Not your order" });
    }

    if (order.status !== "PICKED") {
        return res.status(400).json({
            status: 0,
            message: "Order must be PICKED before rating"
        });
    }
    console.log(order.rating);
    // 2️⃣ Prevent double order rating
    if (Number(order.rating) > 0) {
        return res.status(400).json({
            status: 0,
            message: "Order already rated"
        });
    }


    // 3️⃣ Prevent multiple kitchen reviews
    const existingReview = await prisma.kitchenReview.findUnique({
        where: { orderId: Number(orderId) }
    });

    if (existingReview) {
        return res.status(400).json({
            status: 0,
            message: "You already reviewed this kitchen for this order"
        });
    }

    // ⭐ 4️⃣ Update order rating
    const updatedOrder = await prisma.order.update({
        where: { orderId: Number(orderId) },
        data: { rating: orderRate }
    });

    // ⭐ 5️⃣ Update menu item ratings (average)
    await Promise.all(
        order.items.map(async (item) => {
            const menuItem = await prisma.menuItem.findUnique({
                where: { id: item.menuItemId },
                select: { rating: true, ratingCount: true }
            });

            const oldRating = Number(menuItem.rating);
            const oldCount = menuItem.ratingCount;

            const newCount = oldCount + 1;
            const newRating = ((oldRating * oldCount) + orderRate) / newCount;

            await prisma.menuItem.update({
                where: { id: item.menuItemId },
                data: {
                    rating: Number(newRating.toFixed(2)),
                    ratingCount: newCount
                }
            });
        })
    );

    // ⭐ 6️⃣ Create kitchen review
    const newReview = await prisma.kitchenReview.create({
        data: {
            orderId: Number(orderId),
            userId,
            kitchenId: order.kitchenId,
            rating: kitchenRate,
            review: kitchenReview || null
        }
    });

    // ⭐ 7️⃣ Update kitchen rating
    const kitchen = await prisma.kitchen.findUnique({
        where: { kitchenId: order.kitchenId },
        select: { rating: true, ratingCount: true }
    });

    const oldRating = Number(kitchen.rating);
    const oldCount = kitchen.ratingCount;

    const newCount = oldCount + 1;
    const newRating = ((oldRating * oldCount) + kitchenRate) / newCount;

    await prisma.kitchen.update({
        where: { kitchenId: order.kitchenId },
        data: {
            rating: Number(newRating.toFixed(2)),
            ratingCount: newCount
        }
    });

    return res.json({
        status: 1,
        message: "Order and kitchen rated successfully"
    });
});

exports.startUserSupportChat = catchAsync(async (req, res) => {
    const io = getIO(); // ✅ FIX
    const { userId } = req.user;
    const { message, image } = req.body;

    if (!message && !image) {
        return res.status(400).json({
            status: 0,
            message: "Message or image required"
        });
    }

    // 🔍 Find existing room (OPEN or CLOSED)
    let room = await prisma.chatRoom.findFirst({
        where: { userId }
    });

    // ➕ Create room if not exists, or reopen if closed
    if (!room) {
        room = await prisma.chatRoom.create({
            data: { userId, status: "OPEN" }
        });
    } else if (room.status === "CLOSED") {
        // 🔄 Reopen the closed chat room
        room = await prisma.chatRoom.update({
            where: { roomId: room.roomId },
            data: {
                status: "OPEN",
                updatedAt: new Date()
            }
        });
    }

    // 💾 Save message
    const savedMessage = await prisma.chatMessage.create({
        data: {
            roomId: room.roomId,
            senderRole: "USER",
            senderId: userId,
            message: message || null,
            image: image || null
        }
    });

    const response = {
        messageId: savedMessage.messageId,
        roomId: room.roomId,
        senderRole: "USER",
        message: savedMessage.message,
        image: savedMessage.image,
        createdAt: savedMessage.createdAt
    };

    // 📡 Send to ALL ADMINS
    io.to("admins").emit("support-message", response);

    return res.json({
        status: 1,
        message: "Support message sent",
        roomId: room.roomId,
        data: response
    });
});


// Get user support chat messages
exports.getUserSupportChatMessages = catchAsync(async (req, res) => {
    const { userId } = req.user;

    // Find user's chat room
    const room = await prisma.chatRoom.findFirst({
        where: { userId }
    });

    if (!room) {
        return res.json({
            status: 1,
            message: "No active chat found",
            roomId: null,
            messages: []
        });
    }

    // Fetch all messages from the room
    const messages = await prisma.chatMessage.findMany({
        where: { roomId: room.roomId },
        orderBy: { createdAt: "asc" }
    });

    return res.json({
        status: 1,
        message: "Chat messages fetched successfully",
        roomId: room.roomId,
        roomStatus: room.status,
        messages
    });
});


exports.getNotifications = catchAsync(async (req, res) => {
    // ⭐ Check if user is authenticated
    if (!req.user) {
        return res.status(200).json({
            status: 1,
            message: "No user logged in",
            count: 0,
            notifications: []
        });
    }

    const { userId, userRole = 'USER' } = req.user;
    const { isRead } = req.query;

    // 1️⃣ Fetch all notifications
    const notifications = await prisma.notification.findMany({
        where: {
            ownerId: Number(userId),
            ownerType: userRole
        },
        orderBy: { createdAt: "desc" }
    });

    // 2️⃣ Count unread notifications BEFORE marking as read
    const unreadCount = notifications.filter(n => !n.isRead).length;

    // 3️⃣ Mark unread notifications as read ONLY if isRead=true is passed
    if (isRead === 'true') {
        await prisma.notification.updateMany({
            where: {
                ownerId: Number(userId),
                ownerType: userRole,
                isRead: false
            },
            data: { isRead: true }
        });
    }

    return res.status(200).json({
        status: 1,
        message: "Notifications fetched successfully",
        count: unreadCount, // Only unread count
        notifications
    });
});

/**
 * User requests account deletion
 * Schedules deletion after 6 months. Login cancels this request.
 */
exports.deleteAccount = catchAsync(async (req, res) => {
    const { userId } = req.user;
    const { reasonText } = req.body;

    // Check if there's already a pending deletion
    const existingRequest = await prisma.userAccountRequest.findFirst({
        where: {
            userId: Number(userId),
            requestType: "DELETE",
            status: "PENDING"
        }
    });

    if (existingRequest) {
        return res.status(400).json({
            status: 0,
            message: "Account deletion request already pending"
        });
    }

    // Create the deletion request and update user status
    const deletionDate = new Date();
    deletionDate.setMonth(deletionDate.getMonth() + 6);

    await prisma.$transaction([
        prisma.userAccountRequest.create({
            data: {
                userId: Number(userId),
                requestType: "DELETE",
                reasonText: reasonText || "User initiated deletion",
                requestedAt: new Date(),
                scheduledDeletionAt: deletionDate,
                status: "PENDING"
            }
        }),
        prisma.user.update({

            where: { userId: Number(userId) },
            data: { status: "DELETING_SOON", isActive: 0 }
        })
    ]);

    // Send Day 0 confirmation email (non-fatal)
    try {
        const user = await prisma.user.findUnique({
            where: { userId: Number(userId) },
            select: { name: true, lastName: true, email: true }
        });
        if (user?.email) {
            const { sendUserDeletionRequestEmail } = require("../utils/emailService");
            const userName = [user.name, user.lastName].filter(Boolean).join(" ") || "User";
            await sendUserDeletionRequestEmail(user.email, userName);
            console.log(`📧 [DELETE] Deletion confirmation email sent to ${user.email}`);
        }
    } catch (emailErr) {
        console.error("⚠️ [DELETE] Failed to send deletion email (non-fatal):", emailErr.message);
    }

    return res.status(200).json({
        status: 1,
        message: "Account deletion requested. Your account will be deleted in 6 months. Logging in again will cancel this request.",
        scheduledDeletionAt: deletionDate
    });
});



// auth creation 

const { admin, authApp } = require("./firebaseAuth");

exports.googleLogin = catchAsync(async (req, res) => {
    const { idToken, deviceToken } = req.body;
    console.log(idToken, deviceToken)
    if (!idToken) {
        return res.status(400).json({
            status: 0,
            message: "Firebase token required",
        });
    }

    const decodedToken = await authApp
        .auth()
        .verifyIdToken(idToken);

    const {
        email,
        name,
        picture,
        firebase: { sign_in_provider },
    } = decodedToken;

    if (sign_in_provider !== "google.com") {
        return res.status(400).json({
            status: 0,
            message: "Invalid provider",
        });
    }

    // 3️⃣ Check user in DB
    let user = await prisma.user.findUnique({
        where: { email },
    });

    let isNewUser = 0;

    // 4️⃣ Create user if not exists
    if (!user) {
        // Split name into firstName and lastName
        const nameParts = name ? name.split(' ') : [];
        const firstName = nameParts[0] || null;
        const lastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : null;

        // Ensure we save a full URL for social login if available
        let profilePicUrl = picture || null;
        if (profilePicUrl && !profilePicUrl.startsWith('http')) {
            // If Google provides just an ID (e.g. ACg8oc...), prepend the base URL
            profilePicUrl = `https://lh3.googleusercontent.com/a/${profilePicUrl}`;
        }

        user = await prisma.user.create({
            data: {
                email,
                name: firstName,
                lastName: lastName,
                phoneNumber: null,
                profilePicture: profilePicUrl,
                deviceToken: deviceToken || null,
                authProvider: "GOOGLE",
            },
        });
        isNewUser = 1;

        // Send welcome email (only in production)
        if (process.env.NODE_ENV === 'production') {
            const { sendUserWelcomeEmail } = require('../utils/emailService');
            const userName = name || 'User';
            const emailResult = await sendUserWelcomeEmail(email, userName);

            if (emailResult.success) {
                console.log(`✅ Welcome email sent to ${email} (Google Login)`);
            } else {
                console.error(`❌ Failed to send welcome email to ${email}:`, emailResult.error);
            }
        }
    } else if (deviceToken) {
        await prisma.user.update({
            where: { userId: user.userId },
            data: { deviceToken },
        });
    }

    // ⭐ Handle Pending Account Requests (e.g., self-deletion appeal)
    const pendingDeleteRequest = await prisma.userAccountRequest.findFirst({
        where: {
            userId: user.userId,
            requestType: "DELETE",
            status: "PENDING"
        }
    });

    if (pendingDeleteRequest) {
        await prisma.userAccountRequest.update({
            where: { id: pendingDeleteRequest.id },
            data: { status: "CANCELLED" }
        });

        await prisma.user.update({
            where: { userId: user.userId },
            data: { status: "ACTIVE", isActive: 1 }
        });
        console.log(`✅ [GOOGLE LOGIN] Self-deletion request cancelled for user ${user.userId}`);
    }

    // Check if user is INACTIVE (Admin block)
    if (user.status === "INACTIVE" && !pendingDeleteRequest) {
        return res.status(200).json({
            status: 2,
            message: "Your account is inactive. Please contact support."
        });
    }

    // 5️⃣ Generate YOUR app JWT
    const token = jwt.sign(
        { userId: user.userId },
        process.env.JWT_SECRET_KEY,
        { expiresIn: "10d" }
    );

    return res.status(200).json({
        status: 1,
        message: "Login successful",
        isNewUser,
        token,
    });
});

exports.appleLogin = catchAsync(async (req, res) => {
    const { idToken, deviceToken } = req.body;
    console.log(idToken, deviceToken)
    if (!idToken) {
        return res.status(400).json({
            status: 0,
            message: "Firebase ID token required",
        });
    }

    // 🔐 Verify Firebase token
    const decodedToken = await authApp
        .auth()
        .verifyIdToken(idToken);

    const {
        email,
        name,
        picture,
        firebase: { sign_in_provider },
    } = decodedToken;

    // 🍎 Ensure Apple provider
    if (sign_in_provider !== "apple.com") {
        return res.status(400).json({
            status: 0,
            message: "Invalid Apple login",
        });
    }

    // ⚠️ Apple may not always give name/picture
    let user = await prisma.user.findUnique({
        where: { email },
    });

    let isNewUser = 0;

    if (!user) {
        // Split name into firstName and lastName
        const fullName = name || "Apple User";
        const nameParts = fullName.split(' ');
        const firstName = nameParts[0] || null;
        const lastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : null;

        // For Apple, ensure we only save full URLs to avoid broken fragments
        const profilePicUrl = (picture && picture.startsWith('http')) ? picture : null;

        user = await prisma.user.create({
            data: {
                email,
                name: firstName,
                lastName: lastName,
                phoneNumber: null,
                profilePicture: profilePicUrl,
                deviceToken: deviceToken || null,
                authProvider: "APPLE",
            },
        });
        isNewUser = 1;

        // Send welcome email (only in production)
        if (process.env.NODE_ENV === 'production') {
            const { sendUserWelcomeEmail } = require('../utils/emailService');
            const userName = name || 'Apple User';
            const emailResult = await sendUserWelcomeEmail(email, userName);

            if (emailResult.success) {
                console.log(`✅ Welcome email sent to ${email} (Apple Login)`);
            } else {
                console.error(`❌ Failed to send welcome email to ${email}:`, emailResult.error);
            }
        }
    } else if (deviceToken) {
        await prisma.user.update({
            where: { userId: user.userId },
            data: { deviceToken },
        });
    }

    // ⭐ Handle Pending Account Requests (e.g., self-deletion appeal)
    const pendingDeleteRequest = await prisma.userAccountRequest.findFirst({
        where: {
            userId: user.userId,
            requestType: "DELETE",
            status: "PENDING"
        }
    });

    if (pendingDeleteRequest) {
        await prisma.userAccountRequest.update({
            where: { id: pendingDeleteRequest.id },
            data: { status: "CANCELLED" }
        });

        await prisma.user.update({
            where: { userId: user.userId },
            data: { status: "ACTIVE", isActive: 1 }
        });
        console.log(`✅ [APPLE LOGIN] Self-deletion request cancelled for user ${user.userId}`);
    }

    // Check if user is INACTIVE (Admin block)
    if (user.status === "INACTIVE" && !pendingDeleteRequest) {
        return res.status(200).json({
            status: 2,
            message: "Your account is inactive. Please contact support."
        });
    }

    // Generate YOUR app JWT
    const token = jwt.sign(
        { userId: user.userId },
        process.env.JWT_SECRET_KEY,
        { expiresIn: "10d" }
    );

    return res.status(200).json({
        status: 1,
        message: "Login successful",
        isNewUser,
        token,
    });
});

exports.facebookLogin = catchAsync(async (req, res) => {
    const { idToken, deviceToken } = req.body;
    console.log(idToken, deviceToken)
    if (!idToken) {
        return res.status(400).json({
            status: 0,
            message: "Firebase token required",
        });
    }

    // 🔐 Verify Firebase token
    const decodedToken = await authApp.auth().verifyIdToken(idToken);

    const {
        email,
        name,
        picture,
        firebase: { sign_in_provider },
    } = decodedToken;

    // Ensure Facebook login
    if (sign_in_provider !== "facebook.com") {
        return res.status(400).json({
            status: 0,
            message: "Invalid Facebook login",
        });
    }

    if (!email) {
        return res.status(400).json({
            status: 0,
            message: "Facebook account has no email",
        });
    }

    let user = await prisma.user.findUnique({ where: { email } });
    let isNewUser = 0;

    if (!user) {
        // Split name into firstName and lastName
        const nameParts = name ? name.split(' ') : [];
        const firstName = nameParts[0] || null;
        const lastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : null;

        // For Facebook, ensure we only save full URLs
        const profilePicUrl = (picture && picture.startsWith('http')) ? picture : null;

        user = await prisma.user.create({
            data: {
                email,
                name: firstName,
                lastName: lastName,
                phoneNumber: null,
                profilePicture: profilePicUrl,
                deviceToken,
                authProvider: "FACEBOOK",
            },
        });
        isNewUser = 1;

        // Send welcome email (only in production)
        if (process.env.NODE_ENV === 'production') {
            const { sendUserWelcomeEmail } = require('../utils/emailService');
            const userName = name || 'User';
            const emailResult = await sendUserWelcomeEmail(email, userName);

            if (emailResult.success) {
                console.log(`✅ Welcome email sent to ${email} (Facebook Login)`);
            } else {
                console.error(`❌ Failed to send welcome email to ${email}:`, emailResult.error);
            }
        }
    }

    // ⭐ Handle Pending Account Requests (e.g., self-deletion appeal)
    const pendingDeleteRequest = await prisma.userAccountRequest.findFirst({
        where: {
            userId: user.userId,
            requestType: "DELETE",
            status: "PENDING"
        }
    });

    if (pendingDeleteRequest) {
        await prisma.userAccountRequest.update({
            where: { id: pendingDeleteRequest.id },
            data: { status: "CANCELLED" }
        });

        await prisma.user.update({
            where: { userId: user.userId },
            data: { status: "ACTIVE", isActive: 1 }
        });
        console.log(`✅ [FACEBOOK LOGIN] Self-deletion request cancelled for user ${user.userId}`);
    }

    // Check if user is INACTIVE (Admin block)
    if (user.status === "INACTIVE" && !pendingDeleteRequest) {
        return res.status(200).json({
            status: 2,
            message: "Your account is inactive. Please contact support."
        });
    }

    const token = jwt.sign(
        { userId: user.userId },
        process.env.JWT_SECRET_KEY,
        { expiresIn: "10d" }
    );

    return res.status(200).json({
        status: 1,
        message: "Login successful",
        isNewUser,
        token,
    });
});

// ========================================
// 💳 SAVED CARDS MANAGEMENT (SetupIntent Flow)
// ========================================

const {
    createSetupIntent,
    savePaymentMethodFromSetupIntent,
    getSavedCards,
    deleteSavedCard,
    setDefaultCard
} = require('../utils/stripePaymentMethods');

/**
 * Create SetupIntent for adding a new card (Step 1)
 * This generates a client secret for the frontend to collect card details
 * POST /user/createSetupIntent
 */
exports.createSetupIntent = catchAsync(async (req, res) => {
    const { userId } = req.user;

    try {
        const setupIntent = await createSetupIntent(userId);

        return res.status(200).json({
            status: 1,
            message: "Setup intent created successfully",
            data: {
                clientSecret: setupIntent.clientSecret,
                setupIntentId: setupIntent.setupIntentId
            }
        });
    } catch (error) {
        console.error('Error creating setup intent:', error);
        return res.status(500).json({
            status: 0,
            message: error.message || "Failed to create setup intent"
        });
    }
});

/**
 * Save card after SetupIntent confirmation (Step 2)
 * Called after frontend confirms the SetupIntent with card details
 * POST /user/confirmSavedCard
 * Body: { paymentMethodId, setAsDefault }
 */
exports.confirmSavedCard = catchAsync(async (req, res) => {
    const { userId } = req.user;
    const { paymentMethodId, setAsDefault = false } = req.body;

    if (!paymentMethodId) {
        return res.status(400).json({
            status: 0,
            message: "paymentMethodId is required"
        });
    }

    try {
        const savedCard = await savePaymentMethodFromSetupIntent(
            userId,
            paymentMethodId,
            setAsDefault
        );

        return res.status(200).json({
            status: 1,
            message: "Card saved successfully",
            data: {
                cardId: savedCard.cardId,
                cardBrand: savedCard.cardBrand,
                cardLast4: savedCard.cardLast4,
                cardExpMonth: savedCard.cardExpMonth,
                cardExpYear: savedCard.cardExpYear,
                isDefault: savedCard.isDefault
            }
        });
    } catch (error) {
        console.error('Error confirming saved card:', error);
        return res.status(400).json({
            status: 0,
            message: error.message || "Failed to save card"
        });
    }
});

/**
 * Get all saved cards for the user
 * GET /user/getSavedCards
 * Query params: ?source=database|stripe (default: database)
 */
exports.getSavedCards = catchAsync(async (req, res) => {
    const { userId } = req.user;
    const { source = 'database' } = req.query;

    try {
        const fromDatabase = source === 'database';
        const cards = await getSavedCards(userId, fromDatabase);

        // Format response to hide sensitive data
        const formattedCards = cards.map(card => ({
            cardId: card.cardId || null,
            paymentMethodId: card.paymentMethodId || card.stripePaymentMethodId,
            cardBrand: card.cardBrand,
            cardLast4: card.cardLast4,
            cardExpMonth: card.cardExpMonth,
            cardExpYear: card.cardExpYear,
            cardHolderName: card.cardHolderName,
            isDefault: card.isDefault,
            createdAt: card.createdAt || null
        }));

        return res.status(200).json({
            status: 1,
            message: "Saved cards fetched successfully",
            data: formattedCards
        });
    } catch (error) {
        console.error('Error fetching saved cards:', error);
        return res.status(500).json({
            status: 0,
            message: "Failed to fetch saved cards"
        });
    }
});

/**
 * Delete a saved card
 * DELETE /user/deleteCard/:cardId
 */
exports.deleteCard = catchAsync(async (req, res) => {
    const { userId } = req.user;
    const { cardId } = req.params;

    if (!cardId) {
        return res.status(400).json({
            status: 0,
            message: "cardId is required"
        });
    }

    try {
        await deleteSavedCard(userId, cardId);

        return res.status(200).json({
            status: 1,
            message: "Card deleted successfully"
        });
    } catch (error) {
        console.error('Error deleting card:', error);
        return res.status(400).json({
            status: 0,
            message: error.message || "Failed to delete card"
        });
    }
});

/**
 * Set a card as default
 * PUT /user/setDefaultCard/:cardId
 */
exports.setDefaultCard = catchAsync(async (req, res) => {
    const { userId } = req.user;
    const { cardId } = req.params;

    if (!cardId) {
        return res.status(400).json({
            status: 0,
            message: "cardId is required"
        });
    }

    try {
        const updatedCard = await setDefaultCard(userId, cardId);

        return res.status(200).json({
            status: 1,
            message: "Default card updated successfully",
            data: {
                cardId: updatedCard.cardId,
                cardBrand: updatedCard.cardBrand,
                cardLast4: updatedCard.cardLast4,
                isDefault: updatedCard.isDefault
            }
        });
    } catch (error) {
        console.error('Error setting default card:', error);
        return res.status(400).json({
            status: 0,
            message: error.message || "Failed to set default card"
        });
    }
});
