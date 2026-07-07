const nodemailer = require('nodemailer');

/**
 * Send email using nodemailer with Gmail SMTP
 * @param {Object} options - Email options
 * @param {string} options.to - Recipient email
 * @param {string} options.subject - Email subject
 * @param {string} options.html - HTML content
 * @returns {Promise<Object>} - Email send result
 */
async function sendEmail({ to, subject, html }) {
    try {
        // Create transporter using Gmail SMTP
        const transporter = nodemailer.createTransport({
            host: "smtp.gmail.com",
            port: 587,
            secure: false, // true for 465, false for 587
            auth: {
                user: "support@resqboxfood.com",
                pass: process.env.SMTP_PASSWORD
            }
        });

        // Send email
        const info = await transporter.sendMail({
            from: "ResQBox Food [No Reply] <no-reply@resqboxfood.com>",
            to,
            replyTo: "support@resqboxfood.com",
            subject,
            html
        });

        console.log('✅ Email sent successfully to:', to);
        return { success: true, messageId: info.messageId };
    } catch (error) {
        console.error('❌ Error sending email to', to, ':', error.message);
        return { success: false, error: error.message };
    }
}

/**
 * Send kitchen approval email
 * @param {string} email - Kitchen email
 * @param {string} kitchenName - Kitchen name
 */
async function sendKitchenApprovalEmail(email, kitchenName) {
    const subject = 'Great news! Your kitchen is verified - ResQBox Food';
    const html = `
        <div style="
            font-family: Arial, sans-serif;
            background: #f6f5ff;
            padding: 20px;
            border-radius: 10px;
        ">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;
                box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                
                <h2 style="color:#4CAF50;text-align:center;margin-bottom:10px;">
                    🎉 Kitchen Approved!
                </h2>

                <p style="font-size:16px;color:#333;">
                    Hi <strong>${kitchenName}</strong>,
                </p>

                <p style="font-size:16px;color:#333;">
                    Your kitchen verification has been <strong style="color:#4CAF50;">Approved</strong>! You are now an official partner of <strong style="color:#FF6B35;">ResQBox Food</strong>.
                </p>

                <p style="font-size:16px;color:#333;">
                    You can now log in to your dashboard and start listing your meals. We're excited to have you on board!
                </p>

                <p style="font-size:14px;color:#777;margin-top:25px;">
                    If you have any questions, feel free to reach out to us.
                </p>

                <p style="margin-top:25px;color:#333;">
                    Best regards,<br>
                    <strong style="color:#FF6B35;">The ResQBox Food Team</strong>
                </p>

                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">
                        © ${new Date().getFullYear()} ResQBox Food. All rights reserved.
                    </p>
                    <p style="font-size:12px;color:#999;">
                        Contact us at <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;">support@resqboxfood.com</a>
                    </p>
                </div>
            </div>
        </div>
    `;

    return await sendEmail({ to: email, subject, html });
}

/**
 * Send kitchen rejection email
 * @param {string} email - Kitchen email
 * @param {string} kitchenName - Kitchen name
 * @param {string} reason - Rejection reason
 */
async function sendKitchenRejectionEmail(email, kitchenName, reason) {
    const subject = 'Update regarding your kitchen verification - ResQBox Food';
    const html = `
        <div style="
            font-family: Arial, sans-serif;
            background: #f6f5ff;
            padding: 20px;
            border-radius: 10px;
        ">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;
                box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                
                <h2 style="color:#FF6B35;text-align:center;margin-bottom:10px;">
                    Kitchen Verification Update
                </h2>

                <p style="font-size:16px;color:#333;">
                    Hi <strong>${kitchenName}</strong>,
                </p>

                <p style="font-size:16px;color:#333;">
                    Thank you for your interest in joining <strong style="color:#FF6B35;">ResQBox Food</strong>. After reviewing your submission, we are unable to approve your kitchen at this time.
                </p>

                <div style="
                    background: #fff3cd;
                    border-left: 4px solid #FF6B35;
                    padding: 15px;
                    margin: 20px 0;
                    border-radius: 4px;
                ">
                    <strong style="color:#856404;">Reason:</strong><br>
                    <span style="color:#856404;">${reason || 'Please contact support for more details.'}</span>
                </div>

                <p style="font-size:16px;color:#333;">
                    You are welcome to re-submit your details once the above requirements are met.
                </p>

                <p style="font-size:16px;color:#333;">
                    If you have questions, please contact us at <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;text-decoration:none;font-weight:bold;">support@resqboxfood.com</a>.
                </p>


                <p style="margin-top:25px;color:#333;">
                    Best regards,<br>
                    <strong style="color:#FF6B35;">The ResQBox Food Team</strong>
                </p>

                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">
                        © ${new Date().getFullYear()} ResQBox Food. All rights reserved.
                    </p>
                </div>
            </div>
        </div>
    `;

    return await sendEmail({ to: email, subject, html });
}

