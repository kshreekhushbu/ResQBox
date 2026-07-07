const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const catchAsync = require("../utils/catchAsync");
const prisma = require("../utils/prisma");
const Razorpay = require("razorpay");
const crypto = require("crypto");
const handleFactory = require("./handleFactory");
const { getIO } = require("../utils/socket");
const Stripe = require("stripe");
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY_VENDORS);
const auditLogger = require('../utils/auditLogger');

/**
 * Parse expireDate that may arrive as DD-MM-YYYY (from app) or ISO/YYYY-MM-DD.
 * Returns a valid Date, or null if the input is falsy/unparseable.
 */
function parseExpireDate(value) {
    if (!value) return null;
    const str = String(value).trim();
    // DD-MM-YYYY  →  YYYY-MM-DD
    const ddmmyyyy = str.match(/^(\d{2})-(\d{2})-(\d{4})$/);
    if (ddmmyyyy) {
        const [, dd, mm, yyyy] = ddmmyyyy;
        const d = new Date(`${yyyy}-${mm}-${dd}T00:00:00.000Z`);
        return isNaN(d.getTime()) ? null : d;
    }
    // Fallback: ISO / YYYY-MM-DD / other JS-parseable formats
    const d = new Date(str);
    return isNaN(d.getTime()) ? null : d;
}


// const { emitToUser, userSockets } = require("../utils/sockets");

// exports.loginKitchen = catchAsync(async (req, res) => {
//     const { email, password } = req.body;

//     if (!email || !password) {
//         return res.status(400).json({ status: 0, message: "Email and password are required" });
//     }

//     // 📌 Find kitchen by email
//     const kitchen = await prisma.kitchen.findFirst({
//         where: { email }
//     });

//     if (!kitchen) {
//         return res.status(400).json({ status: 0, message: "Kitchen not found" });
//     }

//     // 📌 Validate password
//     const isMatch = await bcrypt.compare(password, kitchen.password);
//     if (!isMatch) {
//         return res.status(400).json({ status: 0, message: "Invalid password" });
//     }

//     // 📌 Check KYC & expiry (optional)
//     const kitchenKyc = await prisma.kitchenKyc.findFirst({
//         where: { kitchenId: kitchen.kitchenId }
//     });

//     if (kitchenKyc?.expireDate && new Date(kitchenKyc.expireDate) <= new Date()) {
//         return res.status(403).json({
//             status: 0,
//             message: "KYC Expired. Please upload a valid certificate."
//         });
//     }

//     // 📌 Generate token
//     const token = jwt.sign(
//         { id: kitchen.kitchenId, role: "KITCHEN" },
//         process.env.JWT_SECRET_KEY,
//         { expiresIn: "10d" }
//     );

//     return res.status(200).json({
//         status: 1,
//         message: "Login successful",
//         token
//     });
// });

exports.loginKitchen = catchAsync(async (req, res) => {
    const { email, password, deviceToken } = req.body;

    if (!email || !password) {
        return res.status(400).json({ status: 0, message: "Email and password are required" });
    }

    // ⭐ 1️⃣ Try logging in as Kitchen Owner
    const kitchen = await prisma.kitchen.findFirst({ where: { email } });

    if (kitchen) {
        const isMatch = await bcrypt.compare(password, kitchen.password);
        if (!isMatch) {
            return res.status(400).json({ status: 0, message: "Invalid password" });
        }

        const kyc = await prisma.kitchenKyc.findFirst({
            where: { kitchenId: kitchen.kitchenId }
        });

        if (kyc?.expireDate && new Date(kyc.expireDate) <= new Date()) {
            // Update kitchen as REJECTED due to expired certificate
            await prisma.kitchen.update({
                where: { kitchenId: kitchen.kitchenId },
                data: {
                    status: "REJECTED",
                    rejectReason: "Your uploaded Food Certificate has expired. Kindly reapply to continue to ResQ your from getting waste."
                }
            });
            // return res.status(403).json({
            //     status: 0,
            //     message: "Your KYC certificate has expired. Please upload a valid certificate."
            // });
        }

        // ⭐ Token remains SAME
        const token = jwt.sign(
            { id: kitchen.kitchenId, role: "KITCHEN" },
            process.env.JWT_SECRET_KEY,
            { expiresIn: "10d" }
        );

        // Update device token if provided
        if (deviceToken) {
            const currentTokens = Array.isArray(kitchen.deviceTokens) ? kitchen.deviceTokens : [];
            const updatedTokens = currentTokens.includes(deviceToken)
                ? currentTokens
                : [...currentTokens, deviceToken];

            await prisma.kitchen.update({
                where: { kitchenId: kitchen.kitchenId },
                data: {
                    deviceToken,
                    deviceTokens: updatedTokens
                }
            });
        }

        return res.status(200).json({
            status: 1,
            message: "Login successful",
            isTeamMember: false,     // ⭐ Important flag
            token
        });
    }

    // ⭐ 2️⃣ Try logging in as Team Member
    const member = await prisma.teamMember.findFirst({
        where: { email, isActive: 1 }
    });

    if (!member) {
        return res.status(400).json({
            status: 0,
            // message: "Account not found"
            message: "Account not registered. Please register your Restaurant"

        });
    }

    const isMatch = await bcrypt.compare(password, member.password);
    if (!isMatch) {
        return res.status(400).json({ status: 0, message: "Incorrect password" });
    }

    // ⭐ Token remains SAME for team member (kitchenId only)
    const token = jwt.sign(
        { id: member.kitchenId, role: "KITCHEN" },
        process.env.JWT_SECRET_KEY,
        { expiresIn: "10d" }
    );

    // Update device token for kitchen if provided by team member
    if (deviceToken) {
        const kitchen = await prisma.kitchen.findUnique({
            where: { kitchenId: member.kitchenId },
            select: { deviceTokens: true }
        });

        const currentTokens = Array.isArray(kitchen?.deviceTokens) ? kitchen.deviceTokens : [];
        const updatedTokens = currentTokens.includes(deviceToken)
            ? currentTokens
            : [...currentTokens, deviceToken];

        await prisma.kitchen.update({
            where: { kitchenId: member.kitchenId },
            data: {
                deviceToken,
                deviceTokens: updatedTokens
            }
        });
    }

    return res.status(200).json({
        status: 1,
        message: "Login successful",
        isTeamMember: true,   // ⭐ Frontend identifies role
        teamMemberId: member.id,
        token
    });
});

exports.checkEmailExists = catchAsync(async (req, res) => {
    const { email } = req.body;

    // 🚨 Check if email exists in Kitchen table
    const kitchenExists = await prisma.kitchen.findFirst({
        where: { email: email }
    });

    // 🚨 Check if email exists in TeamMember table
    const teamExists = await prisma.teamMember.findFirst({
        where: { email: email }
    });

    if (kitchenExists || teamExists) {
        return res.status(400).json({
            status: 0,
            message: "Email already exists. Please use a different email."
        });
    } else {
        return res.status(200).json({
            status: 1,
            message: "Email not exists."
        });
    }

});

exports.getAbnDetails = catchAsync(async (req, res) => {
    const { abn } = req.query;

    if (!abn) {
        return res.status(400).json({
            status: 0,
            message: "ABN is required"
        });
    }

    const guid = process.env.ABN_GUID;

    if (!guid) {
        return res.status(400).json({
            status: 0,
            message: "ABN API GUID is not configured in environment variables."
        });
    }

    try {
        const url = `https://abr.business.gov.au/json/AbnDetails.aspx?abn=${abn}&guid=${guid}`;
        const response = await fetch(url);

        if (!response.ok) {
            return res.status(response.status).json({
                status: 0,
                message: `ABN API responded with status: ${response.status}`
            });
        }

        const data = await response.text();

        // The ABR JSON API sometimes returns a callback-wrapped string.
        // We attempt to parse it as JSON, stripping callback() if present.
        let jsonData;
        try {
            const cleanedData = data.replace(/^callback\(|\);?$/g, "").trim();
            jsonData = JSON.parse(cleanedData);
        } catch (e) {
            return res.status(200).json({
                status: 1,
                data: data,
                message: "ABN details retrieved as raw text"
            });
        }

        // Logic to determine timezone from State/Postcode
        let timezoneName = null;
        const state = jsonData.AddressState?.toUpperCase();
        const postcode = jsonData.AddressPostcode;

        if (state === "NSW") {
            timezoneName = (postcode === "2880") ? "Australia/Broken_Hill" : "Australia/Sydney";
        } else if (state === "VIC") {
            timezoneName = "Australia/Melbourne";
        } else if (state === "QLD") {
            timezoneName = "Australia/Brisbane";
        } else if (state === "WA") {
            timezoneName = "Australia/Perth";
        } else if (state === "SA") {
            timezoneName = "Australia/Adelaide";
        } else if (state === "TAS") {
            timezoneName = "Australia/Hobart";
        } else if (state === "ACT") {
            timezoneName = "Australia/Canberra";
        } else if (state === "NT") {
            timezoneName = "Australia/Darwin";
        }

        // Fetch timezone from database based on name
        let dbTimezone = null;
        if (timezoneName) {
            dbTimezone = await prisma.timezone.findFirst({
                where: { name: timezoneName, isActive: 1 },
                select: { id: true, name: true, displayName: true }
            });
        }

        return res.status(200).json({
            status: 1,
            data: jsonData,
            timezone: dbTimezone
        });
    } catch (error) {
        console.error("ABN Lookup Error:", error);
        return res.status(500).json({
            status: 0,
            message: "Failed to fetch ABN details",
            error: error.message
        });
    }
});

exports.registerKitchen = catchAsync(async (req, res) => {
    const { kitchenDetails, address, photos, kyc } = req.body;

    // check email is already exist in kitchen or team 

    if (!kitchenDetails)
        return res.status(400).json({ status: 0, message: "Kitchen details required" });

    // 🚨 Check if email exists in Kitchen table
    const kitchenExists = await prisma.kitchen.findFirst({
        where: { email: kitchenDetails.email }
    });

    // 🚨 Check if email exists in TeamMember table
    const teamExists = await prisma.teamMember.findFirst({
        where: { email: kitchenDetails.email }
    });

    if (kitchenExists || teamExists) {
        return res.status(400).json({
            status: 0,
            message: "Email already exists. Please use a different email."
        });
    }

    const hashedPassword = await bcrypt.hash(kitchenDetails.password, 10);
    return await prisma.$transaction(async (tx) => {

        // 📌 1. Create Kitchen
        const kitchen = await tx.kitchen.create({
            data: {
                kitchenName: kitchenDetails.kitchenName,
                email: kitchenDetails.email,
                ownerName: kitchenDetails.ownerName,
                contactNumber: kitchenDetails.contactNumber,
                openingTime: kitchenDetails.openingTime,
                closingTime: kitchenDetails.closingTime,
                description: kitchenDetails.description,
                deviceToken: kitchenDetails.deviceToken || null,
                deviceTokens: kitchenDetails.deviceToken ? [kitchenDetails.deviceToken] : [],
                password: hashedPassword,
                isActive: 0,
                timezoneId: kitchenDetails.timezoneId || 1,
                foodtypes: {
                    connect: kitchenDetails.foodtypes?.map(id => ({ id })) || []
                },
                // 👇 Connect cuisines (many-to-many)
                cuisines: {
                    connect: kitchenDetails.cuisineIds?.map(id => ({ id })) || []
                }

            }
        });

        const kitchenId = kitchen.kitchenId;

        // 📌 2. Save Address
        if (address) {
            await tx.kitchenAddress.create({
                data: { ...address, kitchenId }
            });
        }

        // 📌 3. Save Photos
        if (photos) {
            await tx.kitchenPhotos.create({
                data: {
                    kitchenId,
                    kitchenImages: photos.kitchenImages || [],   // ✅ fix JSON safety
                    kitchenProfilePhoto: photos.kitchenProfilePhoto,
                }
            });
        }

        const currentDate = new Date();

        if (kitchen.kyc?.expireDate && new Date(kitchen.kyc.expireDate) <= currentDate) {
            return res.status(403).json({
                status: 0,
                message: "KYC Expired. Please update your certificate."
            });
        }


        // if (kyc) {
        //     await tx.kitchenKyc.create({
        //         data: {
        //             ...kyc,
        //             foodCertificateImages: photos.foodCertificateImage || [],
        //             expireDate: kyc.expireDate ? new Date(kyc.expireDate) : null,
        //             kitchenId
        //         }
        //     });
        // }
        // 📌 5. Generate token

        if (kyc) {
            const certificates = [];

            // ✅ Add first certificate during signup
            if (kyc.foodCertificateImage && kyc.expireDate) {
                certificates.push({
                    image: kyc.foodCertificateImage,
                    expireDate: parseExpireDate(kyc.expireDate)?.toISOString() ?? null,
                    addedAt: new Date().toISOString()
                });
            }

            await tx.kitchenKyc.create({
                data: {
                    kitchenId,
                    abnNumber: kyc.abnNumber || null,
                    acn: kyc.acn || null,
                    foodCertificateNumber: kyc.foodCertificateNumber || null,
                    foodCertificateImage: kyc.foodCertificateImage,
                    foodCertificateImages: certificates, // ✅ ARRAY
                    expireDate: parseExpireDate(kyc.expireDate),
                    fssaiNumber: kyc.fssaiNumber || null
                }
            });
        }

        const token = jwt.sign(
            { id: kitchen.kitchenId, role: "KITCHEN" },
            process.env.JWT_SECRET_KEY,
            { expiresIn: "10d" }
        );

        // 🔍 CREATE AUDIT LOG - Registration
        await auditLogger.createAuditLog({
            kitchenId: kitchen.kitchenId,
            actorType: 'RESTAURANT',
            actorId: kitchen.kitchenId,
            actorName: kitchenDetails.ownerName,
            actionType: 'RESTAURANT_REGISTERED',
            actionDescription: 'Restaurant registered in the system',
            newData: 'PENDING',
            metadata: {
                kitchenName: kitchenDetails.kitchenName,
                email: kitchenDetails.email,
                ownerName: kitchenDetails.ownerName,
                hasKyc: !!kyc,
                hasAddress: !!address,
                hasPhotos: !!photos
            },
            ipAddress: auditLogger.getIpAddress(req),
            userAgent: auditLogger.getUserAgent(req)
        });

        return res.json({
            status: 1,
            message: "Kitchen registration successful",
            kitchenId,
            token
        });
    });
});

exports.resetOldPassword = catchAsync(async (req, res) => {
    const { email } = req.kitchen;
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
        return res.status(400).json({
            status: 0,
            message: "Old password and new password are required"
        });
    }

    // Fetch kitchen user
    const kitchen = await prisma.kitchen.findFirst({
        where: {
            email: email,
            status: "APPROVED"  // Use enum value instead of integer
        }
    });

    if (!kitchen) {
        return res.status(404).json({
            status: 0,
            message: "Email not found"
        });
    }

    // Verify old password
    const isPasswordValid = await bcrypt.compare(oldPassword, kitchen.password);

    if (!isPasswordValid) {
        return res.status(400).json({
            status: 0,
            message: "Old password is incorrect"
        });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password
    await prisma.kitchen.update({
        where: { kitchenId: kitchen.kitchenId },
        data: {
            password: hashedPassword,
            otp: null, // Clear OTP
            otpStatus: 0 // Reset OTP status
        }
    });

    return res.status(200).json({
        status: 1,
        message: "Password reset successfully"
    });
});