/**
 * Send OTP email for admin forgot password
 * @param {string} email - Admin email
 * @param {string} otp - OTP code
 */
async function sendAdminForgotPasswordOTP(email, otp) {
    const subject = 'Reset Your Password - ResQBox Food';
    const html = `
        <div style="
            font-family: Arial, sans-serif;
            background: #f6f5ff;
            padding: 20px;
            border-radius: 10px;
        ">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;
                box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                
                <h2 style="color:#FF6B35;text-align:center;margin-bottom:10px;">
                    ResQBox Food
                </h2>

                <p style="font-size:16px;color:#333;">
                    Hello,
                </p>

                <p style="font-size:16px;color:#333;">
                    You requested to reset your password. Please use the OTP below to verify your account.
                </p>

                <div style="
                    margin: 25px auto;
                    width: fit-content;
                    background: linear-gradient(135deg, #FF6B35 0%, #4CAF50 100%);
                    padding: 14px 28px;
                    border-radius: 12px;
                    color: white;
                    font-size: 26px;
                    font-weight: bold;
                    letter-spacing: 6px;
                    text-align: center;
                ">
                    ${otp}
                </div>

                <p style="font-size:14px;color:#777;margin-top:25px;">
                    If you did not request this, you can safely ignore this email.
                </p>

                <p style="margin-top:25px;color:#333;">
                    Regards,<br>
                    <strong style="color:#FF6B35;">ResQBox Food Team</strong>
                </p>

                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">
                        © ${new Date().getFullYear()} ResQBox Food. All rights reserved.
                    </p>
                </div>
            </div>
        </div>
    `;

    return await sendEmail({ to: email, subject, html });
}

/**
 * Send welcome email to new user
 * @param {string} email - User email
 * @param {string} userName - User name
 */
async function sendUserWelcomeEmail(email, userName) {
    const subject = 'Welcome to ResQBox Food!';
    const html = `
        <div style="
            font-family: Arial, sans-serif;
            background: #f6f5ff;
            padding: 20px;
            border-radius: 10px;
        ">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;
                box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                
                <h2 style="color:#FF6B35;text-align:center;margin-bottom:10px;">
                    Welcome to ResQBox Food!
                </h2>

                <p style="font-size:16px;color:#333;">
                    Hi <strong>${userName}</strong>,
                </p>

                <p style="font-size:16px;color:#333; line-height: 1.6;">
                    Welcome to ResQBox Food — we’re excited to have you join our community!
                </p>

                <p style="font-size:16px;color:#333; line-height: 1.6;">
                    Thank you for signing up. By being part of ResQBox Food, you’re helping reduce food waste while enjoying delicious meals at amazing prices. It’s a win for you and the planet!
                </p>

                <p style="font-size:16px;color:#333; line-height: 1.6;">
                    You can start exploring local kitchens and place your first order right away through the app. Great food is just a few taps away.
                </p>

                <p style="margin-top:25px;color:#333; font-size:16px;">
                    Happy eating,<br>
                    <strong style="color:#FF6B35;">The ResQBox Food Team</strong>
                </p>

                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">
                        © ${new Date().getFullYear()} ResQBox Food. All rights reserved.
                    </p>
                    <p style="font-size:12px;color:#999;">
                        Contact us at <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;">support@resqboxfood.com</a>
                    </p>
                </div>
            </div>
        </div>
    `;

    return await sendEmail({ to: email, subject, html });
}

/**
 * Send order completion and feedback email
 * @param {string} email - User email
 * @param {string} userName - User name
 * @param {string} kitchenName - Kitchen name
 * @param {number} orderId - Order ID
 */
async function sendOrderCompletionEmail(email, userName, kitchenName, orderId) {
    const subject = 'How was your meal? 😋';
    const html = `
        <div style="
            font-family: Arial, sans-serif;
            background: #f6f5ff;
            padding: 20px;
            border-radius: 10px;
        ">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;
                box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                
                <h2 style="color:#4CAF50;text-align:center;margin-bottom:10px;">
                    Order Completed! 😋
                </h2>

                <p style="font-size:16px;color:#333;">
                    Hi <strong>${userName}</strong>,
                </p>

                <p style="font-size:16px;color:#333;">
                    Your order from <strong style="color:#FF6B35;">${kitchenName}</strong> has been completed. We hope you enjoyed every bite!
                </p>

                <div style="
                    background: #f0f9ff;
                    border-left: 4px solid #4CAF50;
                    padding: 15px;
                    margin: 20px 0;
                    border-radius: 4px;
                ">
                    <strong style="color:#4CAF50;">📝 Rate your experience:</strong><br>
                    <span style="color:#555;">Your feedback helps our kitchens grow and helps other users find the best food.</span>
                </div>

                <p style="font-size:16px;color:#333;">
                    If you enjoyed your meal, please take a moment to rate us on the Play Store or App Store.
                </p>


                <p style="font-size:14px;color:#666;text-align:center;margin-top:15px;">
                    You can download the invoice from the <strong style="color:#FF6B35;">ResQBox Food App</strong>.
                </p>

                <p style="font-size:16px;color:#333;text-align:center;">
                    See you again soon for your next rescue! 🌱
                </p>

                <p style="margin-top:25px;color:#333;">
                    Best regards,<br>
                    <strong style="color:#FF6B35;">The ResQBox Food Team</strong>
                </p>

                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">
                        © ${new Date().getFullYear()} ResQBox Food. All rights reserved.
                    </p>
                    <p style="font-size:12px;color:#999;">
                        Contact us at <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;">support@resqboxfood.com</a>
                    </p>
                </div>
            </div>
        </div>
    `;

    return await sendEmail({ to: email, subject, html });
}

/**
 * Send kitchen verification received email
 * @param {string} email - Kitchen email
 * @param {string} kitchenName - Kitchen name
 */
async function sendKitchenVerificationReceivedEmail(email, kitchenName) {
    const subject = "We've received your kitchen verification request!";
    const html = `
        <div style="
            font-family: Arial, sans-serif;
            background: #f6f5ff;
            padding: 20px;
            border-radius: 10px;
        ">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;
                box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                
                <h2 style="color:#FF6B35;text-align:center;margin-bottom:10px;">
                    Verification Request Received! ✅
                </h2>

                <p style="font-size:16px;color:#333;">
                    Hi <strong>${kitchenName}</strong>,
                </p>

                <p style="font-size:16px;color:#333;">
                    Thank you for submitting your kitchen details at <strong style="color:#FF6B35;">ResQBox Food</strong> for verification.
                </p>

                <div style="
                    background: #fff8f0;
                    border-left: 4px solid #FF6B35;
                    padding: 15px;
                    margin: 20px 0;
                    border-radius: 4px;
                ">
                    <strong style="color:#FF6B35;">📋 What's next?</strong><br>
                    <span style="color:#555;">The ResQBox Food Support team is currently reviewing your information. You can expect a status update within <strong>48 hours</strong>.</span>
                </div>

                <p style="font-size:16px;color:#333;">
                    Once verified, you'll be ready to start sharing meals with the community! 🌱
                </p>

                <p style="font-size:16px;color:#333;">
                    If you have any questions in the meantime, feel free to reach out to us at <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;text-decoration:none;font-weight:bold;">support@resqboxfood.com</a>.
                </p>

                <p style="margin-top:25px;color:#333;">
                    Best regards,<br>
                    <strong style="color:#FF6B35;">The ResQBox Food Team</strong>
                </p>

                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">
                        © ${new Date().getFullYear()} ResQBox Food. All rights reserved.
                    </p>
                    <p style="font-size:12px;color:#999;">
                        Contact us at <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;">support@resqboxfood.com</a>
                    </p>
                </div>
            </div>
        </div>
    `;

    return await sendEmail({ to: email, subject, html });
}

/**
 * Send certificate expiry warning email (30 days)
 * @param {string} email - Kitchen email
 * @param {string} kitchenName - Kitchen name
 * @param {string} expiryDate - Certificate expiry date
 */
async function sendCertificateExpiry30DayWarning(email, kitchenName, expiryDate) {
    const subject = 'Important: Your Food Certificate is expiring in 30 days';
    const html = `
        <div style="font-family: Arial, sans-serif; background: #f6f5ff; padding: 20px; border-radius: 10px;">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                <h2 style="color:#FF6B35;text-align:center;margin-bottom:10px;">Certificate Expiring Soon</h2>
                <p style="font-size:16px;color:#333;">Hi <strong>${kitchenName}</strong>,</p>
                <p style="font-size:16px;color:#333;">This is a friendly reminder that your Food Safety Certificate on file is set to expire in <strong style="color:#FF6B35;">30 days</strong> on ${expiryDate}.</p>
                <div style="background: #fff8f0; border-left: 4px solid #FF6B35; padding: 15px; margin: 20px 0; border-radius: 4px;">
                    <strong style="color:#FF6B35;">📋 Action Required:</strong><br>
                    <span style="color:#555;">To ensure there is no interruption to your service on ResQBox Food, please upload your renewed certificate through your dashboard as soon as possible.</span>
                </div>
                <p style="font-size:16px;color:#333;">If you have already renewed it, please ignore this message. For any help, contact us at <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;text-decoration:none;font-weight:bold;">support@resqboxfood.com</a>.</p>
                <p style="margin-top:25px;color:#333;">Best regards,<br><strong style="color:#FF6B35;">The ResQBox Food Team</strong></p>
                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">© ${new Date().getFullYear()} ResQBox Food. All rights reserved.</p>
                </div>
            </div>
        </div>
    `;
    return await sendEmail({ to: email, subject, html });
}