exports.addFoodCertificate = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen; // from token
    const { foodCertificateImage, expireDate } = req.body;

    if (!foodCertificateImage || !expireDate) {
        return res.status(400).json({
            status: 0,
            message: "foodCertificateImage and expireDate are required"
        });
    }

    // 🔍 Get existing KYC and kitchen details
    const [kyc, kitchen] = await Promise.all([
        prisma.kitchenKyc.findUnique({
            where: { kitchenId }
        }),
        prisma.kitchen.findUnique({
            where: { kitchenId },
            select: { kitchenName: true, ownerName: true }
        })
    ]);

    if (!kyc) {
        return res.status(404).json({
            status: 0,
            message: "KYC record not found"
        });
    }

    // 🧾 Existing certificates (safe fallback)
    const existingImages = Array.isArray(kyc.foodCertificateImages)
        ? kyc.foodCertificateImages
        : [];

    // 🆕 New certificate entry
    const newCertificate = {
        image: foodCertificateImage,
        expireDate: parseExpireDate(expireDate)?.toISOString() ?? null,
        addedAt: new Date().toISOString()
    };

    // ➕ Append (DO NOT overwrite)
    const updatedCertificates = [...existingImages, newCertificate];

    // 💾 Save back
    await prisma.kitchenKyc.update({
        where: { kitchenId },
        data: {
            foodCertificateImage,
            expireDate: parseExpireDate(expireDate),
            foodCertificateImages: updatedCertificates
        }
    });

    // 🔍 CREATE AUDIT LOG
    const imageUrl = `${process.env.kyc_s3}${foodCertificateImage}`;

    // Get the last certificate (if exists)
    const lastCertificate = existingImages.length > 0
        ? existingImages[existingImages.length - 1]
        : null;

    const lastCertificateUrl = lastCertificate
        ? `${process.env.kyc_s3}${lastCertificate.image}`
        : null;

    await auditLogger.createAuditLog({
        kitchenId,
        actorType: 'RESTAURANT',
        actorId: kitchenId,
        actorName: kitchen?.ownerName || 'Restaurant Owner',
        actionType: 'FOOD_CERTIFICATE_ADDED',
        actionDescription: `New food certificate added (expires: ${new Date(expireDate).toLocaleDateString()})`,
        oldData: {
            certificateImage: lastCertificateUrl,
            expireDate: lastCertificate?.expireDate || null
        },
        newData: {
            certificateImage: imageUrl,
            expireDate: parseExpireDate(expireDate)?.toISOString() ?? null
        },
        metadata: {
            certificateEndpoint: foodCertificateImage,
            certificateUrl: imageUrl,
            expireDate: parseExpireDate(expireDate)?.toISOString() ?? null,
            addedAt: newCertificate.addedAt,
            totalCertificates: updatedCertificates.length,
            previousCertificateCount: existingImages.length
        },
        ipAddress: auditLogger.getIpAddress(req),
        userAgent: auditLogger.getUserAgent(req)
    });

    // 🔔 Create admin alert
    try {
        await prisma.adminAlert.create({
            data: {
                kitchenId,
                alertType: "FOOD_CERTIFICATE",
                title: "New Food Certificate Added",
                message: `${kitchen?.kitchenName || 'A kitchen'} has uploaded a new food certificate for review`,
                metadata: {
                    certificateImage: foodCertificateImage,
                    expireDate: parseExpireDate(expireDate)?.toISOString() ?? null,
                    addedAt: new Date().toISOString()
                }
            }
        });

        console.log(`✅ [ALERT] Admin alert created for food certificate from kitchen ${kitchenId}`);
    } catch (alertError) {
        console.error("⚠️ [ALERT] Failed to create admin alert:", alertError);
        // Don't fail the request if alert creation fails
    }

    return res.status(200).json({
        status: 1,
        message: "Food certificate added successfully",
        certificate: newCertificate
    });
});

exports.getFoodCertificates = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen; // from token
    const kyc = await prisma.kitchenKyc.findUnique({
        where: { kitchenId }
    });
    if (!kyc) {
        return res.status(404).json({
            status: 0,
            message: "KYC record not found"
        });
    }

    const KYC_IMG = process.env.kyc_s3;

    // Get certificates and sort by addedAt (latest first)
    const certificates = Array.isArray(kyc.foodCertificateImages)
        ? kyc.foodCertificateImages
            .map(cert => ({
                image: cert.image ? `${KYC_IMG}${cert.image}` : null,
                expireDate: cert.expireDate || null,
                addedAt: cert.addedAt || null
            }))
            .sort((a, b) => {
                // Sort by addedAt descending (latest first)
                if (!a.addedAt) return 1;
                if (!b.addedAt) return -1;
                return new Date(b.addedAt) - new Date(a.addedAt);
            })
        : [];

    return res.status(200).json({
        status: 1,
        message: "Food certificates retrieved successfully",
        foodCertificateImages: certificates
    });
});

exports.reapplyKitchen = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen; // from JWT
    const { kitchenDetails, address, photos, kyc } = req.body;

    console.log("Reapply kitchen details:", {
        kitchenId,
        kitchenDetails,
        address,
        photos,
        kyc
    });
    // 🔍 1. Check kitchen exists
    const kitchen = await prisma.kitchen.findUnique({
        where: { kitchenId }
    });

    if (!kitchen) {
        return res.status(404).json({
            status: 0,
            message: "Kitchen not found"
        });
    }

    // ❌ Only REJECTED kitchens can reapply
    if (kitchen.status !== "REJECTED") {
        return res.status(400).json({
            status: 0,
            message: `Cannot reapply. Current status: ${kitchen.status}`
        });
    }

    // 🚨 Email conflict check (Prisma way)
    if (kitchenDetails?.email) {
        const emailInKitchen = await prisma.kitchen.findFirst({
            where: {
                email: kitchenDetails.email,
                kitchenId: { not: kitchenId }
            }
        });

        const emailInTeam = await prisma.teamMember.findFirst({
            where: { email: kitchenDetails.email }
        });

        if (emailInKitchen || emailInTeam) {
            return res.status(400).json({
                status: 0,
                message: "Email already exists. Please use a different email."
            });
        }
    }

    // 🔐 Hash password if provided
    let hashedPassword;
    if (kitchenDetails?.password) {
        hashedPassword = await bcrypt.hash(kitchenDetails.password, 10);
    }

    // 🔁 Transaction
    await prisma.$transaction(async (tx) => {

        // 1️⃣ Update Kitchen (reset status)
        await tx.kitchen.update({
            where: { kitchenId },
            data: {
                kitchenName: kitchenDetails?.kitchenName,
                email: kitchenDetails?.email,
                ownerName: kitchenDetails?.ownerName,
                contactNumber: kitchenDetails?.contactNumber,
                openingTime: kitchenDetails?.openingTime,
                closingTime: kitchenDetails?.closingTime,
                description: kitchenDetails?.description,
                deviceToken: kitchenDetails?.deviceToken || null,
                timezoneId: kitchenDetails?.timezoneId || 1,
                ...(hashedPassword && { password: hashedPassword }),

                status: "PENDING",
                isActive: 0,
                rejectReason: null,
                createdAt: new Date(),

                cuisines: kitchenDetails?.cuisineIds
                    ? {
                        set: kitchenDetails.cuisineIds.map(id => ({ id }))
                    }
                    : undefined,

                foodtypes: kitchenDetails?.foodtypes
                    ? {
                        set: kitchenDetails.foodtypes.map(id => ({ id }))
                    }
                    : undefined
            }
        });

        // 2️⃣ Upsert Address
        if (address) {
            await tx.kitchenAddress.upsert({
                where: { kitchenId },
                update: address,
                create: { ...address, kitchenId }
            });
        }

        // 3️⃣ Upsert Photos
        if (photos) {
            await tx.kitchenPhotos.upsert({
                where: { kitchenId },
                update: {
                    kitchenImages: photos.kitchenImages || [],
                    kitchenProfilePhoto: photos.kitchenProfilePhoto
                },
                create: {
                    kitchenId,
                    kitchenImages: photos.kitchenImages || [],
                    kitchenProfilePhoto: photos.kitchenProfilePhoto
                }
            });
        }

        // // 4️⃣ Upsert KYC
        // if (kyc) {
        //     await tx.kitchenKyc.upsert({
        //         where: { kitchenId },
        //         update: {
        //             ...kyc,
        //             expireDate: kyc.expireDate
        //                 ? new Date(kyc.expireDate)
        //                 : null
        //         },
        //         create: {
        //             ...kyc,
        //             expireDate: kyc.expireDate
        //                 ? new Date(kyc.expireDate)
        //                 : null,
        //             kitchenId
        //         }
        //     });
        // }
        // ===============================
        // 4️⃣ KYC (MOSTLY UPDATE)
        // ===============================
        if (kyc) {
            const existingKyc = await tx.kitchenKyc.findUnique({
                where: { kitchenId }
            });

            // Existing certificates
            let certificates = existingKyc?.foodCertificateImages || [];

            // ➕ Append new certificate if provided
            if (kyc.foodCertificateImage && kyc.expireDate) {
                certificates.push({
                    image: kyc.foodCertificateImage,
                    expireDate: parseExpireDate(kyc.expireDate)?.toISOString() ?? null,
                    addedAt: new Date().toISOString()
                });
            }

            if (existingKyc) {
                // 🔁 UPDATE (MAIN CASE)
                await tx.kitchenKyc.update({
                    where: { kitchenId },
                    data: {
                        abnNumber: kyc.abnNumber ?? existingKyc.abnNumber,
                        acn: kyc.acn ?? existingKyc.acn,
                        foodCertificateNumber:
                            kyc.foodCertificateNumber ?? existingKyc.foodCertificateNumber,
                        foodCertificateImages: certificates,
                        expireDate: parseExpireDate(kyc.expireDate) ?? existingKyc.expireDate,
                        fssaiNumber: kyc.fssaiNumber ?? existingKyc.fssaiNumber
                    }
                });
            } else {
                // 🆕 CREATE (ONLY IF NOT EXISTS)
                await tx.kitchenKyc.create({
                    data: {
                        kitchenId,
                        abnNumber: kyc.abnNumber || null,
                        acn: kyc.acn || null,
                        foodCertificateNumber: kyc.foodCertificateNumber || null,
                        foodCertificateImages: certificates,
                        expireDate: parseExpireDate(kyc.expireDate),
                        fssaiNumber: kyc.fssaiNumber || null
                    }
                });
            }
        }

    });

    // 🔍 CREATE AUDIT LOG - Reapplication
    await auditLogger.createAuditLog({
        kitchenId,
        actorType: 'RESTAURANT',
        actorId: kitchenId,
        actorName: kitchenDetails?.ownerName,
        actionType: 'STATUS_REAPPLIED',
        actionDescription: 'Restaurant reapplied after rejection',
        oldData: 'REJECTED',
        newData: 'PENDING',
        reason: kitchen.rejectReason,
        metadata: {
            updatedKyc: !!kyc,
            updatedAddress: !!address,
            updatedPhotos: !!photos
        },
        ipAddress: auditLogger.getIpAddress(req),
        userAgent: auditLogger.getUserAgent(req)
    });

    return res.status(200).json({
        status: 1,
        message: "Kitchen re-applied successfully. Awaiting admin approval."
    });
});

exports.logoutKitchen = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen; // From auth middleware
    const { deviceToken } = req.body;

    if (!deviceToken) {
        return res.status(400).json({
            status: 0,
            message: "deviceToken is required for logout"
        });
    }

    const kitchen = await prisma.kitchen.findUnique({
        where: { kitchenId },
        select: { deviceToken: true, deviceTokens: true }
    });

    if (!kitchen) {
        return res.status(404).json({
            status: 0,
            message: "Kitchen not found"
        });
    }

    let currentTokens = Array.isArray(kitchen.deviceTokens) ? kitchen.deviceTokens : [];
    const updatedTokens = currentTokens.filter(t => t !== deviceToken);

    // If the logging out token is the primary deviceToken, clear it or set to another one
    let newPrimaryToken = kitchen.deviceToken;
    if (kitchen.deviceToken === deviceToken) {
        newPrimaryToken = updatedTokens.length > 0 ? updatedTokens[0] : null;
    }

    await prisma.kitchen.update({
        where: { kitchenId },
        data: {
            deviceToken: newPrimaryToken,
            deviceTokens: updatedTokens
        }
    });

    return res.status(200).json({
        status: 1,
        message: "Logged out successfully"
    });
});

exports.getCategories = catchAsync(async (req, res) => {
    const BASE_URL = process.env.categories_s3;
    const { search } = req.query;
    const categories = await prisma.category.findMany({
        where: {
            isActive: 1,
            name: {
                contains: search,
                mode: "insensitive"
            }
        },
        orderBy: { name: "asc" }
    });

    const formatted = categories.map(c => ({
        ...c,
        image: c.image ? `${BASE_URL}${c.image}` : null
    }));

    res.status(200).json({
        status: 1,
        categories: formatted,
    });
});

exports.getCuisines = catchAsync(async (req, res) => {
    const BASE_URL = process.env.cuisines_s3;
    const { search } = req.query;
    const cuisines = await prisma.cuisine.findMany({
        where: {
            isActive: 1,
            name: {
                contains: search,
                mode: "insensitive"
            }
        },
        orderBy: { name: "asc" }
    });

    const formatted = cuisines.map(c => ({
        ...c,
        image: c.image ? `${BASE_URL}${c.image}` : null
    }));

    res.status(200).json({
        status: 1,
        cuisines: formatted
    });
});

exports.addMenuItem = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const {
        name,
        categoryIds = [],
        quantity,
        price,
        description,
        image,
        isVegetarian,
        discountPrice,
        isSpicy,
        startTime,
        endTime,
        foodtypeIds = [],
        startTimeDate,
        endTimeDate,

    } = req.body;

    if (!name || !quantity || !price || !Array.isArray(categoryIds) || categoryIds.length === 0) {
        return res.status(400).json({
            status: 0,
            message: "name, categoryIds[], quantity, price are required"
        });
    }

    console.log("startTimeDate", startTimeDate);
    console.log("endTimeDate", endTimeDate);
    const actualPrice = Number(price);
    const discountedPrice = Number(discountPrice) || 0;

    // ⭐ Calculate discount %
    let discountPercentage = 0;
    if (discountedPrice > 0 && discountedPrice < actualPrice) {
        discountPercentage = Math.round(((actualPrice - discountedPrice) / actualPrice) * 100);
    }

    const newItem = await prisma.menuItem.create({
        data: {
            kitchenId,
            name,
            quantity: Number(quantity),
            price: actualPrice,
            discountPrice: discountedPrice,
            discountPercentage,
            description: description || null,
            image: image || null,
            isVegetarian: Boolean(isVegetarian),
            isSpicy: isSpicy || "NORMAL",
            startTime: startTime || null,
            endTime: endTime || null,
            isActive: 1,
            foodtypeIds: {
                connect: foodtypeIds.map(id => ({ id: Number(id) }))
            },
            categoryIds: {
                connect: categoryIds.map(id => ({ id: Number(id) }))
            },
            startTimeDate: startTimeDate || null,
            endTimeDate: endTimeDate || null,
        }
    });

    // 🔔 Notify wishlist users about new menu item (non-blocking, non-fatal)
    setImmediate(async () => {
        try {
            const { sendNotificationToUser } = require("./handleFactory");

            // Fetch all users who wishlisted this kitchen, with their device token
            const wishlistEntries = await prisma.wishlist.findMany({
                where: { kitchenId },
                select: {
                    user: {
                        select: { userId: true, deviceToken: true, isActive: true, status: true }
                    }
                }
            });

            const eligibleUsers = wishlistEntries
                .map(w => w.user)
                .filter(u => u && u.isActive === 1 && u.status === "ACTIVE" && u.deviceToken);

            if (eligibleUsers.length === 0) return;

            const priceLabel = discountedPrice > 0 ? ` — $${discountedPrice.toFixed(2)}` : "";

            // Fetch kitchen name for notification text
            const kitchenInfo = await prisma.kitchen.findUnique({
                where: { kitchenId },
                select: { kitchenName: true }
            });
            const title = `New item at ${kitchenInfo?.kitchenName || "your favourite kitchen"}! 🍽️`;
            const body = `${name}${priceLabel} is now available. Grab it before it's gone!`;

            // Save in-app notification + send FCM push for each eligible user
            await prisma.notification.createMany({
                data: eligibleUsers.map(u => ({
                    ownerId: u.userId,
                    ownerType: "USER",
                    title,
                    message: body,
                    type: 2
                }))
            });

            // Send FCM push to each user's device token
            await Promise.allSettled(
                eligibleUsers.map(u =>
                    sendNotificationToUser(u.userId, { title, body, orderId: "" }, u.deviceToken)
                )
            );

            console.log(`✅ [NOTIFY] Wishlist notifications sent to  ${eligibleUsers.length} users for kitchen ${kitchenId}`);
        } catch (err) {
            console.error("⚠️ [NOTIFY] Wishlist notification error:", err.message);
        }
    });

    return res.status(201).json({
        status: 1,
        message: "Menu item added successfully",
        discountPercentage
    });
});

exports.getAllMenuItems = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen; // from authenticateKitchen()
    const { search } = req.query;
    const BASE_URL = process.env.menu_s3;
    const FOODTYPE_IMG = process.env.categories_s3 || "";
    const { markExpiredMenuItems } = require("../cron/menuItemExpiryChecker");

    // 1. Fetch menu items with timezone
    const menuItems = await prisma.menuItem.findMany({
        where: {
            kitchenId,
            isActive: {
                not: 2  // Exclude deleted items (isActive = 2)
            },
            ...(search && {
                name: {
                    contains: search   // 🔥 FIX: no mode key in Prisma 6
                }
            })
        },
        orderBy: {
            createdAt: "desc"
        },
        include: {
            categoryIds: { select: { id: true, name: true } },
            foodtypeIds: { select: { id: true, name: true, image: true } },
            kitchen: {
                include: {
                    timezone: true  // ⭐ For time validation
                }
            }
        }
    });

    console.log(`📊 [VENDOR] Fetched ${menuItems.length} menu items from database for kitchen ${kitchenId}`);
    console.log(`📊 [VENDOR] Items: ${menuItems.map(i => `${i.name} (isActive: ${i.isActive})`).join(', ')}`);

    // 2. Mark expired items as inactive but return ALL items (for vendor management)
    const allMenuItems = await markExpiredMenuItems(menuItems);

    console.log(`📊 [VENDOR] After marking expired: ${allMenuItems.length} items`);

    // 3. Format and remove kitchen object
    const formatted = allMenuItems.map(item => ({
        ...item,
        image: item.image ? `${BASE_URL}${item.image}` : null,
        kitchen: undefined,  // Clean response
        foodtypeIds: item.foodtypeIds?.map(ft => ({
            ...ft,
            image: ft.image ? `${FOODTYPE_IMG}${ft.image}` : null
        })),
        foodtype: item.foodtypeIds?.[0]
            ? {
                ...item.foodtypeIds[0],
                image: item.foodtypeIds[0].image ? `${FOODTYPE_IMG}${item.foodtypeIds[0].image}` : null
            }
            : null // ⭐ Backward Compatibility with image URL
    }));

    console.log(`📊 [VENDOR] Returning ${formatted.length} items to client`);

    return res.status(200).json({
        status: 1,
        message: "Menu items fetched successfully",
        menuItems: formatted
    });
});

exports.getMenuItemById = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { id } = req.params;

    const BASE_URL = process.env.menu_s3;
    const FOODTYPE_IMG = process.env.categories_s3 || "";

    const item = await prisma.menuItem.findFirst({
        where: {
            id: Number(id),
            kitchenId,
            isActive: {
                not: 2
            }
        },
        include: {
            categoryIds: { select: { id: true, name: true } },
            foodtypeIds: { select: { id: true, name: true, image: true } },
        }
    });

    if (!item) {
        return res.status(404).json({
            status: 0,
            message: "Menu item not found"
        });
    }

    return res.status(200).json({
        status: 1,
        message: "Menu item details",
        menuItem: {
            ...item,
            image: item.image ? `${BASE_URL}${item.image}` : null,
            foodtypeIds: item.foodtypeIds?.map(ft => ({
                ...ft,
                image: ft.image ? `${FOODTYPE_IMG}${ft.image}` : null
            })),
            foodtype: item.foodtypeIds?.[0]
                ? {
                    ...item.foodtypeIds[0],
                    image: item.foodtypeIds[0].image ? `${FOODTYPE_IMG}${item.foodtypeIds[0].image}` : null
                }
                : null // ⭐ Backward Compatibility with image URL
        }
    });
});

exports.updateMenuItem = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { id } = req.params;

    const {
        name,
        categoryIds,
        quantity,
        price,
        discountPrice,
        description,
        image,
        isVegetarian,
        isSpicy,
        startTime,
        endTime,
        startTimeDate,
        endTimeDate,
        foodtypeIds,
        isActive
    } = req.body;

    console.log("startTimeDate", startTimeDate);
    console.log("endTimeDate", endTimeDate);
    console.log("isActive", isActive);

    // 🔍 Fetch old item to check status transition and get details for notification
    const oldItem = await prisma.menuItem.findFirst({
        where: { id: Number(id), kitchenId },
        include: { kitchen: { include: { timezone: true } } }
    });

    if (!oldItem) {
        return res.status(404).json({
            status: 0,
            message: "Menu item not found"
        });
    }

    // Convert to numeric and validate
    const actualPrice = price !== undefined ? Number(price) : undefined;
    const discountedPrice = discountPrice !== undefined ? Number(discountPrice) : undefined;
    const validPrice = !isNaN(actualPrice) ? actualPrice : undefined;
    const validDiscountPrice = !isNaN(discountedPrice) ? discountedPrice : undefined;
    const validQuantity = quantity !== undefined ? Number(quantity) : undefined;
    const updateData = {
        name: name ?? undefined,
        description: description ?? undefined,
        image: image ?? undefined,
        isVegetarian: isVegetarian !== undefined ? Boolean(isVegetarian) : undefined,
        quantity: validQuantity,
        price: validPrice,
        discountPrice: validDiscountPrice,
        isSpicy: isSpicy || undefined,
        startTime: startTime || undefined,
        endTime: endTime || undefined,
        isActive: isActive !== undefined ? Number(isActive) : undefined,
        startTimeDate: startTimeDate || undefined,
        endTimeDate: endTimeDate || undefined,
    };

    // Update foodtype mapping (Restricted to single choice)
    if (foodtypeIds !== undefined) {
        updateData.foodtypeIds = {
            set: [],
            connect: foodtypeIds ? [{ id: Number(foodtypeIds) }] : []
        };
    }

    // ⭐ Recalculate discountPercentage only if price and discountPrice are valid
    if (validPrice && validDiscountPrice && validDiscountPrice < validPrice) {
        updateData.discountPercentage = Math.round(((validPrice - validDiscountPrice) / validPrice) * 100);
    } else {
        updateData.discountPercentage = 0;
    }

    // Update category mappings (Check if categoryIds exists)
    if (Array.isArray(categoryIds) && categoryIds.length > 0) {
        updateData.categoryIds = {
            set: [],
            connect: categoryIds.map(id => ({ id: Number(id) }))
        };
    }

    // ⏰ Time Validation: If trying to activate via update, check if it's already expired
    // We check against the NEW times if provided, otherwise the OLD times
    if (updateData.isActive === 1) {
        const { evaluateExpiry } = require("../cron/menuItemExpiryChecker");
        const timezoneName = oldItem.kitchen?.timezone?.name || "Australia/Sydney";

        const prospectiveItem = {
            ...oldItem,
            endTime: updateData.endTime !== undefined ? updateData.endTime : oldItem.endTime,
            endTimeDate: updateData.endTimeDate !== undefined ? updateData.endTimeDate : oldItem.endTimeDate
        };

        const { shouldDeactivate } = evaluateExpiry(prospectiveItem, timezoneName);

        if (shouldDeactivate) {
            console.log(`⚠️ [VENDOR] Activation blocked for item ${id} - it has expired.`);
            updateData.isActive = 0; // Keep it inactive as requested
        }
    }

    try {
        await prisma.menuItem.update({
            where: { id: Number(id) },
            data: updateData
        });

        // 🔔 Notify wishlist users if item is becoming active (0 -> 1)
        // ⭐ Use updateData.isActive to respect time validation results
        if (updateData.isActive === 1 && oldItem.isActive === 0) {
            setImmediate(async () => {
                try {
                    const { sendNotificationToUser } = require("./handleFactory");

                    // Fetch all users who wishlisted this kitchen
                    const wishlistEntries = await prisma.wishlist.findMany({
                        where: { kitchenId },
                        select: {
                            user: {
                                select: { userId: true, deviceToken: true, isActive: true, status: true }
                            }
                        }
                    });

                    const eligibleUsers = wishlistEntries
                        .map(w => w.user)
                        .filter(u => u && u.isActive === 1 && u.status === "ACTIVE" && u.deviceToken);

                    if (eligibleUsers.length === 0) return;

                    const finalPrice = discountedPrice !== undefined ? discountedPrice : oldItem.discountPrice;
                    const priceLabel = finalPrice > 0 ? ` — $${Number(finalPrice).toFixed(2)}` : "";

                    // Fetch kitchen name for notification text
                    const kitchenInfo = await prisma.kitchen.findUnique({
                        where: { kitchenId },
                        select: { kitchenName: true }
                    });

                    const itemName = name || oldItem.name;
                    const title = `Item available back at ${kitchenInfo?.kitchenName || "your favourite kitchen"}! 🍽️`;
                    const body = `${itemName}${priceLabel} is now available. Grab it before it's gone!`;

                    // Save in-app notification + send FCM push
                    await prisma.notification.createMany({
                        data: eligibleUsers.map(u => ({
                            ownerId: u.userId,
                            ownerType: "USER",
                            title,
                            message: body,
                            type: 2
                        }))
                    });

                    await Promise.allSettled(
                        eligibleUsers.map(u =>
                            sendNotificationToUser(u.userId, { title, body, orderId: "" }, u.deviceToken)
                        )
                    );

                    console.log(`✅ [NOTIFY] Update notifications sent to ${eligibleUsers.length} users for kitchen ${kitchenId}`);
                } catch (err) {
                    console.error("⚠️ [NOTIFY] Wishlist update notification error:", err.message);
                }
            });
        }

        return res.status(200).json({
            status: 1,
            message: "Menu item updated successfully"
        });
    } catch (error) {
        return res.status(500).json({
            status: 0,
            message: "Failed to update menu item",
            error: error.message
        });
    }
});

exports.getFoodTypes = catchAsync(async (req, res) => {
    const BASE_URL = process.env.categories_s3;

    const foodTypes = await prisma.foodtype.findMany({
        where: { isActive: 1, type: "KITCHEN" },
        orderBy: { createdAt: "desc" }
    });

    const formatted = foodTypes.map(c => ({
        ...c,
        image: c.image ? `${BASE_URL}${c.image}` : null
    }));

    res.status(200).json({
        status: 1,
        foodTypes: formatted,
    });
});

exports.getMenuTypes = catchAsync(async (req, res) => {
    const BASE_URL = process.env.categories_s3;

    const foodTypes = await prisma.foodtype.findMany({
        where: { isActive: 1, type: "MENU" },
        orderBy: { createdAt: "desc" }
    });

    const formatted = foodTypes.map(c => ({
        ...c,
        image: c.image ? `${BASE_URL}${c.image}` : null
    }));

    res.status(200).json({
        status: 1,
        menuTypes: formatted,
    });
});


exports.inactivateMenuItem = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;   // from authenticateKitchen middleware
    const { id } = req.params;           // menu item ID
    const { isActive } = req.query;      // 0 or 1

    if (isActive === undefined) {
        return res.status(400).json({
            status: 0,
            message: "isActive query param is required (1 or 0)"
        });
    }

    const newStatus = Number(isActive);
    if (![0, 1].includes(newStatus)) {
        return res.status(400).json({
            status: 0,
            message: "isActive must be 1 (activate) or 0 (inactivate)"
        });
    }

    // Check if item belongs to this kitchen + fetch kitchen timezone for validation
    const item = await prisma.menuItem.findFirst({
        where: {
            id: Number(id),
            kitchenId
        },
        include: {
            kitchen: {
                include: { timezone: true }
            }
        }
    });

    if (!item) {
        return res.status(404).json({
            status: 0,
            message: "Menu item not found"
        });
    }

    // ⏰ Time Validation: If trying to activate (0 -> 1), check if it's already expired
    if (newStatus === 1) {
        const { evaluateExpiry } = require("../cron/menuItemExpiryChecker");
        const timezoneName = item.kitchen?.timezone?.name || "Australia/Sydney";

        const { shouldDeactivate, reason } = evaluateExpiry(item, timezoneName);

        if (shouldDeactivate) {
            return res.status(200).json({
                status: 1,
                message: `Cannot activate: ${reason || "Item is outside its service time"}`
            });
        }
    }

    // Update item status
    await prisma.menuItem.update({
        where: { id: Number(id) },
        data: { isActive: newStatus }
    });

    // 🔔 Notify wishlist users if item is becoming active (0 -> 1)
    if (newStatus === 1 && item.isActive === 0) {
        setImmediate(async () => {
            try {
                const { sendNotificationToUser } = require("./handleFactory");

                // Fetch all users who wishlisted this kitchen
                const wishlistEntries = await prisma.wishlist.findMany({
                    where: { kitchenId },
                    select: {
                        user: {
                            select: { userId: true, deviceToken: true, isActive: true, status: true }
                        }
                    }
                });

                const eligibleUsers = wishlistEntries
                    .map(w => w.user)
                    .filter(u => u && u.isActive === 1 && u.status === "ACTIVE" && u.deviceToken);

                if (eligibleUsers.length === 0) return;

                const priceLabel = item.discountPrice > 0 ? ` — $${Number(item.discountPrice).toFixed(2)}` : "";

                const title = `Item available back at ${item.kitchen?.kitchenName || "your favourite kitchen"}! 🍽️`;
                const body = `${item.name}${priceLabel} is now available. Grab it before it's gone!`;

                // Save in-app notification + send FCM push
                await prisma.notification.createMany({
                    data: eligibleUsers.map(u => ({
                        ownerId: u.userId,
                        ownerType: "USER",
                        title,
                        message: body,
                        type: 2
                    }))
                });

                await Promise.allSettled(
                    eligibleUsers.map(u =>
                        sendNotificationToUser(u.userId, { title, body, orderId: "" }, u.deviceToken)
                    )
                );

                console.log(`✅ [NOTIFY] Toggle notifications sent to ${eligibleUsers.length} users for kitchen ${kitchenId}`);
            } catch (err) {
                console.error("⚠️ [NOTIFY] Wishlist toggle notification error:", err.message);
            }
        });
    }

    res.status(200).json({
        status: 1,
        message: `Menu item ${newStatus === 1 ? "activated" : "inactivated"} successfully`
    });
});

exports.deleteMenuItem = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { id } = req.params;

    const item = await prisma.menuItem.findFirst({
        where: {
            id: Number(id),
            kitchenId
        }
    });

    if (!item) {
        return res.status(404).json({
            status: 0,
            message: "Menu item not found"
        });
    }

    await prisma.menuItem.update({
        where: { id: Number(id) },
        data: { isActive: 2 }
    });

    return res.status(200).json({
        status: 1,
        message: "Menu item deleted"
    });
});