/**
 * Send certificate expiry warning email (7 days)
 * @param {string} email - Kitchen email
 * @param {string} kitchenName - Kitchen name
 * @param {string} expiryDate - Certificate expiry date
 */
async function sendCertificateExpiry7DayWarning(email, kitchenName, expiryDate) {
    const subject = 'Action Required: 7 days until certificate expiration ⚠️';
    const html = `
        <div style="font-family: Arial, sans-serif; background: #f6f5ff; padding: 20px; border-radius: 10px;">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                <h2 style="color:#FF6B35;text-align:center;margin-bottom:10px;">⚠️ Urgent: Certificate Expiring Soon</h2>
                <p style="font-size:16px;color:#333;">Hi <strong>${kitchenName}</strong>,</p>
                <p style="font-size:16px;color:#333;">Your food certificate will expire in <strong style="color:#FF6B35;">7 days</strong> on ${expiryDate}.</p>
                <div style="background: #fff3cd; border-left: 4px solid #FF6B35; padding: 15px; margin: 20px 0; border-radius: 4px;">
                    <strong style="color:#856404;">⚠️ Action Required Today:</strong><br>
                    <span style="color:#856404;">Please update your documentation today to keep your kitchen active on our platform. Failure to provide a valid certificate will result in a temporary suspension of your account until the documents are verified.</span>
                </div>
                <p style="margin-top:25px;color:#333;">Best regards,<br><strong style="color:#FF6B35;">The ResQBox Food Team</strong></p>
                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">© ${new Date().getFullYear()} ResQBox Food. All rights reserved.</p>
                </div>
            </div>
        </div>
    `;
    return await sendEmail({ to: email, subject, html });
}

/**
 * Send certificate expiry warning email (3 days)
 * @param {string} email - Kitchen email
 * @param {string} kitchenName - Kitchen name
 * @param {string} expiryDate - Certificate expiry date
 */
async function sendCertificateExpiry3DayWarning(email, kitchenName, expiryDate) {
    const subject = 'Final Reminder: Your certificate expires in 3 Days';
    const html = `
        <div style="font-family: Arial, sans-serif; background: #f6f5ff; padding: 20px; border-radius: 10px;">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                <h2 style="color:#f44336;text-align:center;margin-bottom:10px;">🚨 Final Reminder</h2>
                <p style="font-size:16px;color:#333;">Hi <strong>${kitchenName}</strong>,</p>
                <p style="font-size:16px;color:#333;">Your Food Safety Certificate is about to expire in <strong style="color:#f44336;">3 days</strong> on ${expiryDate}. To continue receiving orders and serving customers, we need your updated certificate within the next 3 days.</p>
                <div style="background: #ffebee; border-left: 4px solid #f44336; padding: 15px; margin: 20px 0; border-radius: 4px;">
                    <strong style="color:#c62828;">⚠️ Important:</strong><br>
                    <span style="color:#c62828;">If your account expires, your listings will be hidden from the app.</span>
                </div>
                <p style="font-size:16px;color:#333;">Please reach out to <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;text-decoration:none;font-weight:bold;">support@resqboxfood.com</a> immediately if you are experiencing delays with your renewal.</p>
                <p style="margin-top:25px;color:#333;">Best regards,<br><strong style="color:#FF6B35;">The ResQBox Food Team</strong></p>
                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">© ${new Date().getFullYear()} ResQBox Food. All rights reserved.</p>
                </div>
            </div>
        </div>
    `;
    return await sendEmail({ to: email, subject, html });
}

/**
 * Send certificate expiry warning email (2 days)
 * @param {string} email - Kitchen email
 * @param {string} kitchenName - Kitchen name
 * @param {string} expiryDate - Certificate expiry date
 */
async function sendCertificateExpiry2DayWarning(email, kitchenName, expiryDate) {
    const subject = 'Final Reminder: Your certificate expires in 2 Days';
    const html = `
        <div style="font-family: Arial, sans-serif; background: #f6f5ff; padding: 20px; border-radius: 10px;">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                <h2 style="color:#f44336;text-align:center;margin-bottom:10px;">🚨 Final Reminder</h2>
                <p style="font-size:16px;color:#333;">Hi <strong>${kitchenName}</strong>,</p>
                <p style="font-size:16px;color:#333;">Your Food Safety Certificate is about to expire in <strong style="color:#f44336;">2 days</strong> on ${expiryDate}. To continue receiving orders and serving customers, we need your updated certificate within the next 2 days.</p>
                <div style="background: #ffebee; border-left: 4px solid #f44336; padding: 15px; margin: 20px 0; border-radius: 4px;">
                    <strong style="color:#c62828;">⚠️ Important:</strong><br>
                    <span style="color:#c62828;">If your account expires, your listings will be hidden from the app.</span>
                </div>
                <p style="font-size:16px;color:#333;">Please reach out to <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;text-decoration:none;font-weight:bold;">support@resqboxfood.com</a> immediately if you are experiencing delays with your renewal.</p>
                <p style="margin-top:25px;color:#333;">Best regards,<br><strong style="color:#FF6B35;">The ResQBox Food Team</strong></p>
                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">© ${new Date().getFullYear()} ResQBox Food. All rights reserved.</p>
                </div>
            </div>
        </div>
    `;
    return await sendEmail({ to: email, subject, html });
}

/**
 * Send certificate expiry warning email (1 day)
 * @param {string} email - Kitchen email
 * @param {string} kitchenName - Kitchen name
 * @param {string} expiryDate - Certificate expiry date
 */
async function sendCertificateExpiry1DayWarning(email, kitchenName, expiryDate) {
    const subject = 'URGENT: Your certificate expires tomorrow 🚨';
    const html = `
        <div style="font-family: Arial, sans-serif; background: #f6f5ff; padding: 20px; border-radius: 10px;">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                <h2 style="color:#d32f2f;text-align:center;margin-bottom:10px;">🚨 URGENT: Final Notice</h2>
                <p style="font-size:16px;color:#333;">Hi <strong>${kitchenName}</strong>,</p>
                <p style="font-size:16px;color:#333;">This is your final notice. Your food certificate expires <strong style="color:#d32f2f;">tomorrow</strong> on ${expiryDate}.</p>
                <div style="background: #ffcdd2; border-left: 4px solid #d32f2f; padding: 15px; margin: 20px 0; border-radius: 4px;">
                    <strong style="color:#b71c1c;">🚨 Immediate Action Required:</strong><br>
                    <span style="color:#b71c1c;">To avoid your account being deactivated and your kitchen removed from the ResQBox map, please upload your latest certificate immediately.</span>
                </div>
                <p style="font-size:16px;color:#333;">Please reach out to <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;text-decoration:none;font-weight:bold;">support@resqboxfood.com</a> immediately if you are experiencing delays with your renewal.</p>
                <p style="margin-top:25px;color:#333;">Best regards,<br><strong style="color:#FF6B35;">The ResQBox Food Team</strong></p>
                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">© ${new Date().getFullYear()} ResQBox Food. All rights reserved.</p>
                </div>
            </div>
        </div>
    `;
    return await sendEmail({ to: email, subject, html });
}

/**
 * Send certificate expired notification
 * @param {string} email - Kitchen email
 * @param {string} kitchenName - Kitchen name
 */
async function sendCertificateExpiredNotification(email, kitchenName) {
    const subject = 'Your account has been suspended due to certificate expiration';
    const html = `
        <div style="font-family: Arial, sans-serif; background: #f6f5ff; padding: 20px; border-radius: 10px;">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                <h2 style="color:#d32f2f;text-align:center;margin-bottom:10px;">Account Suspended</h2>
                <p style="font-size:16px;color:#333;">Hi <strong>${kitchenName}</strong>,</p>
                <p style="font-size:16px;color:#333;">As of today, your Food Safety Certificate has expired. For the safety of our community, your account has been temporarily deactivated.</p>
                <div style="background: #ffebee; border-left: 4px solid #d32f2f; padding: 15px; margin: 20px 0; border-radius: 4px;">
                    <strong style="color:#c62828;">⚠️ Account Status:</strong><br>
                    <span style="color:#c62828;">You will not be able to accept new orders until a valid certificate is uploaded and verified by our team.</span>
                </div>
                <p style="font-size:16px;color:#333;">You are welcome to re-submit your details once the above requirements are met. If you have questions, please contact us at <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;text-decoration:none;font-weight:bold;">support@resqboxfood.com</a>.</p>
                <p style="margin-top:25px;color:#333;">Best regards,<br><strong style="color:#FF6B35;">The ResQBox Food Team</strong></p>
                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">© ${new Date().getFullYear()} ResQBox Food. All rights reserved.</p>
                </div>
            </div>
        </div>
    `;
    return await sendEmail({ to: email, subject, html });
}