exports.getKitchenDetails = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;

    const KITCHEN_IMG = process.env.kitchen_s3 || "";
    const PROFILE_IMG = process.env.user_s3 || "";
    const MENU_IMG = process.env.menu_s3 || "";
    const KYC_IMG = process.env.kyc_s3 || "";

    const kitchen = await prisma.kitchen.findUnique({
        where: { kitchenId: Number(kitchenId) },
        include: {
            address: true,
            kyc: true,
            photos: true,
            items: true,
            cuisines: true,
            foodtypes: true, // Added foodtypes
            wishlist: true,
            reviews: {
                include: {
                    user: {
                        select: {
                            name: true,
                            profilePicture: true  // Adjusted to expected field
                        }
                    }
                },
                orderBy: { createdAt: "desc" }
            }
        }
    });

    if (!kitchen) {
        return res.status(404).json({ status: 0, message: "Kitchen not found" });
    }
    // ================================
    // 🔐 STRIPE ONBOARDING STATUS CHECK
    // ================================
    if (
        kitchen.stripeAccountId &&
        kitchen.stripeAccountConnected &&
        !kitchen.stripeOnboardingCompleted
    ) {
        try {
            const Stripe = require("stripe");
            const stripe = new Stripe(process.env.STRIPE_SECRET_KEY_VENDORS);

            const account = await stripe.accounts.retrieve(kitchen.stripeAccountId);

            const isCompleted =
                account.details_submitted === true &&
                account.charges_enabled === true &&
                account.payouts_enabled === true &&
                account.capabilities?.transfers === 'active' && // 🔥 Ensure transfers are enabled
                (
                    !account.requirements?.currently_due ||
                    account.requirements.currently_due.length === 0
                );

            if (isCompleted) {
                await prisma.kitchen.update({
                    where: { kitchenId: Number(kitchenId) },
                    data: {
                        stripeOnboardingCompleted: true,
                        stripeCompletedAt: new Date()
                    }
                });

                // 📡 Trigger socket to kitchen to update UI
                try {
                    const io = getIO();
                    io.to(`kitchen_${kitchenId}`).emit("stripe-onboarding-completed", {
                        success: true,
                        message: "Stripe onboarding completed successfully"
                    });
                    console.log(`📡 [SOCKET] Notified kitchen ${kitchenId} about onboarding completion`);
                } catch (socketError) {
                    console.error(`⚠️ [SOCKET] Failed to notify kitchen ${kitchenId}:`, socketError.message);
                }

                // 🔄 Update local object so response is correct
                kitchen.stripeOnboardingCompleted = true;
                kitchen.stripeCompletedAt = new Date();

                console.log(
                    `✅ [Stripe] Onboarding completed for kitchen ${kitchenId}`
                );
            }
        } catch (err) {
            console.error(
                `⚠️ [Stripe] Failed to verify onboarding for kitchen ${kitchenId}:`,
                err.message
            );
            // ❌ Do NOT fail API if Stripe is temporarily unavailable
        }
    }

    // 🔗 Generate Stripe onboarding URL if not completed
    let stripeOnboardingUrl = null;
    if (kitchen.stripeAccountId && !kitchen.stripeOnboardingCompleted) {
        // Direct link to Stripe Dashboard account status page
        stripeOnboardingUrl = `https://dashboard.stripe.com/b/${kitchen.stripeAccountId}/account/status`;
        console.log(`[Stripe] Generated dashboard URL for kitchen ${kitchenId}: ${stripeOnboardingUrl}`);
    }
    let stripeDashBoardUrl = null;
    if (kitchen.stripeAccountId) {
        stripeDashBoardUrl = `https://dashboard.stripe.com/b/${kitchen.stripeAccountId}/account/status`
    }

    const FOODTYPE_IMG = process.env.foodtype_s3 || "";
    const kitchenImages = Array.isArray(kitchen.photos?.kitchenImages)
        ? kitchen.photos.kitchenImages.map(img => `${KITCHEN_IMG}${img}`)
        : [];


    const formattedKitchen = {
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
        deviceToken: kitchen.deviceToken,
        stripeOnboardingCompleted: kitchen.stripeOnboardingCompleted,
        stripeAccountConnected: kitchen.stripeAccountConnected,
        stripeOnboardingUrl: stripeOnboardingUrl, // ⭐ Include onboarding URL
        stripeDashBoardUrl: stripeDashBoardUrl,
        notificationTime: kitchen.notificationTime,
        address: kitchen.address || null,
        foodtypes: kitchen.foodtypes?.map(ft => ({
            id: ft.id,
            name: ft.name,
            image: ft.image ? `${FOODTYPE_IMG}${ft.image}` : null,
            isActive: ft.isActive
        })) || [],
        timezoneId: kitchen.timezoneId,
        notificationTime: kitchen.notificationTime,
        // kyc: kitchen.kyc ? {
        //     abnNumber: kitchen.kyc.abnNumber,
        //     acn: kitchen.kyc.acn,
        //     foodCertificateNumber: kitchen.kyc.foodCertificateNumber,
        //     foodCertificateImage: kitchen.kyc.foodCertificateImage
        //         ? `${KYC_IMG}${kitchen.kyc.foodCertificateImage}`
        //         : null,
        //     foodCertificateImages: kitchen.kyc.foodCertificateImages
        //         ? kitchen.kyc.foodCertificateImages.map(img => `${KYC_IMG}${img}`)
        //         : null,
        //     expireDate: kitchen.kyc.expireDate,
        //     fssaiNumber: kitchen.kyc.fssaiNumber,
        // } : null,
        kyc: kitchen.kyc ? {
            abnNumber: kitchen.kyc.abnNumber,
            acn: kitchen.kyc.acn,
            foodCertificateNumber: kitchen.kyc.foodCertificateNumber,
            foodCertificateImage: kitchen.kyc.foodCertificateImage
                ? `${KYC_IMG}${kitchen.kyc.foodCertificateImage}`
                : null,
            // ✅ MULTIPLE CERTIFICATES WITH URL
            foodCertificateImages: Array.isArray(kitchen.kyc.foodCertificateImages)
                ? kitchen.kyc.foodCertificateImages.map(cert => ({
                    image: cert.image ? `${KYC_IMG}${cert.image}` : null,
                    expireDate: cert.expireDate || null,
                    addedAt: cert.addedAt || null
                }))
                : [],

            expireDate: kitchen.kyc.expireDate,
            fssaiNumber: kitchen.kyc.fssaiNumber,
        } : null,

        photos: kitchen.photos ? {
            kitchenImages,
            kitchenProfilePhoto: kitchen.photos.kitchenProfilePhoto
                ? `${KITCHEN_IMG}${kitchen.photos.kitchenProfilePhoto}`
                : null
        } : null,

        items: kitchen.items.map(item => ({
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            price: item.price,
            description: item.description,
            isVegetarian: item.isVegetarian,
            isSpicy: item.isSpicy,
            rating: item.rating,
            ratingCount: item.ratingCount,
            isActive: item.isActive,
            image: item.image ? `${MENU_IMG}${item.image}` : null
        })),

        reviews: kitchen.reviews.map(r => ({
            id: r.id,
            orderId: r.orderId,
            rating: r.rating,
            review: r.review,
            createdAt: r.createdAt,
            user: r.user ? {
                name: r.user.name,
                profilePicture: r.user.profilePicture
                    ? (r.user.profilePicture.startsWith('http') ? r.user.profilePicture : `${PROFILE_IMG}${r.user.profilePicture}`)
                    : null
            } : null
        }))
    };

    return res.status(200).json({
        status: 1,
        message: "Kitchen details fetched successfully",
        kitchen: formattedKitchen
    });
});

exports.updateNotificationTime = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { notificationTime } = req.body;

    const kitchen = await prisma.kitchen.findUnique({ where: { kitchenId } });

    if (!kitchen) {
        return res.status(404).json({ status: 0, message: "Kitchen not found" });
    }

    await prisma.kitchen.update({
        where: { kitchenId },
        data: { notificationTime }
    });

    return res.status(200).json({
        status: 1,
        message: "Notification time updated successfully"
    });
});

exports.updateKitchen = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { kitchenDetails, address, photos } = req.body;

    const kitchen = await prisma.kitchen.findUnique({
        where: { kitchenId },
        include: {
            address: true,
            photos: true
        }
    });

    if (!kitchen) {
        return res.status(404).json({ status: 0, message: "Kitchen not found" });
    }
    console.log(kitchenDetails);

    // ⭐ Update kitchen details
    if (kitchenDetails) {
        // const kitchenFieldsToCheck = [
        //     'kitchenName', 'email', 'ownerName', 'contactNumber',
        //     'openingTime', 'closingTime', 'description', 'timezoneId', 'stripeAccountId'
        // ];

        // kitchenFieldsToCheck.forEach(field => {
        //     if (kitchenDetails[field] !== undefined && kitchenDetails[field] !== kitchen[field]) {
        //         changedFields.push(field);
        //         oldData[field] = kitchen[field];
        //         newData[field] = kitchenDetails[field];
        //     }
        // });

        const updatedKitchen = await prisma.kitchen.update({
            where: { kitchenId },
            data: {
                kitchenName: kitchenDetails.kitchenName ?? undefined,
                email: kitchenDetails.email ?? undefined,
                ownerName: kitchenDetails.ownerName ?? undefined,
                contactNumber: kitchenDetails.contactNumber ?? undefined,
                openingTime: kitchenDetails.openingTime ?? undefined,
                closingTime: kitchenDetails.closingTime ?? undefined,
                description: kitchenDetails.description ?? undefined,
                timezoneId: kitchenDetails.timezoneId ?? undefined,
                stripeAccountId: kitchenDetails.stripeAccountId ?? undefined,
            }
        });

        // ⭐ Use the Stripe ID from request or fall back to DB stored ID
        const activeStripeId = kitchenDetails.stripeAccountId || kitchen.stripeAccountId;

        if (activeStripeId) {
            try {
                const { setWeeklyPayoutSchedule } = require('../utils/stripePayoutScheduler');
                await setWeeklyPayoutSchedule(activeStripeId);
                console.log(`✅ [AUTO] Verified/Set payout schedule for kitchen ${kitchenId}`);
            } catch (error) {
                console.error(`⚠️ [AUTO] Failed to verify/set payout schedule for kitchen ${kitchenId}:`, error.message);
            }
        }
    }

    // ⭐ Update address
    if (address) {
        const exists = await prisma.kitchenAddress.findUnique({ where: { kitchenId } });

        // const addressFieldsToCheck = [
        //     'houseNo', 'street', 'pincode', 'state', 'city',
        //     'country', 'landmark', 'latitude', 'longitude'
        // ];

        // addressFieldsToCheck.forEach(field => {
        //     if (address[field] !== undefined && address[field] !== kitchen.address?.[field]) {
        //         changedFields.push(`address.${field}`);
        //         oldData[`address.${field}`] = kitchen.address?.[field];
        //         newData[`address.${field}`] = address[field];
        //     }
        // });

        if (exists) {
            await prisma.kitchenAddress.update({
                where: { kitchenId },
                data: {
                    houseNo: address.houseNo ?? undefined,
                    street: address.street ?? undefined,
                    pincode: address.pincode ?? undefined,
                    state: address.state ?? undefined,
                    city: address.city ?? undefined,
                    country: address.country ?? undefined,
                    landmark: address.landmark ?? undefined,
                    latitude: address.latitude ?? undefined,
                    longitude: address.longitude ?? undefined
                }
            });
        } else {
            await prisma.kitchenAddress.create({
                data: { kitchenId, ...address }
            });
            // changedFields.push('address');
            // newData.address = 'created';
        }
    }

    // ⭐ Update Photos
    if (photos) {
        const exists = await prisma.kitchenPhotos.findUnique({ where: { kitchenId } });

        const photoData = {
            kitchenImages: photos.kitchenImages ?? undefined,
            kitchenProfilePhoto: photos.kitchenProfilePhoto ?? undefined
        };

        // // Helper function to convert image array to URLs
        // const imagesToUrls = (images) => {
        //     if (!images) return null;
        //     if (Array.isArray(images)) {
        //         return images.map(img => `${process.env.kitchen_s3}${img}`);
        //     }
        //     return `${process.env.kitchen_s3}${images}`;
        // };

        // if (photos.kitchenImages !== undefined && JSON.stringify(photos.kitchenImages) !== JSON.stringify(kitchen.photos?.kitchenImages)) {
        //     changedFields.push('photos.kitchenImages');
        //     oldData['photos.kitchenImages'] = imagesToUrls(kitchen.photos?.kitchenImages);
        //     newData['photos.kitchenImages'] = imagesToUrls(photos.kitchenImages);
        // }

        // if (photos.kitchenProfilePhoto !== undefined && photos.kitchenProfilePhoto !== kitchen.photos?.kitchenProfilePhoto) {
        //     changedFields.push('photos.kitchenProfilePhoto');
        //     oldData['photos.kitchenProfilePhoto'] = imagesToUrls(kitchen.photos?.kitchenProfilePhoto);
        //     newData['photos.kitchenProfilePhoto'] = imagesToUrls(photos.kitchenProfilePhoto);
        // }

        if (exists) {
            await prisma.kitchenPhotos.update({
                where: { kitchenId },
                data: photoData
            });
        } else {
            await prisma.kitchenPhotos.create({
                data: { kitchenId, ...photoData }
            });
            // changedFields.push('photos');
            // newData.photos = 'created';
        }
    }

    // // 🔍 CREATE AUDIT LOG - Only if there were changes
    // if (changedFields.length > 0) {
    //     const auditLogger = require('../utils/auditLogger');
    //     await auditLogger.createAuditLog({
    //         kitchenId,
    //         actorType: 'RESTAURANT',
    //         actorId: kitchenId,
    //         actorName: kitchen.ownerName,
    //         actionType: 'KITCHEN_UPDATED',
    //         actionDescription: `Kitchen profile updated: ${changedFields.join(', ')}`,
    //         oldData,
    //         newData,
    //         metadata: {
    //             fieldsUpdated: changedFields,
    //             updateSections: {
    //                 kitchenDetails: !!kitchenDetails,
    //                 address: !!address,
    //                 photos: !!photos
    //             }
    //         },
    //         ipAddress: auditLogger.getIpAddress(req),
    //         userAgent: auditLogger.getUserAgent(req)
    //     });
    // }

    return res.status(200).json({
        status: 1,
        message: "Kitchen updated successfully"
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
exports.getKitchenOrders = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { type, date, search } = req.query;

    const typeNum = Number(type);   // 👈 FIX

    let filterStatus = {};

    if (typeNum === 1) {
        filterStatus = { status: "PENDING" };
    } else if (typeNum === 2) {
        filterStatus = {
            status: {
                in: ["ACCEPTED", "PREPARING", "READY"]
            }
        };
    } else if (typeNum === 3) {
        filterStatus = {
            status: {
                in: ["PICKED", "NO_SHOW", "CANCELLED", "REJECTED"]
            }
        };
    }

    // 📅 Build where condition with optional date filter
    let whereCondition = { kitchenId, ...filterStatus };

    // Add date filter if provided
    if (date) {
        const startOfDay = new Date(date);
        startOfDay.setHours(0, 0, 0, 0);

        const endOfDay = new Date(date);
        endOfDay.setHours(23, 59, 59, 999);

        whereCondition.orderedAt = {
            gte: startOfDay,
            lte: endOfDay
        };
    }

    // 🔍 Add search filter by orderId if provided
    if (search) {
        const searchNum = Number(search);
        if (!isNaN(searchNum)) {
            whereCondition.orderId = searchNum;
        }
    }

    const orders = await prisma.order.findMany({
        where: whereCondition,
        orderBy: { orderedAt: "desc" },
        include: {
            items: {
                include: {
                    menu: {   // ⭐ fetch menu item name, image, price etc.
                        select: {
                            name: true
                        }
                    }
                }
            },
            user: {
                select: {
                    name: true,
                    phoneNumber: true
                }
            }
        }
    });

    res.json({ status: 1, orders });
});