/**
 * Send OTP email for user signup
 * @param {string} email - User email
 * @param {string} otp - OTP code
 */
async function sendUserSignupOTP(email, otp) {
    const subject = 'Verify Your Email - ResQBox Food';
    const html = `
        <div style="font-family: Arial, sans-serif; background: #f6f5ff; padding: 20px; border-radius: 10px;">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                <h2 style="color:#FF6B35;text-align:center;margin-bottom:10px;">Welcome to ResQBox Food! 🥗</h2>
                <p style="font-size:16px;color:#333;">Hello,</p>
                <p style="font-size:16px;color:#333;">Thank you for signing up! Please use the OTP below to verify your account.</p>
                <div style="margin: 25px auto; width: fit-content; background: linear-gradient(135deg, #FF6B35 0%, #4CAF50 100%); padding: 14px 28px; border-radius: 12px; color: white; font-size: 26px; font-weight: bold; letter-spacing: 6px; text-align: center;">
                    ${otp}
                </div>
                <p style="font-size:14px;color:#777;margin-top:25px;">If you did not request this, you can safely ignore this email.</p>
                <p style="margin-top:25px;color:#333;">Regards,<br><strong style="color:#FF6B35;">ResQBox Food Team</strong></p>
                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">© ${new Date().getFullYear()} ResQBox Food. All rights reserved.</p>
                </div>
            </div>
        </div>
    `;
    return await sendEmail({ to: email, subject, html });
}

/**
 * Send OTP email for user login
 * @param {string} email - User email
 * @param {string} otp - OTP code
 */
async function sendUserLoginOTP(email, otp) {
    const subject = 'Your Login OTP - ResQBox Food';
    const html = `
        <div style="font-family: Arial, sans-serif; background: #f6f5ff; padding: 20px; border-radius: 10px;">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                <h2 style="color:#FF6B35;text-align:center;margin-bottom:10px;">Login to ResQBox Food</h2>
                <p style="font-size:16px;color:#333;">Hello,</p>
                <p style="font-size:16px;color:#333;">Please use the OTP below to log in to your account.</p>
                <div style="margin: 25px auto; width: fit-content; background: linear-gradient(135deg, #FF6B35 0%, #4CAF50 100%); padding: 14px 28px; border-radius: 12px; color: white; font-size: 26px; font-weight: bold; letter-spacing: 6px; text-align: center;">
                    ${otp}
                </div>
                <p style="font-size:14px;color:#777;margin-top:25px;">If you did not request this, please secure your account immediately.</p>
                <p style="margin-top:25px;color:#333;">Regards,<br><strong style="color:#FF6B35;">ResQBox Food Team</strong></p>
                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">© ${new Date().getFullYear()} ResQBox Food. All rights reserved.</p>
                </div>
            </div>
        </div>
    `;
    return await sendEmail({ to: email, subject, html });
}

/**
 * Send account inactive notification email (Initial + 30-day reminder)
 * Sent when an admin marks a user account as Inactive.
 * @param {string} email - User email
 * @param {string} userName - User's name
 * @param {string} reasonCategory - e.g. "Policy Violation"
 * @param {string} reasonDescription - Detailed description of why account was marked inactive
 */