exports.getKitchenOrderById = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { orderId } = req.params;

    const order = await prisma.order.findFirst({
        where: {
            orderId: Number(orderId),
            kitchenId
        },
        include: {
            items: {
                include: {
                    menu: {
                        select: {
                            name: true,
                            price: true,
                            quantity: true,
                            isVegetarian: true,
                            isSpicy: true
                        }
                    }
                }
            },
            user: {
                select: {
                    name: true,
                    phoneNumber: true,
                    profilePicture: true
                }
            },
            restaurantOrderInvoice: {
                select: {
                    invoiceNumber: true,
                    pdfUrl: true,
                    serviceFeePercent: true,
                    createdAt: true
                }
            }
        }
    });

    if (!order) {
        return res.status(404).json({
            status: 0,
            message: "Order not found"
        });
    }

    res.json({
        status: 1,
        order
    });
});

exports.acceptOrder = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { orderId } = req.params;
    const { dateTime } = req.body;

    // Convert dateTime string to Date object if provided
    const acceptedAtTime = dateTime ? new Date(dateTime) : new Date();
    console.log("Kitchen trying to accept order:", kitchenId, orderId, "acceptedAt:", acceptedAtTime);

    // Get payment info
    const payment = await prisma.orderPayment.findFirst({
        where: { orderId: Number(orderId) }
    });

    if (!payment) {
        return res.status(404).json({ status: 0, message: "Payment not found" });
    }

    console.log("💳 [PAYMENT] Payment Intent ID:", payment.paymentIntentId);
    console.log("💳 [PAYMENT] Current Status:", payment.status);

    // Capture the payment
    try {
        console.log("💳 [PAYMENT] Capturing payment...");
        const capturedPayment = await stripe.paymentIntents.capture(payment.paymentIntentId);
        console.log("✅ [PAYMENT] Payment captured successfully");
        console.log("💰 [PAYMENT] Captured amount:", capturedPayment.amount_received / 100);

        // Update payment status immediately (webhook will also update it, but this ensures it's updated)
        await prisma.orderPayment.update({
            where: { paymentIntentId: payment.paymentIntentId },
            data: { status: "SUCCEEDED" }
        });
        console.log("✅ [PAYMENT] Payment status updated to SUCCEEDED");

    } catch (stripeError) {
        console.error("❌ [PAYMENT] Error capturing payment:", stripeError.message);
        return res.status(500).json({
            status: 0,
            message: "Failed to capture payment",
            error: stripeError.message
        });
    }

    // Update order status
    await prisma.order.update({
        where: { orderId: Number(orderId) },
        data: {
            status: "ACCEPTED",
            paymentStatus: "PAID",
            acceptedAt: acceptedAtTime
        }
    });
    console.log("✅ [ORDER] Order status updated to ACCEPTED and PAID");

    // Fetch the order & verify it belongs to kitchen
    const orderRecord = await prisma.order.findUnique({
        where: { orderId: Number(orderId) }
    });

    if (!orderRecord)
        return res.status(404).json({ status: 0, message: "Order not found" });

    if (orderRecord.kitchenId !== kitchenId)
        return res.status(403).json({
            status: 0,
            message: "This order does NOT belong to your kitchen ❌"
        });

    // Now update safely
    const updatedOrder = await prisma.order.update({
        where: { orderId: Number(orderId) },
        data: {
            status: "ACCEPTED",
            acceptedAt: acceptedAtTime
        }
    });

    console.log("Order updated successfully:", updatedOrder);

    // ⏰ Cancel scheduled order acceptance check (if any)
    try {
        const { cancelOrderAcceptanceCheck } = require("../cron/orderAcceptanceChecker");
        const cancelled = cancelOrderAcceptanceCheck(Number(orderId));
        if (cancelled) {
            console.log(`✅ [ORDER ACCEPTANCE] Cancelled scheduled check for Order #${orderId}`);
        }
    } catch (error) {
        console.error("⚠️  [ORDER ACCEPTANCE] Error cancelling scheduled check:", error.message);
        // Don't fail the acceptance if cancellation fails
    }

    // ℹ️ Note: Inventory is already reduced during payment success in webhook
    // No need to reduce quantity again here

    // 2️⃣ Fetch user + device token
    const order = await prisma.order.findUnique({
        where: { orderId: Number(orderId) },
        include: {
            user: {
                select: {
                    userId: true,
                    deviceToken: true,
                    name: true
                }
            }
        }
    });

    if (!order || !order.user)
        return res.status(404).json({ status: 0, message: "User not found 🚫" });

    const userId = order.user.userId;
    const deviceToken = order.user.deviceToken;

    // 3️⃣ Create a DB notification
    const notification = await prisma.notification.create({
        data: {
            ownerId: userId,
            ownerType: "USER",
            title: "Order Accepted 👍",
            message: `Your order has been accepted and is now being prepared by the kitchen 👨‍🍳🔥`,
            orderId: order.orderId,
            type: 1
        }
    });

    // 4️⃣ Send Push Notification via FCM
    if (deviceToken) {
        await handleFactory.sendNotificationToUser(
            userId,
            {
                title: "Order Accepted 👍",
                body: `Great news! 🎉 Your order is now being prepared 👨‍🍳🔥`,
                orderId: order.orderId.toString(),
                status: "ACCEPTED"
            },
            deviceToken
        );
    }

    // 🔌 SOCKET — Notify user of status change
    try {
        const { getIO } = require('../utils/socket');
        getIO().to(`user_${userId}`).emit('order_status_update', {
            orderId: order.orderId,
            orderNumber: order.orderNumber,
            status: 'ACCEPTED',
            acceptedAt: updatedOrder.acceptedAt
        });
        console.log(`🔌 [SOCKET] Emitted order_status_update (ACCEPTED) to user_${userId}`);
    } catch (socketError) {
        console.error('⚠️ [SOCKET] Failed to emit order_status_update:', socketError.message);
    }

    res.json({ status: 1, message: "Order accepted" });
});

exports.rejectOrder = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { orderId } = req.params;
    const { dateTime } = req.body;
    console.log("Date Time:", dateTime);
    const payment = await prisma.orderPayment.findFirst({
        where: { orderId: Number(orderId) }
    });

    if (payment) {
        await stripe.paymentIntents.cancel(payment.paymentIntentId);
    }
    // Update order status
    await prisma.order.updateMany({
        where: { orderId: Number(orderId), kitchenId },
        data: { status: "REJECTED" }
    });

    // ✅ RESTORE menu item quantities (since order was rejected)
    console.log("📦 [INVENTORY] Restoring quantities for rejected order:", orderId);
    const orderItems = await prisma.orderItem.findMany({
        where: { orderId: Number(orderId) },
        select: {
            menuItemId: true,
            quantity: true,
            menu: {
                select: { name: true }
            }
        }
    });

    // Restore each menu item's quantity
    for (const item of orderItems) {
        const menuItem = await prisma.menuItem.findUnique({
            where: { id: item.menuItemId },
            select: { quantity: true, isActive: true }
        });

        if (menuItem) {
            const newQuantity = menuItem.quantity + item.quantity;

            // Restore quantity and reactivate if it was deactivated due to 0 quantity
            await prisma.menuItem.update({
                where: { id: item.menuItemId },
                data: {
                    quantity: newQuantity,
                    isActive: menuItem.isActive === 0 && newQuantity > 0 ? 1 : undefined
                }
            });

            console.log(`   ✅ [INVENTORY] ${item.menu.name}: ${menuItem.quantity} → ${newQuantity} (restored +${item.quantity})`);
        }
    }

    // Fetch user + device token
    const order = await prisma.order.findUnique({
        where: { orderId: Number(orderId) },
        include: {
            user: {
                select: {
                    userId: true,
                    deviceToken: true,
                    name: true
                }
            }
        }
    });

    if (order && order.user) {
        const userId = order.user.userId;
        const deviceToken = order.user.deviceToken;

        // Create a DB notification
        await prisma.notification.create({
            data: {
                ownerId: userId,
                ownerType: "USER",
                title: "Order Rejected ❌",
                message: `We're sorry, but the kitchen cannot fulfill your order at this time.`,
                orderId: order.orderId,
                type: 1
            }
        });

        // Send Push Notification via FCM
        if (deviceToken) {
            await handleFactory.sendNotificationToUser(
                userId,
                {
                    title: "Order Rejected ❌",
                    body: `We're sorry, but the kitchen cannot fulfill your order at this time.`,
                    orderId: order.orderId.toString(),
                    status: "REJECTED"
                },
                deviceToken
            );
        }
    }

    // 🔌 SOCKET — Notify user of status change
    if (order && order.user) {
        try {
            const { getIO } = require('../utils/socket');
            getIO().to(`user_${order.user.userId}`).emit('order_status_update', {
                orderId: order.orderId,
                orderNumber: order.orderNumber,
                status: 'REJECTED'
            });
            console.log(`🔌 [SOCKET] Emitted order_status_update (REJECTED) to user_${order.user.userId}`);
        } catch (socketError) {
            console.error('⚠️ [SOCKET] Failed to emit order_status_update:', socketError.message);
        }
    }

    // 🚫 Cancel scheduled no-show check
    try {
        const { cancelNoShowCheck } = require("../cron/orderNoShowChecker");
        cancelNoShowCheck(Number(orderId));
    } catch (noShowError) {
        console.error("❌ [NO SHOW] Error cancelling check:", noShowError.message);
    }

    res.json({ status: 1, message: "Order rejected" });
});

exports.updateStatus = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { orderId } = req.params;
    const { status, dateTime } = req.body;

    // Convert dateTime string to Date object if provided
    const timestamp = dateTime ? new Date(dateTime) : new Date();
    console.log("Update status - dateTime:", dateTime, "converted to:", timestamp);

    // Prepare update data with status-specific timestamps
    const updateData = { status };

    // Set appropriate timestamp based on status
    switch (status) {
        case 'PREPARING':
            updateData.preparedAt = timestamp;
            break;
        case 'PICKED':
            updateData.preparedAt = timestamp;
            updateData.pickedAt = timestamp;
            break;
        case 'NO_SHOW':
            updateData.preparedAt = timestamp;
            updateData.pickedAt = timestamp;
            break;
        // READY, NO_SHOW, CANCELLED don't have specific timestamp fields
    }

    // Update order status with timestamps
    await prisma.order.updateMany({
        where: { orderId: Number(orderId), kitchenId },
        data: updateData
    });

    // 🚫 Cancel scheduled no-show check if status is terminal
    const terminalStatuses = ['PICKED', 'CANCELLED', 'REJECTED', 'NO_SHOW'];
    if (terminalStatuses.includes(status)) {
        try {
            const { cancelNoShowCheck } = require("../cron/orderNoShowChecker");
            cancelNoShowCheck(Number(orderId));
        } catch (noShowError) {
            console.error("❌ [NO SHOW] Error cancelling check:", noShowError.message);
        }
    }

    // Fetch user + device token
    const order = await prisma.order.findUnique({
        where: { orderId: Number(orderId) },
        include: {
            user: {
                select: {
                    userId: true,
                    deviceToken: true,
                    name: true
                }
            },
            kitchen: {
                include: {
                    address: true,
                    kyc: true
                }
            },
            items: {
                include: {
                    menu: {
                        select: {
                            name: true,
                            price: true
                        }
                    }
                }
            }
        }
    });

    if (order && order.user) {
        const userId = order.user.userId;
        const deviceToken = order.user.deviceToken;

        // Define notification messages for each status
        const notificationTemplates = {
            PREPARING: {
                title: "Order Being Prepared 👨‍🍳",
                message: "Your order is now being prepared by the kitchen. It will be ready soon!",
                body: "Your order is now being prepared by the kitchen. It will be ready soon!"
            },
            READY: {
                title: "Order Ready for Pickup ✅",
                message: "Great news! Your order is ready for pickup. Please collect it at your convenience.",
                body: "Great news! Your order is ready for pickup. Please collect it at your convenience."
            },
            PICKED: {
                title: "Order Picked Up 📦",
                message: "Your order has been picked up. Enjoy your meal!",
                body: "Your order has been picked up. Enjoy your meal!"
            },
            NO_SHOW: {
                title: "Order Not Collected ⏰",
                message: "You did not collect your order. Please contact support if you have any questions.",
                body: "You did not collect your order. Please contact support if you have any questions."
            },
            CANCELLED: {
                title: "Order Cancelled ❌",
                message: "Your order has been cancelled. If you have any questions, please contact support.",
                body: "Your order has been cancelled. If you have any questions, please contact support."
            }
        };

        const template = notificationTemplates[status];

        // Only send notification for specific statuses
        if (template) {
            // Create a DB notification
            await prisma.notification.create({
                data: {
                    ownerId: userId,
                    ownerType: "USER",
                    title: template.title,
                    message: template.message,
                    orderId: order.orderId,
                    type: 1
                }
            });

            // Send Push Notification via FCM
            if (deviceToken) {
                await handleFactory.sendNotificationToUser(
                    userId,
                    {
                        title: template.title,
                        body: template.body,
                        orderId: order.orderId.toString(),
                        status: status
                    },
                    deviceToken
                );
            }
        }

        // 🔌 SOCKET — Notify user of status change (for ALL statuses)
        try {
            const { getIO } = require('../utils/socket');
            getIO().to(`user_${userId}`).emit('order_status_update', {
                orderId: order.orderId,
                orderNumber: order.orderNumber,
                status: status,
                preparedAt: updateData.preparedAt || null,
                pickedAt: updateData.pickedAt || null
            });
            console.log(`🔌 [SOCKET] Emitted order_status_update (${status}) to user_${userId}`);
        } catch (socketError) {
            console.error('⚠️ [SOCKET] Failed to emit order_status_update:', socketError.message);
        }

        // 📄 Generate Invoice when order is PICKED (delivered)
        if (status === "PICKED" || status === "NO_SHOW") {
            try {
                const { getNextOrderInvoiceNumber, generateOrderInvoice } = require("../utils/invoiceGenerator");

                // Check if invoice already exists
                const existingInvoice = await prisma.orderInvoice.findUnique({
                    where: { orderId: Number(orderId) }
                });

                if (!existingInvoice) {
                    console.log(`📄 Generating invoice for order ${orderId}...`);

                    // Generate invoice number
                    const invoiceNumber = await getNextOrderInvoiceNumber();

                    // Prepare customer address
                    const customerAddress = order.kitchen.address
                        ? `${order.kitchen.address.houseNo || ""} ${order.kitchen.address.street || ""}, ${order.kitchen.address.city || ""}, ${order.kitchen.address.state || ""} ${order.kitchen.address.pincode || ""}`.trim()
                        : null;

                    // Prepare restaurant address
                    const restaurantAddress = order.kitchen.address
                        ? `${order.kitchen.address.houseNo || ""} ${order.kitchen.address.street || ""}, ${order.kitchen.address.landmark || ""}, ${order.kitchen.address.city || ""}, ${order.kitchen.address.state || ""} ${order.kitchen.address.pincode || ""}`.trim()
                        : null;

                    // Prepare order items for invoice
                    const orderItems = order.items.map(item => ({
                        name: item.menu?.name || "Unknown Item",
                        quantity: item.quantity,
                        price: item.price,
                        totalPrice: item.totalPrice
                    }));

                    // Calculate subtotal (before tax)
                    const subtotal = order.itemTotal;

                    // Generate PDF
                    const { pdfUrl } = await generateOrderInvoice({
                        invoiceNumber,
                        order: {
                            orderId: order.orderId,
                            orderNumber: order.orderNumber,
                            totalAmount: order.totalAmount,
                            gstAmount: order.gstAmount,
                            platformFee: order.platformFee || 0,
                            packingCharges: 0 // Add if you have packing charges in your order model
                        },
                        customer: {
                            name: order.user.name || "Customer",
                            address: customerAddress,
                            phone: order.user.phoneNumber || "N/A"
                        },
                        restaurant: {
                            name: order.kitchen.kitchenName,
                            gstin: order.kitchen.kyc?.abnNumber || null,
                            fssai: order.kitchen.kyc?.fssaiNumber || null,
                            address: restaurantAddress,
                            state: order.kitchen.address?.state || null
                        },
                        orderItems,
                        createdAt: new Date()
                    });

                    // Save invoice to database
                    await prisma.orderInvoice.create({
                        data: {
                            orderId: Number(orderId),
                            invoiceNumber,
                            pdfUrl
                        }
                    });

                    console.log(`✅ Invoice generated successfully: ${invoiceNumber}`);
                    console.log(`📎 PDF URL: ${pdfUrl}`);
                } else {
                    console.log(`ℹ️ Invoice already exists for order ${orderId}`);
                }
            } catch (invoiceError) {
                console.error("❌ Error generating invoice:", invoiceError);
                // Don't fail the status update if invoice generation fails
            }

            // 📧 Send order completion email (only in production)
            if (process.env.NODE_ENV === 'production' && order.user.email) {
                const { sendOrderCompletionEmail } = require('../utils/emailService');
                const userName = order.user.name || 'Customer';
                const kitchenName = order.kitchen.kitchenName || 'Restaurant';

                const emailResult = await sendOrderCompletionEmail(
                    order.user.email,
                    userName,
                    kitchenName,
                    order.orderId
                );

                if (emailResult.success) {
                    console.log(`✅ Order completion email sent to ${order.user.email}`);
                } else {
                    console.error(`❌ Failed to send order completion email to ${order.user.email}:`, emailResult.error);
                }
            }
        }

        // 📄 Generate Restaurant Invoice when order is PICKED or NO_SHOW
        if (status === "PICKED" || status === "NO_SHOW") {
            try {
                const { generateRestaurantOrderInvoice, getNextOrderInvoiceNumber } = require("../utils/invoiceGenerator");

                console.log(`📄 Generating restaurant invoice for order ${orderId}...`);

                // Get service fee percentage from config
                const serviceFeeConfig = await prisma.config.findFirst({
                    where: { configKey: "Service Fee Percentage" }
                });
                const serviceFeePercent = Number(serviceFeeConfig?.configValue) || 15;

                // Generate restaurant invoice number
                const restaurantInvoiceNumber = await getNextOrderInvoiceNumber();

                // Prepare order items for invoice
                const orderItems = order.items.map(item => ({
                    name: item.menu?.name || "Unknown Item",
                    quantity: item.quantity,
                    price: item.price,
                    totalPrice: item.totalPrice
                }));

                // Generate Restaurant PDF
                const { pdfUrl: restaurantPdfUrl } = await generateRestaurantOrderInvoice({
                    invoiceNumber: restaurantInvoiceNumber,
                    order: {
                        orderId: order.orderId,
                        orderNumber: order.orderNumber,
                        totalAmount: order.totalAmount,
                        itemTotal: order.itemTotal
                    },
                    restaurant: {
                        name: order.kitchen.kitchenName,
                        gstin: order.kitchen.kyc?.abnNumber || null
                    },
                    orderItems,
                    serviceFeePercent,
                    createdAt: new Date()
                });

                console.log(`✅ Restaurant invoice generated successfully: ${restaurantInvoiceNumber}`);
                console.log(`📎 Restaurant PDF URL: ${restaurantPdfUrl}`);

                // Save restaurant invoice to database
                await prisma.restaurantOrderInvoice.create({
                    data: {
                        orderId: Number(orderId),
                        invoiceNumber: restaurantInvoiceNumber,
                        pdfUrl: restaurantPdfUrl,
                        serviceFeePercent
                    }
                });

                console.log(`✅ Restaurant invoice saved to database`);

            } catch (restaurantInvoiceError) {
                console.error("❌ Error generating restaurant invoice:", restaurantInvoiceError);
                // Don't fail the status update if restaurant invoice generation fails
            }
        }
    }

    res.json({ status: 1, message: "Order status updated" });
})




exports.getKitchenStatus = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen; // comes from authenticateKitchen()

    const kitchen = await prisma.kitchen.findUnique({
        where: { kitchenId }   // already a number
    });

    if (!kitchen) {
        return res.status(404).json({ status: 0, message: "Kitchen not found" });
    }

    res.json({
        status: 1,
        kitchenId,
        registrationStatus: kitchen.status,  // PENDING / APPROVED / REJECTED
        rejectReason: kitchen.rejectReason,
        message:
            kitchen.status === "APPROVED"
                ? "Your kitchen has been approved!"
                : kitchen.status === "REJECTED"
                    ? "Your kitchen has been rejected"
                    : "Verification in progress"
    });
});

exports.updateKitchenActiveStatus = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;   // From authenticateKitchen middleware
    const { isActive } = req.query;      // 0 or 1

    if (isActive === undefined) {
        return res.status(400).json({
            status: 0,
            message: "isActive query param is required (1 or 0)"
        });
    }

    const newStatus = Number(isActive);

    if (![0, 1].includes(newStatus)) {
        return res.status(400).json({
            status: 0,
            message: "isActive must be 1 (activate) or 0 (pause)"
        });
    }

    // Check kitchen exists
    const kitchen = await prisma.kitchen.findFirst({
        where: {
            kitchenId: Number(kitchenId),
            isActive: {
                not: 2
            }   // Kitchen must be active in DB
        }
    });

    if (!kitchen) {
        return res.status(404).json({
            status: 0,
            message: "Kitchen not found"
        });
    }

    // Update status
    await prisma.kitchen.update({
        where: { kitchenId: Number(kitchenId) },
        data: { isActive: newStatus }
    });

    return res.status(200).json({
        status: 1,
        message: `Kitchen ${newStatus === 1 ? "activated" : "paused"} successfully`
    });
});

// add team member 

exports.addTeamMember = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;

    const {
        firstName,
        lastName,
        email,
        phoneNumber,
        username,
        password,
        profilePhoto
    } = req.body;

    if (!firstName || !email || !password) {
        return res.status(400).json({
            status: 0,
            message: "firstName, email, and password are required"
        });
    }

    // ❗ Check email already used by ANY team member
    const teamExists = await prisma.teamMember.findFirst({
        where: { email }
    });

    if (teamExists) {
        return res.status(400).json({
            status: 0,
            message: "Email already exists in team members"
        });
    }

    // ❗ Check email already used in KITCHEN table
    const kitchenExists = await prisma.kitchen.findFirst({
        where: { email }
    });

    if (kitchenExists) {
        return res.status(400).json({
            status: 0,
            message: "Email already registered as a Kitchen account"
        });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const member = await prisma.teamMember.create({
        data: {
            kitchenId,
            firstName,
            lastName,
            email,
            phoneNumber,
            username,
            password: hashedPassword,
            profilePhoto
        }
    });

    return res.status(200).json({
        status: 1,
        message: "Team member added successfully",
        member
    });
});

exports.getTeamMembers = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;

    const PHOTO_BASE = process.env.team_s3 || "";

    const members = await prisma.teamMember.findMany({
        where: { kitchenId, isActive: 1 },
        orderBy: { createdAt: "desc" }
    });

    const formatted = members.map(m => ({
        ...m,
        profilePhoto: m.profilePhoto
            ? `${PHOTO_BASE}${m.profilePhoto}`
            : null
    }));

    return res.status(200).json({
        status: 1,
        message: "Team members fetched successfully",
        members: formatted
    });
});


exports.getTeamMemberById = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { kitchenId } = req.kitchen;  // kitchen owner token

    const member = await prisma.teamMember.findFirst({
        where: {
            id: Number(id),
            kitchenId,
            isActive: 1
        },
        select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            phoneNumber: true,
            username: true,
            profilePhoto: true,
            createdAt: true,
            updatedAt: true
        }
    });

    if (!member) {
        return res.status(404).json({
            status: 0,
            message: "Team member not found"
        });
    }

    // Add S3 prefix if stored as filename only
    const PHOTO_BASE = process.env.team_s3 || "";
    const finalMember = {
        ...member,
        profilePhoto: member.profilePhoto
            ? `${PHOTO_BASE}${member.profilePhoto}`
            : null
    };

    return res.status(200).json({
        status: 1,
        message: "Team member fetched successfully",
        member: finalMember
    });
});

exports.updateTeamMember = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { kitchenId } = req.kitchen;

    const data = { ...req.body };

    // ❗ Validate Email
    if (data.email) {

        // Check if email is used by another TEAM MEMBER
        const emailExists = await prisma.teamMember.findFirst({
            where: {
                email: data.email,
                id: { not: Number(id) },  // exclude this member
                kitchenId
            }
        });

        if (emailExists) {
            return res.status(400).json({
                status: 0,
                message: "Email already exists for another team member"
            });
        }

        // Check if email exists in KITCHEN table
        const kitchenExists = await prisma.kitchen.findFirst({
            where: { email: data.email }
        });

        if (kitchenExists) {
            return res.status(400).json({
                status: 0,
                message: "Email is registered as a Kitchen account"
            });
        }
    }

    await prisma.teamMember.update({
        where: { id: Number(id) },
        data
    });

    return res.status(200).json({
        status: 1,
        message: "Team member updated successfully"
    });
});

exports.deleteTeamMember = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { kitchenId } = req.kitchen;

    await prisma.teamMember.updateMany({
        where: { id: Number(id), kitchenId },
        data: { isActive: 0 }
    });

    return res.status(200).json({
        status: 1,
        message: "Team member removed successfully"
    });
});


exports.startKitchenSupportChat = catchAsync(async (req, res) => {
    const io = getIO(); // ✅ FIX
    const { kitchenId } = req.kitchen;
    const { message, image } = req.body;

    console.log("\n========== KITCHEN SUPPORT CHAT REQUEST ==========");
    console.log("📥 Request from Kitchen ID:", kitchenId);
    console.log("💬 Message:", message || "(no text message)");
    console.log("🖼️  Image:", image || "(no image)");
    console.log("⏰ Timestamp:", new Date().toISOString());

    if (!message && !image) {
        console.log("❌ Validation failed: No message or image provided");
        return res.status(400).json({
            status: 0,
            message: "Message or image required"
        });
    }

    // 🔍 Find existing room (OPEN or CLOSED)
    let room = await prisma.chatRoom.findFirst({
        where: { kitchenId }
    });

    // ➕ Create room if not exists, or reopen if closed
    if (!room) {
        console.log("🆕 Creating new chat room for kitchen:", kitchenId);
        room = await prisma.chatRoom.create({
            data: { kitchenId, status: "OPEN" }
        });
        console.log("✅ Chat room created with ID:", room.roomId);
    } else if (room.status === "CLOSED") {
        // 🔄 Reopen the closed chat room
        console.log("🔄 Reopening closed chat room ID:", room.roomId);
        room = await prisma.chatRoom.update({
            where: { roomId: room.roomId },
            data: {
                status: "OPEN",
                updatedAt: new Date()
            }
        });
        console.log("✅ Chat room reopened successfully");
    } else {
        console.log("📂 Using existing chat room ID:", room.roomId);
    }

    // 💾 Save message
    const savedMessage = await prisma.chatMessage.create({
        data: {
            roomId: room.roomId,
            senderRole: "KITCHEN",
            senderId: kitchenId,
            message: message || null,
            image: image || null
        }
    });
    console.log("💾 Message saved to database with ID:", savedMessage.messageId);

    const response = {
        messageId: savedMessage.messageId,
        roomId: room.roomId,
        senderRole: "KITCHEN",
        message: savedMessage.message,
        image: savedMessage.image,
        createdAt: savedMessage.createdAt
    };

    // 📡 Check admin connections and emit
    console.log("\n========== SOCKET.IO ADMIN CONNECTION CHECK ==========");

    // Get all sockets in the "admins" room
    const adminsRoom = io.sockets.adapter.rooms.get("admins");
    const adminCount = adminsRoom ? adminsRoom.size : 0;

    console.log("👥 Admins connected to 'admins' room:", adminCount);

    if (adminCount > 0) {
        console.log("✅ ADMINS ARE CONNECTED");
        console.log("📡 Emitting 'support-message' event to", adminCount, "admin(s)");

        // Log each connected admin socket ID
        if (adminsRoom) {
            const socketIds = Array.from(adminsRoom);
            console.log("🔌 Connected admin socket IDs:", socketIds);
        }

        io.to("admins").emit("support-message", response);
        console.log("✅ Message emitted successfully");
    } else {
        console.log("⚠️  WARNING: NO ADMINS CURRENTLY CONNECTED");
        console.log("📭 Message saved to database but not delivered in real-time");
        console.log("💡 Admins will see this message when they connect/refresh");

        // Still emit (won't reach anyone, but keeps code consistent)
        io.to("admins").emit("support-message", response);
    }

    console.log("\n========== RESPONSE DATA ==========");
    console.log("Response:", JSON.stringify(response, null, 2));
    console.log("==================================================\n");

    return res.json({
        status: 1,
        message: "Support message sent",
        roomId: room.roomId,
        data: response,
        // Add debug info in response (optional - remove in production)
        debug: {
            adminsConnected: adminCount,
            deliveredInRealTime: adminCount > 0
        }
    });
});

exports.getKitchenSupportChatMessages = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;

    // Find kitchen's chat room
    const room = await prisma.chatRoom.findFirst({
        where: { kitchenId }
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


// 🔐 Forgot Password Flow for Kitchen/Team Member

// 1️⃣ Send Forgot Password OTP
exports.sendForgotPasswordOTP = catchAsync(async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({
            status: 0,
            message: "Email is required"
        });
    }

    // Check if email exists in Kitchen or TeamMember
    const kitchen = await prisma.kitchen.findFirst({ where: { email } });
    const teamMember = await prisma.teamMember.findFirst({ where: { email } });

    if (!kitchen && !teamMember) {
        return res.status(404).json({
            status: 0,
            message: "Email not found"
        });
    }

    // Generate 6-digit OTP
    let otp = '123456'; // Fixed OTP for development
    if (process.env.NODE_ENV === 'production') {
        otp = Math.floor(100000 + Math.random() * 900000).toString(); // Random 6-digit OTP in production
    }

    // Store OTP in database
    if (kitchen) {
        await prisma.kitchen.update({
            where: { kitchenId: kitchen.kitchenId },
            data: {
                otp,
                otpStatus: 1
            }
        });
    } else if (teamMember) {
        await prisma.teamMember.update({
            where: { id: teamMember.id },
            data: {
                otp,
                otpStatus: 1
            }
        });
    }

    // Send OTP via email (only in production)
    if (process.env.NODE_ENV === 'production') {
        const { sendAdminForgotPasswordOTP } = require('../utils/emailService');
        const emailResult = await sendAdminForgotPasswordOTP(email, otp);

        if (emailResult.success) {
            console.log(`✅ [VENDOR FORGOT PASSWORD] OTP sent to ${email}`);
        } else {
            console.error(`❌ [VENDOR FORGOT PASSWORD] Failed to send OTP to ${email}:`, emailResult.error);
        }
    } else {
        console.log(`🔐 [VENDOR FORGOT PASSWORD] OTP for ${email}: ${otp} (Development mode - email not sent)`);
    }

    return res.status(200).json({
        status: 1,
        message: "OTP sent to your email",
    });
});