async function sendUserAccountInactiveEmail(email, userName, reasonCategory, reasonDescription) {
    const subject = 'Important: Your ResQBox Food account is now Inactive';
    const html = `
        <div style="font-family: Arial, sans-serif; background: #f6f5ff; padding: 20px; border-radius: 10px;">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;box-shadow:0 4px 12px rgba(0,0,0,0.08);">

                <h2 style="color:#e65100;text-align:center;margin-bottom:6px;">Your Account is Now Inactive</h2>
                <p style="text-align:center;color:#888;font-size:13px;margin-top:0;">ResQBox Food — Account Notice</p>

                <p style="font-size:16px;color:#333;line-height:1.6;">Hi <strong>${userName}</strong>,</p>

                <p style="font-size:16px;color:#333;line-height:1.6;">
                    We are writing to inform you that your ResQBox Food account has been marked as
                    <strong style="color:#e65100;">Inactive</strong>.
                </p>

                <div style="background:#fff8f0;border-left:4px solid #e65100;padding:16px 20px;margin:20px 0;border-radius:4px;">
                    <p style="margin:0 0 6px 0;font-size:14px;color:#999;text-transform:uppercase;letter-spacing:0.5px;">Reason Category</p>
                    <p style="margin:0 0 14px 0;font-size:16px;color:#333;font-weight:bold;">${reasonCategory || 'Not specified'}</p>
                    <p style="margin:0 0 6px 0;font-size:14px;color:#999;text-transform:uppercase;letter-spacing:0.5px;">Reason</p>
                    <p style="margin:0;font-size:15px;color:#555;line-height:1.5;">${reasonDescription || 'Please contact support for more details.'}</p>
                </div>

                <div style="background:#f1f8e9;border-left:4px solid #4CAF50;padding:16px 20px;margin:20px 0;border-radius:4px;">
                    <strong style="color:#2e7d32;">📅 What happens next?</strong><br>
                    <span style="color:#33691e;font-size:15px;line-height:1.6;">
                        If no action is taken, your account data will be permanently deleted in <strong>6 months</strong>.
                        If you believe this is a mistake or would like to reactivate your account,
                        please contact our support team at
                        <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;font-weight:bold;">support@resqboxfood.com</a>.
                    </span>
                </div>

                <p style="margin-top:30px;color:#333;font-size:15px;">
                    Regards,<br>
                    <strong style="color:#FF6B35;">The ResQBox Food Team</strong>
                </p>

                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">© ${new Date().getFullYear()} ResQBox Food. All rights reserved.</p>
                    <p style="font-size:12px;color:#999;">Contact us at <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;">support@resqboxfood.com</a></p>
                </div>
            </div>
        </div>
    `;
    return await sendEmail({ to: email, subject, html });
}

/**
 * Send deletion reminder email for both INACTIVE and user-DELETE flows
 * @param {string} email
 * @param {string} userName
 * @param {number|string} daysUntilDeletion - 7, 3, 2, 1, or 'today'
 * @param {string} requestType - 'INACTIVE' | 'DELETE'
 */
async function sendUserDeletionReminderEmail(email, userName, daysUntilDeletion, requestType = 'DELETE') {
    const isInactive = requestType === 'INACTIVE';
    const isFinalDay = daysUntilDeletion === 'today' || daysUntilDeletion === 0 || daysUntilDeletion === 1;
    const headerColor = isFinalDay ? '#d32f2f' : (daysUntilDeletion <= 3 ? '#e65100' : '#b45309');

    // ── INACTIVE flow copy ──────────────────────────────────────────
    // Subject: "Reminder: Your account data is scheduled for deletion in X days"
    // ── DELETE (user-requested) flow copy ───────────────────────────
    // Subject: "Reminder: X days until your account is deleted" (or Final Day)

    const subject = isInactive
        ? (isFinalDay
            ? 'Reminder: Your account data is scheduled for deletion today'
            : `Reminder: Your account data is scheduled for deletion in ${daysUntilDeletion} days`)
        : (isFinalDay
            ? 'Reminder of removal of account'
            : `Reminder: ${daysUntilDeletion} days until your account is deleted`);

    const bodyText = isInactive
        ? `This is a reminder that your inactive ResQBox Food account is scheduled for
           permanent data deletion in <strong style="color:${headerColor};">${isFinalDay ? 'today' : `${daysUntilDeletion} days`}</strong>.<br><br>
           Once deleted, your history, rewards, and profile settings <strong>cannot be recovered</strong>.
           To prevent this and reactivate your account, please reach out to our support team immediately at
           <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;font-weight:bold;">support@resqboxfood.com</a>.`
        : (isFinalDay
            ? `Your account data will be deleted from ResQBox Food!<br><br>
               Once this process is complete, we won't be able to recover your data.
               If you want to keep your account, this is your final chance: just log in once and we'll cancel the removal immediately.<br><br>
               If not, we wish you all the best. Thank you for the meals you've helped us save.`
            : `We're checking in one last time. In <strong style="color:${headerColor};">${daysUntilDeletion} days</strong>,
               your ResQBox Food account and all your saved data will be gone forever.<br><br>
               We'll miss seeing you rescue those surplus meals! If you've had a change of heart,
               just log in to the app today to stay part of the family.<br><br>
               Hope to see you back soon!`);

    const html = `
        <div style="font-family: Arial, sans-serif; background: #f6f5ff; padding: 20px; border-radius: 10px;">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;box-shadow:0 4px 12px rgba(0,0,0,0.08);">

                <div style="text-align:center;margin-bottom:20px;">
                    <div style="display:inline-block;background:${isFinalDay ? '#ffcdd2' : '#fff3cd'};border-radius:50%;width:60px;height:60px;line-height:60px;font-size:28px;">${isFinalDay ? '🚨' : '⏳'}</div>
                </div>

                <h2 style="color:${headerColor};text-align:center;margin-bottom:6px;">
                    ${isFinalDay ? (isInactive ? 'Account Deletion Today' : 'Reminder of removal of account') : `${daysUntilDeletion} days until deletion`}
                </h2>
                <p style="text-align:center;color:#888;font-size:13px;margin-top:0;">ResQBox Food</p>

                <p style="font-size:16px;color:#333;line-height:1.6;">Hi <strong>${userName}</strong>,</p>

                <p style="font-size:16px;color:#333;line-height:1.6;">${bodyText}</p>

                <p style="margin-top:30px;color:#333;font-size:15px;">
                    Warmly,<br>
                    <strong style="color:#FF6B35;">The ResQBox Team</strong>
                </p>

                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">© ${new Date().getFullYear()} ResQBox Food. All rights reserved.</p>
                    <p style="font-size:12px;color:#999;">Contact us at <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;">support@resqboxfood.com</a></p>
                </div>
            </div>
        </div>
    `;
    return await sendEmail({ to: email, subject, html });
}

/**
 * Send account deletion request confirmation email (Day 0)
 * Sent immediately when a user requests account deletion
 * @param {string} email - User email
 * @param {string} userName - User's name
 */
async function sendUserDeletionRequestEmail(email, userName) {
    const subject = "We're sorry to see you go...";
    const html = `
        <div style="font-family: Arial, sans-serif; background: #f6f5ff; padding: 20px; border-radius: 10px;">
            <div style="max-width:600px;margin:auto;background:#ffffff;padding:25px;border-radius:10px;box-shadow:0 4px 12px rgba(0,0,0,0.08);">

                <div style="text-align:center;margin-bottom:20px;">
                    <div style="display:inline-block;background:#fff3cd;border-radius:50%;width:60px;height:60px;line-height:60px;font-size:28px;">💚</div>
                </div>

                <h2 style="color:#FF6B35;text-align:center;margin-bottom:6px;">We're sorry to see you go...</h2>
                <p style="text-align:center;color:#888;font-size:13px;margin-top:0;">ResQBox Food</p>

                <p style="font-size:16px;color:#333;line-height:1.6;">Hi <strong>${userName}</strong>,</p>

                <p style="font-size:16px;color:#333;line-height:1.6;">
                    We've received your request to delete your ResQBox Food account.
                    To be honest, it hurts a little! We've loved having you as part of our mission
                    to rescue delicious food and reduce waste.
                </p>

                <div style="background:#f1f8e9;border-left:4px solid #4CAF50;padding:16px 20px;margin:20px 0;border-radius:4px;">
                    <strong style="color:#2e7d32;">💚 Changed your mind?</strong><br>
                    <span style="color:#33691e;font-size:15px;line-height:1.6;">
                        It's not too late! If you want to cancel this request and get back to rescuing meals,
                        simply <strong>log back into the app</strong> at any time.
                        Logging in will automatically cancel the deletion process.
                    </span>
                </div>

                <div style="background:#fff8f0;border-left:4px solid #FF6B35;padding:16px 20px;margin:20px 0;border-radius:4px;">
                    <strong style="color:#e65100;">⚠️ If you didn't request this:</strong><br>
                    <span style="color:#555;font-size:15px;line-height:1.6;">
                        Please contact our support team immediately at
                        <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;font-weight:bold;">support@resqboxfood.com</a>
                        to secure your account.
                    </span>
                </div>

                <p style="margin-top:30px;color:#333;font-size:15px;">
                    Warmly,<br>
                    <strong style="color:#FF6B35;">The ResQBox Team</strong>
                </p>

                <div style="text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #eee;">
                    <p style="font-size:12px;color:#999;">© ${new Date().getFullYear()} ResQBox Food. All rights reserved.</p>
                    <p style="font-size:12px;color:#999;">Contact us at <a href="mailto:support@resqboxfood.com" style="color:#FF6B35;">support@resqboxfood.com</a></p>
                </div>
            </div>
        </div>
    `;
    return await sendEmail({ to: email, subject, html });
}

module.exports = {
    sendEmail,
    sendKitchenApprovalEmail,
    sendKitchenRejectionEmail,
    sendAdminForgotPasswordOTP,
    sendUserWelcomeEmail,
    sendOrderCompletionEmail,
    sendKitchenVerificationReceivedEmail,
    sendCertificateExpiry30DayWarning,
    sendCertificateExpiry7DayWarning,
    sendCertificateExpiry3DayWarning,
    sendCertificateExpiry2DayWarning,
    sendCertificateExpiry1DayWarning,
    sendCertificateExpiredNotification,
    sendUserSignupOTP,
    sendUserLoginOTP,
    sendUserAccountInactiveEmail,
    sendUserDeletionReminderEmail,
    sendUserDeletionRequestEmail
};