// 2️⃣ Verify Forgot Password OTP
exports.verifyForgotPasswordOTP = catchAsync(async (req, res) => {
    const { email, otp } = req.body;

    if (!email || !otp) {
        return res.status(400).json({
            status: 0,
            message: "Email and OTP are required"
        });
    }

    // Fetch kitchen or team member
    const kitchen = await prisma.kitchen.findFirst({ where: { email } });
    const teamMember = await prisma.teamMember.findFirst({ where: { email } });

    if (!kitchen && !teamMember) {
        return res.status(404).json({
            status: 0,
            message: "Email not found"
        });
    }

    // Verify OTP length
    if (otp.length !== 6) {
        return res.status(400).json({
            status: 0,
            message: "Invalid OTP format"
        });
    }

    // Verify OTP matches
    if (kitchen) {
        if (kitchen.otp !== otp || kitchen.otpStatus !== 1) {
            return res.status(400).json({
                status: 0,
                message: "Invalid or expired OTP"
            });
        }

        // Mark OTP as verified
        await prisma.kitchen.update({
            where: { kitchenId: kitchen.kitchenId },
            data: {
                otpStatus: 0
            }
        });
    } else if (teamMember) {
        if (teamMember.otp !== otp || teamMember.otpStatus !== 1) {
            return res.status(400).json({
                status: 0,
                message: "Invalid or expired OTP"
            });
        }

        // Mark OTP as verified
        await prisma.teamMember.update({
            where: { id: teamMember.id },
            data: {
                otpStatus: 0
            }
        });
    }

    return res.status(200).json({
        status: 1,
        message: "OTP verified successfully",
        email
    });
});

// 3️⃣ Reset Password
exports.resetPassword = catchAsync(async (req, res) => {
    const { email, newPassword } = req.body;

    if (!email || !newPassword) {
        return res.status(400).json({
            status: 0,
            message: "Email and new password are required"
        });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password for kitchen or team member
    const kitchen = await prisma.kitchen.findFirst({ where: { email } });
    const teamMember = await prisma.teamMember.findFirst({ where: { email } });

    if (kitchen) {
        await prisma.kitchen.update({
            where: { kitchenId: kitchen.kitchenId },
            data: { password: hashedPassword }
        });
    } else if (teamMember) {
        await prisma.teamMember.update({
            where: { id: teamMember.id },
            data: { password: hashedPassword }
        });
    } else {
        return res.status(404).json({
            status: 0,
            message: "Email not found"
        });
    }

    return res.status(200).json({
        status: 1,
        message: "Password reset successfully"
    });
});


exports.getNotifications = catchAsync(async (req, res) => {
    const { kitchenId, userRole = 'KITCHEN' } = req.kitchen;

    // 1️⃣ Fetch all notifications
    const notifications = await prisma.notification.findMany({
        where: {
            ownerId: Number(kitchenId),
            ownerType: userRole
        },
        orderBy: { createdAt: "desc" }
    });

    // 2️⃣ Mark unread notifications as read (bulk update)
    await prisma.notification.updateMany({
        where: {
            ownerId: Number(kitchenId),
            ownerType: userRole,
            isRead: false
        },
        data: { isRead: true }
    });



    return res.status(200).json({
        status: 1,
        message: "Notifications fetched successfully",
        count: notifications.length,
        notifications
    });
});


exports.getPayoutInvoices = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;

    const invoices = await prisma.kitchenPayout.findMany({
        where: {
            kitchenId: Number(kitchenId)
        },
        orderBy: { createdAt: "desc" }
    });

    return res.status(200).json({
        status: 1,
        message: "Payout invoices fetched successfully",
        count: invoices.length,
        invoices
    });
});

// Get detailed payout invoice information
exports.getPayoutInvoiceDetails = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { payoutId } = req.params;

    // Fetch payout details
    const payout = await prisma.kitchenPayout.findFirst({
        where: {
            payoutId: Number(payoutId),
            kitchenId: Number(kitchenId)
        },
        include: {
            invoice: true
        }
    });

    if (!payout) {
        return res.status(404).json({
            status: 0,
            message: "Payout not found"
        });
    }

    // Fetch all ELIGIBLE orders in this payout period
    // ⭐ CRITICAL: Only show orders that kitchen should be paid for
    // ✅ Include: ACCEPTED, PREPARING, READY, PICKED
    // ❌ Exclude: REJECTED, PENDING, CANCELLED, NO_SHOW, PAYMENT_PENDING
    const orders = await prisma.order.findMany({
        where: {
            kitchenId: Number(kitchenId),
            paymentStatus: "PAID",
            status: {
                in: ["ACCEPTED", "PREPARING", "READY", "PICKED", "NO_SHOW"]  // ⭐ ONLY eligible statuses
            },
            orderedAt: {
                gte: payout.periodStart,
                lte: payout.periodEnd
            }
        },
        include: {
            items: {
                include: {
                    menu: {
                        select: {
                            name: true
                        }
                    }
                }
            }
        },
        orderBy: {
            orderedAt: "desc"
        }
    });

    // Calculate totals
    const totalAmount = orders.reduce((sum, order) => sum + Number(order.totalAmount), 0);
    const totalPlatformFees = orders.reduce((sum, order) => sum + Number(order.platformFee), 0);
    const totalGST = orders.reduce((sum, order) => sum + Number(order.gstAmount), 0);

    // Use stored values from payout if available, otherwise calculate
    const finalTotalAmount = payout.totalOrderAmount ? Number(payout.totalOrderAmount) : totalAmount;
    const finalPlatformFees = payout.platformFeeAmount ? Number(payout.platformFeeAmount) : totalPlatformFees;
    const netPayout = Number(payout.payoutAmount);

    // ⭐ Get GST rate and Platform Fee (service fee %) from config
    const config = await prisma.config.findMany({
        where: {
            configKey: { in: ["GST Percentage", "Platform Fee"] }
        }
    });
    const gstPercent = Number(config.find(c => c.configKey === "GST Percentage")?.configValue) || 10;
    const gstRate = gstPercent / 100; // Convert to decimal (e.g., 10 -> 0.10)

    const platformFeePercent = Number(config.find(c => c.configKey === "Platform Fee")?.configValue) || 15;
    const platformFeeRate = platformFeePercent / 100; // Convert to decimal (e.g., 15 -> 0.15)

    // 📊 Breakdown Calculations
    // 🛑 NEW LOGIC: Remove platform fee from Listed Price base, just like in the PDF
    const listedPriceTotal = finalTotalAmount - finalPlatformFees;

    // ⭐ INCLUSIVE GST MATH: Net = Total / 1.1
    const listedPriceNet = Number((listedPriceTotal / (1 + gstRate)).toFixed(2));
    const listedPriceGST = Number((listedPriceTotal - listedPriceNet).toFixed(2));

    // ⭐ Calculate Service Fee (15% of Listed Price)
    // Use stored value if available, otherwise calculate from Listed Price
    let serviceFeeTotal;
    if (payout.serviceFeeAmount && Number(payout.serviceFeeAmount) > 0) {
        serviceFeeTotal = Number(payout.serviceFeeAmount);
    } else {
        // Get Service Fee Percentage from config (default 15%)
        const serviceFeeConfig = await prisma.config.findFirst({
            where: { configKey: "Service Fee Percentage" }
        });
        const serviceFeePercent = Number(serviceFeeConfig?.configValue) || 15;

        // Calculate service fee as percentage of Listed Price
        serviceFeeTotal = Number((listedPriceTotal * (serviceFeePercent / 100)).toFixed(2));
    }

    const serviceFeeNet = Number((serviceFeeTotal / (1 + gstRate)).toFixed(2));
    const serviceFeeGST = Number((serviceFeeTotal - serviceFeeNet).toFixed(2));

    // Total Payout = Listed Price - Service Fee
    const totalPayoutAmount = netPayout;
    const totalPayoutNet = Number((totalPayoutAmount / (1 + gstRate)).toFixed(2));
    const totalPayoutGST = Number((totalPayoutAmount - totalPayoutNet).toFixed(2));

    // Format orders for response
    const formattedOrders = orders.map(order => {
        const orderDisplayId = "OD" + String(order.orderNumber);
        const totalItems = order.items.reduce((sum, item) => sum + item.quantity, 0);

        return {
            orderId: order.orderId,
            orderDisplayId,
            totalAmount: Number(order.totalAmount),
            platformFee: Number(order.platformFee),
            gstAmount: Number(order.gstAmount),
            quantity: totalItems,
            status: order.status,
            orderedAt: order.orderedAt,
            items: order.items.map(item => ({
                name: item.menu?.name || "Unknown",
                quantity: item.quantity,
                price: Number(item.price)
            }))
        };
    });

    return res.status(200).json({
        status: 1,
        message: "Payout invoice details fetched successfully",
        data: {
            payoutId: payout.payoutId,
            invoiceNumber: payout.invoice?.invoiceNumber || null,
            pdfUrl: payout.invoice?.pdfUrl || null,
            periodStart: payout.periodStart,
            periodEnd: payout.periodEnd,
            summary: {
                totalOrders: orders.length,
                // 📊 Detailed Breakdown Table Format
                breakdown: {
                    listedPrice: {
                        gst: parseFloat(listedPriceGST.toFixed(2)),
                        netAmount: parseFloat(listedPriceNet.toFixed(2)),
                        total: parseFloat(listedPriceTotal.toFixed(2))
                    },
                    serviceFee: {
                        gst: parseFloat(serviceFeeGST.toFixed(2)),
                        netAmount: parseFloat(serviceFeeNet.toFixed(2)),
                        total: parseFloat(serviceFeeTotal.toFixed(2))
                    },
                    totalPayout: {
                        gst: parseFloat(totalPayoutGST.toFixed(2)),
                        netAmount: parseFloat(totalPayoutNet.toFixed(2)),
                        total: parseFloat(totalPayoutAmount.toFixed(2))
                    }
                },
                // Legacy fields for backward compatibility
                totalAmount: finalTotalAmount,
                gstAmount: totalGST,
                platformFeeDeducted: finalPlatformFees,
                netPayout: netPayout
            },
            orders: formattedOrders
        }
    });
});



exports.getKitchenDashboard = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { type = "today" } = req.query; // today | week | month
    const { startOfDay, endOfDay, startOfWeek, endOfWeek, startOfMonth, endOfMonth } = require("date-fns");

    const now = new Date();

    // ======================
    // 🔁 DATE RANGE BY TYPE
    // ======================
    let rangeStart;
    let rangeEnd;

    if (type === "week") {
        rangeStart = startOfWeek(now, { weekStartsOn: 1 }); // Monday
        rangeEnd = endOfWeek(now, { weekStartsOn: 1 });
    } else if (type === "month") {
        rangeStart = startOfMonth(now);
        rangeEnd = endOfMonth(now);
    } else {
        // today (default)
        rangeStart = startOfDay(now);
        rangeEnd = endOfDay(now);
    }

    // ======================
    // 💰 TOTAL ALL-TIME INCOME
    // ======================
    const totalIncomeAgg = await prisma.order.aggregate({
        where: {
            kitchenId,
            status: { notIn: ["CANCELLED", "REJECTED"] }
        },
        _sum: { totalAmount: true }
    });

    const totalIncome = Number(totalIncomeAgg._sum.totalAmount || 0);

    // ======================
    // 📦 RANGE ORDERS COUNT
    // ======================
    const ordersCount = await prisma.order.count({
        where: {
            kitchenId,
            orderedAt: { gte: rangeStart, lte: rangeEnd },
            status: { notIn: ["CANCELLED", "REJECTED"] }
        }
    });

    // ======================
    // 💵 RANGE REVENUE
    // ======================
    const revenueAgg = await prisma.order.aggregate({
        where: {
            kitchenId,
            orderedAt: { gte: rangeStart, lte: rangeEnd },
            status: { notIn: ["CANCELLED", "REJECTED"] }
        },
        _sum: { totalAmount: true }
    });

    const revenue = Number(revenueAgg._sum.totalAmount || 0);

    // ======================
    // ❌ RANGE CANCELLED
    // ======================
    const cancelledOrders = await prisma.order.count({
        where: {
            kitchenId,
            orderedAt: { gte: rangeStart, lte: rangeEnd },
            status: { in: ["CANCELLED", "REJECTED"] }
        }
    });

    // ======================
    // ✅ RESPONSE
    // ======================
    return res.json({
        status: 1,
        message: "Dashboard data fetched successfully",
        data: {
            totalIncome, // 🔥 all-time
            summary: {
                type, // today | week | month
                orders: ordersCount,
                revenue,
                cancelledOrders
            }
        }
    });
});


exports.getAllTransactions = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { startDate, endDate, download } = req.query;

    let start, end;

    if (startDate && endDate) {
        start = new Date(startDate);
        start.setHours(0, 0, 0, 0);

        end = new Date(endDate);
        end.setHours(23, 59, 59, 999);
    }

    // Build filter
    const whereFilter = {
        kitchenId,
        status: "PICKED",
    };

    if (startDate && endDate) {
        whereFilter.orderedAt = {
            gte: start,
            lte: end
        };
    }

    // Fetch data
    const transactions = await prisma.order.findMany({
        where: whereFilter,
        orderBy: { orderedAt: "desc" },
        select: {
            orderId: true,
            totalAmount: true,
            orderedAt: true,
            orderNumber: true,
            user: { select: { name: true } }
        }
    });

    // Format
    const formatted = transactions.map(t => ({
        orderId: t.orderId,
        customerName: t.user?.name || "Unknown Customer",
        amount: t.totalAmount,
        orderNumber: t.orderNumber,
        date: t.orderedAt.toISOString().slice(0, 10)
    }));

    if (download === "pdf") {
        const PDFDocument = require("pdfkit");
        const doc = new PDFDocument({ margin: 40 });

        res.setHeader("Content-Type", "application/pdf");
        res.setHeader(
            "Content-Disposition",
            "attachment; filename=transactions.pdf"
        );

        doc.pipe(res);

        // ---------- TITLE ----------
        doc.fontSize(22).font("Helvetica-Bold")
            .text("Transaction Report", { align: "center" });
        doc.moveDown();

        // ---------- DATE RANGE ----------
        if (startDate && endDate) {
            doc.fontSize(12).font("Helvetica")
                .text(`From: ${startDate}     To: ${endDate}`);
            doc.moveDown();
        }

        // ---------- COLUMN POSITIONS ----------
        const colOrderId = 40;
        const colCustomer = 160;
        const colAmount = 330;
        const colDate = 440;

        let headerY = doc.y + 10;

        // ---------- HEADER ----------
        doc.fontSize(12).font("Helvetica-Bold");

        doc.text("Order ID", colOrderId, headerY, { width: 100 });
        doc.text("Customer Name", colCustomer, headerY, { width: 150 });
        doc.text("Amount", colAmount, headerY, { width: 80, align: "right" });
        doc.text("Date", colDate, headerY, { width: 100 });

        // ---------- HEADER LINE ----------
        doc.moveTo(40, headerY + 18).lineTo(550, headerY + 18).stroke();
        doc.moveDown(2);

        // ---------- ROW STYLE ----------
        doc.font("Helvetica").fontSize(12);

        formatted.forEach((row) => {
            const y = doc.y;

            // FIX: Remove superscript junk & normalize characters
            let cleanAmount = String(row.amount)
                .normalize("NFKC")          // Normalize Unicode
                .replace(/[^\d.-]/g, "")    // Remove non-numeric characters
                .trim();

            // USE Rs. (₹ sometimes breaks in PDFKit)
            const finalAmount = `A$ ${cleanAmount}`;

            doc.text(String(row.orderId), colOrderId, y, { width: 100 });
            doc.text(row.customerName, colCustomer, y, { width: 150 });
            doc.text(finalAmount, colAmount, y, { width: 80, align: "right" });
            doc.text(row.date, colDate, y, { width: 100 });

            doc.moveDown(1);
        });

        doc.end();
        return;
    }

    // Normal JSON Response
    return res.json({
        status: 1,
        data: formatted
    });
});

// ========================================
// VENDOR NOTIFICATIONS
// ========================================

/**
 * Get vendor notifications
 */
exports.getVendorNotifications = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const [notifications, totalCount, unreadCount] = await Promise.all([
        prisma.notification.findMany({
            where: {
                ownerId: kitchenId,
                ownerType: "KITCHEN"
            },
            orderBy: {
                createdAt: "desc"
            },
            skip,
            take: limit
        }),
        prisma.notification.count({
            where: {
                ownerId: kitchenId,
                ownerType: "KITCHEN"
            }
        }),
        prisma.notification.count({
            where: {
                ownerId: kitchenId,
                ownerType: "KITCHEN",
                isRead: false
            }
        })
    ]);

    return res.status(200).json({
        status: 1,
        message: "Notifications fetched successfully",
        data: notifications,
        pagination: {
            page,
            limit,
            total: totalCount,
            totalPages: Math.ceil(totalCount / limit)
        },
        unreadCount
    });
});

/**
 * Manual trigger for certificate expiry check (for testing)
 */
exports.triggerCertificateExpiryCheck = catchAsync(async (req, res) => {
    console.log("🔧 [MANUAL TRIGGER] Certificate expiry check triggered manually");

    const { checkExpiringCertificates } = require("../cron/certificateExpiryChecker");
    const result = await checkExpiringCertificates();

    return res.status(200).json({
        status: 1,
        message: "Certificate expiry check completed",
        result
    });
});


// exports.validateOfferPrice = catchAsync(async (req, res) => {
//     const { price, offerPrice } = req.body;

//     if (!offerPrice || !price) {
//         return res.status(400).json({
//             status: 0,
//             message: "Offer price, price is required"
//         });
//     }


//     if (offerPrice < 0) {
//         return res.status(400).json({
//             status: 0,
//             message: "Offer price cannot be negative"
//         });
//     }

//     if (offerPrice > price) {
//         return res.status(400).json({
//             status: 0,
//             message: "Offer price cannot be greater than price"
//         });
//     }
//     // get Minimum Discount Percentage from config 

//     const minDiscountPercentage = await prisma.config.findFirst({
//         where: { configKey: "Minimum Discount Percentage" },
//         select: { configValue: true }
//     });

//     // calculate discount percentage
//     const discountPercentage = ((price - offerPrice) / price) * 100;

//     if (discountPercentage < Number(minDiscountPercentage.configValue)) {
//         return res.status(400).json({
//             status: 0,
//             message: `Minimum discount percentage is ${minDiscountPercentage.configValue}`
//         });
//     }


//     res.status(200).json({
//         status: 1,
//         message: "Offer price validated successfully"
//     });
// });
exports.validateOfferPrice = catchAsync(async (req, res) => {
    const { price, offerPrice } = req.body;

    if (!offerPrice || !price) {
        return res.status(400).json({
            status: 0,
            message: "Offer price, price is required"
        });
    }


    if (offerPrice < 0) {
        return res.status(400).json({
            status: 0,
            message: "Offer price cannot be negative"
        });
    }

    if (offerPrice > price) {
        return res.status(400).json({
            status: 0,
            message: "Offer price cannot be greater than price"
        });
    }
    // get Minimum Discount Percentage from config 

    const minDiscountPercentage = await prisma.config.findFirst({
        where: { configKey: "Minimum Discount Percentage" },
        select: { configValue: true }
    });

    // calculate discount percentage
    const discountPercentage = ((price - offerPrice) / price) * 100;

    if (discountPercentage < Number(minDiscountPercentage.configValue)) {
        return res.status(400).json({
            status: 0,
            message: `Minimum discount percentage is ${minDiscountPercentage.configValue}`
        });
    }


    res.status(200).json({
        status: 1,
        message: "Offer price validated successfully"
    });
});
// ========================================
// MONTHLY INVOICE ENDPOINTS
// ========================================

// Get list of monthly invoices for a kitchen
exports.getMonthlyInvoices = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;

    const invoices = await prisma.monthlyInvoice.findMany({
        where: {
            kitchenId: Number(kitchenId)
        },
        orderBy: { createdAt: "desc" }
    });

    return res.status(200).json({
        status: 1,
        message: "Monthly invoices fetched successfully",
        count: invoices.length,
        invoices
    });
});

// Get detailed monthly invoice information
exports.getMonthlyInvoiceDetails = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;
    const { invoiceId } = req.params;

    // Fetch monthly invoice details
    const invoice = await prisma.monthlyInvoice.findFirst({
        where: {
            invoiceId: Number(invoiceId),
            kitchenId: Number(kitchenId)
        }
    });

    if (!invoice) {
        return res.status(404).json({
            status: 0,
            message: "Monthly invoice not found"
        });
    }

    // Fetch all orders in this invoice period
    const orders = await prisma.order.findMany({
        where: {
            kitchenId: Number(kitchenId),
            paymentStatus: "PAID", // Only include paid orders
            orderedAt: {
                gte: invoice.periodStart,
                lte: invoice.periodEnd
            }
        },
        include: {
            items: {
                include: {
                    menu: {
                        select: {
                            name: true
                        }
                    }
                }
            }
        },
        orderBy: {
            orderedAt: "desc"
        }
    });

    // Calculate totals
    const totalAmount = orders.reduce((sum, order) => sum + Number(order.totalAmount), 0);
    const totalPlatformFees = orders.reduce((sum, order) => sum + Number(order.platformFee), 0);
    const totalGST = orders.reduce((sum, order) => sum + Number(order.gstAmount), 0);

    // Use stored values from invoice
    const finalTotalAmount = Number(invoice.totalOrderAmount);
    const finalPlatformFees = Number(invoice.platformFeeAmount);
    const netAmount = Number(invoice.netAmount);

    console.log("\n========== MONTHLY INVOICE CALCULATION ==========");
    console.log("📊 Stored Values:");
    console.log("   Total Order Amount:", finalTotalAmount);
    console.log("   Platform Fee Amount:", finalPlatformFees);
    console.log("   Net Amount (from DB):", netAmount);

    // ⭐ Get GST rate from config
    const config = await prisma.config.findMany({
        where: {
            configKey: { in: ["GST Percentage", "Service Fee Percentage"] }
        }
    });
    const gstPercent = Number(config.find(c => c.configKey === "GST Percentage")?.configValue) || 10;
    const gstRate = gstPercent / 100; // Convert to decimal (e.g., 10 -> 0.10)

    const serviceFeePercent = Number(config.find(c => c.configKey === "Service Fee Percentage")?.configValue) || 15;

    console.log("   GST Rate:", gstPercent + "%");
    console.log("   Service Fee %:", serviceFeePercent + "%");

    // 📊 Breakdown Calculations (SAME AS WEEKLY PAYOUT)
    // 🛑 Step 1: Remove platform fee from Listed Price base
    const listedPriceTotal = finalTotalAmount - finalPlatformFees;
    console.log("\n📊 Listed Price Calculation:");
    console.log("   Total:", listedPriceTotal, "=", finalTotalAmount, "-", finalPlatformFees);

    // ⭐ INCLUSIVE GST MATH: Net = Total / 1.1
    const listedPriceNet = Number((listedPriceTotal / (1 + gstRate)).toFixed(2));
    const listedPriceGST = Number((listedPriceTotal - listedPriceNet).toFixed(2));
    console.log("   Net:", listedPriceNet, "= Total / 1.1");
    console.log("   GST:", listedPriceGST, "= Total - Net");

    // Calculate Service Fee (Deduction)
    const serviceFeeTotal = listedPriceTotal - netAmount;
    const serviceFeeNet = Number((serviceFeeTotal / (1 + gstRate)).toFixed(2));
    const serviceFeeGST = Number((serviceFeeTotal - serviceFeeNet).toFixed(2));
    console.log("\n📊 Service Fee Calculation:");
    console.log("   Total:", serviceFeeTotal, "=", listedPriceTotal, "-", netAmount);
    console.log("   Net:", serviceFeeNet);
    console.log("   GST:", serviceFeeGST);

    // Total Payout = Net Amount
    const totalPayoutAmount = netAmount;
    const totalPayoutNet = Number((totalPayoutAmount / (1 + gstRate)).toFixed(2));
    const totalPayoutGST = Number((totalPayoutAmount - totalPayoutNet).toFixed(2));
    console.log("\n📊 Total Payout Calculation:");
    console.log("   Total:", totalPayoutAmount);
    console.log("   Net:", totalPayoutNet);
    console.log("   GST:", totalPayoutGST);
    console.log("====================================================\n");

    // Format orders for response
    const formattedOrders = orders.map(order => {
        const orderDisplayId = "OD" + String(order.orderNumber);
        const totalItems = order.items.reduce((sum, item) => sum + item.quantity, 0);

        return {
            orderId: order.orderId,
            orderDisplayId,
            totalAmount: Number(order.totalAmount),
            platformFee: Number(order.platformFee),
            gstAmount: Number(order.gstAmount),
            quantity: totalItems,
            status: order.status,
            orderedAt: order.orderedAt,
            items: order.items.map(item => ({
                name: item.menu?.name || "Unknown",
                quantity: item.quantity,
                price: Number(item.price)
            }))
        };
    });

    return res.status(200).json({
        status: 1,
        message: "Monthly invoice details fetched successfully",
        data: {
            invoiceId: invoice.invoiceId,
            invoiceNumber: invoice.invoiceNumber,
            pdfUrl: invoice.pdfUrl,
            month: invoice.month,
            year: invoice.year,
            periodStart: invoice.periodStart,
            periodEnd: invoice.periodEnd,
            summary: {
                totalOrders: orders.length,
                // 📊 Detailed Breakdown Table Format
                breakdown: {
                    listedPrice: {
                        gst: parseFloat(listedPriceGST.toFixed(2)),
                        netAmount: parseFloat(listedPriceNet.toFixed(2)),
                        total: parseFloat(listedPriceTotal.toFixed(2))
                    },
                    serviceFee: {
                        gst: parseFloat(serviceFeeGST.toFixed(2)),
                        netAmount: parseFloat(serviceFeeNet.toFixed(2)),
                        total: parseFloat(serviceFeeTotal.toFixed(2))
                    },
                    totalPayout: {
                        gst: parseFloat(totalPayoutGST.toFixed(2)),
                        netAmount: parseFloat(totalPayoutNet.toFixed(2)),
                        total: parseFloat(totalPayoutAmount.toFixed(2))
                    }
                },
                // Legacy fields for backward compatibility
                totalAmount: finalTotalAmount,
                gstAmount: totalGST,
                platformFeeDeducted: finalPlatformFees,
                netPayout: netAmount
            },
            orders: formattedOrders
        }
    });
});

// ✅ Stripe Onboarding Return Handler (Success)
exports.stripeOnboardingReturn = catchAsync(async (req, res) => {
    console.log("🎉 [STRIPE] Vendor returned from Stripe onboarding");

    // The webhook will update stripeOnboardingCompleted status
    // This endpoint just shows a success page

    return res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Stripe Setup Complete</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                }
                .container {
                    background: white;
                    padding: 40px;
                    border-radius: 12px;
                    box-shadow: 0 10px 40px rgba(0,0,0,0.1);
                    text-align: center;
                    max-width: 400px;
                }
                .success-icon {
                    font-size: 64px;
                    margin-bottom: 20px;
                }
                h1 {
                    color: #333;
                    margin-bottom: 10px;
                }
                p {
                    color: #666;
                    line-height: 1.6;
                }
                .note {
                    background: #f0f9ff;
                    border-left: 4px solid #3b82f6;
                    padding: 12px;
                    margin-top: 20px;
                    text-align: left;
                    font-size: 14px;
                }
                .dashboard-link {
                    display: inline-block;
                    margin-top: 20px;
                    padding: 12px 24px;
                    background: #635bff;
                    color: white;
                    text-decoration: none;
                    border-radius: 6px;
                    font-weight: 600;
                    transition: background 0.2s;
                }
                .dashboard-link:hover {
                    background: #4f46e5;
                }
                .secondary-text {
                    margin-top: 20px;
                    font-size: 14px;
                    color: #999;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="success-icon">✅</div>
                <h1>Stripe Setup Complete!</h1>
                <p>Your Stripe account has been successfully connected. You can now receive payments from customers.</p>
                
                <a href="https://dashboard.stripe.com/express/dashboard" class="dashboard-link" target="_blank">
                    Open Stripe Dashboard →
                </a>
                
                <div class="note">
                    <strong>What you can do in Stripe Dashboard:</strong>
                    <ul style="margin: 10px 0 0 0; padding-left: 20px; text-align: left;">
                        <li>View your payouts and transactions</li>
                        <li>Update bank account details</li>
                        <li>Manage tax settings</li>
                        <li>View payment history</li>
                    </ul>
                </div>
                
                <p class="secondary-text">
                    You can close this window and return to the ResQBox app.
                </p>
            </div>
        </body>
        </html>
    `);
});

// ✅ Stripe Onboarding Refresh Handler (Retry/Expired)
exports.stripeOnboardingRefresh = catchAsync(async (req, res) => {
    console.log("🔄 [STRIPE] Vendor needs to refresh onboarding link");

    // Show a page that tells them to go back to the app
    return res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Stripe Setup - Refresh Required</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                }
                .container {
                    background: white;
                    padding: 40px;
                    border-radius: 12px;
                    box-shadow: 0 10px 40px rgba(0,0,0,0.1);
                    text-align: center;
                    max-width: 400px;
                }
                .warning-icon {
                    font-size: 64px;
                    margin-bottom: 20px;
                }
                h1 {
                    color: #333;
                    margin-bottom: 10px;
                }
                p {
                    color: #666;
                    line-height: 1.6;
                }
                .note {
                    background: #fff3cd;
                    border-left: 4px solid #ffc107;
                    padding: 12px;
                    margin-top: 20px;
                    text-align: left;
                    font-size: 14px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="warning-icon">⚠️</div>
                <h1>Session Expired</h1>
                <p>Your Stripe onboarding session has expired or needs to be refreshed.</p>
                <div class="note">
                    <strong>What to do:</strong>
                    <ol style="margin: 10px 0 0 0; padding-left: 20px;">
                        <li>Return to the ResQBox vendor app</li>
                        <li>Go to your profile/settings</li>
                        <li>Click on "Complete Stripe Setup" again</li>
                    </ol>
                </div>
                <p style="margin-top: 2
                0px; font-size: 14px; color: #999;">
                    You can close this window and return to the app.
                </p>
            </div>
        </body>
        </html>
    `);
});

// ✅ Get Stripe Dashboard Login Link
exports.getStripeDashboardLink = catchAsync(async (req, res) => {
    const { kitchenId } = req.kitchen;

    const kitchen = await prisma.kitchen.findUnique({
        where: { kitchenId },
        select: { stripeAccountId: true, stripeOnboardingCompleted: true }
    });

    if (!kitchen) {
        return res.status(404).json({
            status: 0,
            message: "Kitchen not found"
        });
    }

    if (!kitchen.stripeAccountId) {
        return res.status(400).json({
            status: 0,
            message: "Stripe account not connected"
        });
    }

    if (!kitchen.stripeOnboardingCompleted) {
        return res.status(400).json({
            status: 0,
            message: "Please complete Stripe onboarding first"
        });
    }

    try {
        // Create a login link for the connected account
        const loginLink = await stripe.accounts.createLoginLink(kitchen.stripeAccountId);

        return res.json({
            status: 1,
            message: "Stripe dashboard link generated",
            dashboardUrl: loginLink.url
        });
    } catch (error) {
        console.error("Error creating Stripe dashboard link:", error);
        return res.status(500).json({
            status: 0,
            message: "Failed to generate dashboard link",
            error: error.message
        });
    }
});
