const PDFDocument = require("pdfkit");
const prisma = require("../utils/prisma");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const dotenv = require("dotenv");

dotenv.config();

// Initialize S3 Client
const s3 = new S3Client({
    region: process.env.AWS_REGION,
    credentials: {
        accessKeyId: process.env.AWS_ACCESSKEYID,
        secretAccessKey: process.env.AWS_SECRETACCESSKEY,
    },
});

/**
 * Generate next invoice number
 * Format: INV-YYYY-NNN (e.g., INV-2025-001)
 * Checks both payoutInvoice and monthlyInvoice tables to ensure uniqueness
 */
async function getNextInvoiceNumber(retryCount = 0, maxRetries = 5) {
    const currentYear = new Date().getFullYear();

    // Add random delay to reduce collision probability on retries
    if (retryCount > 0) {
        const delay = Math.floor(Math.random() * 100) + (retryCount * 50);
        await new Promise(resolve => setTimeout(resolve, delay));
    }

    try {
        // Get the latest invoice from both tables for this year
        const [latestPayoutInvoice, latestMonthlyInvoice] = await Promise.all([
            prisma.payoutInvoice.findFirst({
                where: {
                    invoiceNumber: {
                        startsWith: `INV-${currentYear}-`
                    }
                },
                orderBy: {
                    invoiceId: "desc"
                }
            }),
            prisma.monthlyInvoice.findFirst({
                where: {
                    invoiceNumber: {
                        startsWith: `INV-${currentYear}-`
                    }
                },
                orderBy: {
                    invoiceId: "desc"
                }
            })
        ]);

        // Extract numbers from both invoices
        let maxNumber = 0;

        if (latestPayoutInvoice) {
            const parts = latestPayoutInvoice.invoiceNumber.split("-");
            const num = parseInt(parts[2]) || 0;
            maxNumber = Math.max(maxNumber, num);
        }

        if (latestMonthlyInvoice) {
            const parts = latestMonthlyInvoice.invoiceNumber.split("-");
            const num = parseInt(parts[2]) || 0;
            maxNumber = Math.max(maxNumber, num);
        }

        const nextNumber = maxNumber + 1;
        return `INV-${currentYear}-${String(nextNumber).padStart(3, "0")}`;
    } catch (error) {
        if (error.code === 'P2002' && retryCount < maxRetries) {
            console.log(`⚠️  [Invoice] Collision detected, retrying... (attempt ${retryCount + 1}/${maxRetries})`);
            return getNextInvoiceNumber(retryCount + 1, maxRetries);
        }
        throw error;
    }
}

/**
 * Generate PDF invoice for kitchen payout and upload to S3
 */
async function generatePayoutInvoice(payoutData) {
    const {
        invoiceNumber,
        kitchen,
        restaurantCode,
        periodStart,
        periodEnd,
        totalCredits,
        platformFeesDeducted,
        serviceFeeAmount,
        serviceFeePercent,
        payoutAmount,
        orderCount,
        orders,
        stripeTransferId,
        createdAt
    } = payoutData;

    // 🐛 DEBUG: Log what the invoice generator received
    console.log("\n========== INVOICE GENERATOR RECEIVED ==========");
    console.log("totalCredits:", totalCredits);
    console.log("platformFeesDeducted:", platformFeesDeducted);
    console.log("payoutAmount:", payoutAmount);
    console.log("orderCount:", orderCount);
    console.log("\n🔍 KITCHEN OBJECT DEBUG:");
    console.log("kitchen:", JSON.stringify(kitchen, null, 2));
    console.log("\n🔍 KYC DATA:");
    console.log("kitchen.kyc:", kitchen.kyc);
    console.log("kitchen.kyc?.abnNumber:", kitchen.kyc?.abnNumber);
    console.log("================================================\n");

    const isMonthly = payoutData.isMonthly || false;
    const title = isMonthly ? "MONTHLY SUMMARY INVOICE" : "PAYOUT INVOICE";
    const subTitle = isMonthly ? "Monthly Performance Summary" : "Kitchen Payout Service";
    const periodLabel = isMonthly ? "Invoice Period:" : "Payout Period:";
    const totalLabel = isMonthly ? "Total Summary" : "Total Payout";

    const datetime = Date.now();
    const fileName = `${invoiceNumber}-${datetime}.pdf`;

    return new Promise((resolve, reject) => {
        try {
            const doc = new PDFDocument({ margin: 50 });

            // Collect PDF data in memory
            const chunks = [];
            doc.on('data', (chunk) => chunks.push(chunk));
            doc.on('end', async () => {
                try {
                    // Combine all chunks into a single buffer
                    const pdfBuffer = Buffer.concat(chunks);

                    // Upload to S3
                    const s3Key = `invoices/${fileName}`;
                    const uploadParams = {
                        Bucket: process.env.AWS_BUCKET_NAME,
                        Key: s3Key,
                        Body: pdfBuffer,
                        ContentType: 'application/pdf',
                    };

                    const command = new PutObjectCommand(uploadParams);
                    await s3.send(command);

                    // Return CloudFront URL
                    const pdfUrl = `https://d19qgxevt3ep10.cloudfront.net/${s3Key}`;

                    resolve({
                        fileName,
                        pdfUrl
                    });
                } catch (uploadError) {
                    console.error("S3 upload error:", uploadError);
                    reject(uploadError);
                }
            });

            doc.on('error', reject);

            // Header
            doc
                .fontSize(20)
                .font("Helvetica-Bold")
                .text(title, { align: "center" })
                .moveDown();

            // Company Info
            doc
                .fontSize(10)
                .font("Helvetica")
                .text("ResQBox Food Platform", { align: "center" })
                .text(subTitle, { align: "center" })
                .moveDown(2);

            const formatDate = (date) => {
                const d = new Date(date);
                return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`;
            };

            // Invoice Details Box
            doc
                .fontSize(12)
                .font("Helvetica-Bold")
                .text(`Invoice Number: ${invoiceNumber}`, 50, 150)
                .font("Helvetica")
                .fontSize(10)
                .text(`Date: ${formatDate(createdAt)}`, 50, 170)
                .moveDown();

            // Restaurant Details
            doc
                .fontSize(12)
                .font("Helvetica-Bold")
                .text("Restaurant Details:", 50, 200)
                .fontSize(10)
                .font("Helvetica")
                .text(`Restaurant Code: ${restaurantCode}`, 50, 220)
                .text(`Restaurant Name: ${kitchen.kitchenName}`, 50, 235);

            // ABN with better handling
            const abnNumber = kitchen.kyc?.abnNumber || kitchen.kyc?.acn || "ABN not provided";
            console.log("🔍 ABN Display Value:", abnNumber);

            doc.text(`ABN: ${abnNumber}`, 50, 250)
                .text(
                    `Address: ${kitchen.address?.street || ""}, ${kitchen.address?.city || ""}, ${kitchen.address?.state || ""} ${kitchen.address?.pincode || ""}`,
                    50,
                    265,
                    { width: 500 }
                )
                .moveDown(2);

            // Payout Period
            doc
                .fontSize(12)
                .font("Helvetica-Bold")
                .text(periodLabel, 50, 305)
                .fontSize(10)
                .font("Helvetica")
                .text(
                    `From: ${formatDate(periodStart)} To: ${formatDate(periodEnd)}`,
                    50,
                    325
                )
                .moveDown(2);

            // Line separator
            doc
                .moveTo(50, 355)
                .lineTo(550, 355)
                .stroke();

            // ========================================
            // PAYOUT BREAKDOWN TABLE (MOVED TO TOP)
            // ========================================
            let yPosition = 375;

            const GST_RATE = 0.10; // 10% GST

            // 🛑 NEW LOGIC: Remove platform fee from Listed Price total first
            const listedPriceTotal = totalCredits - platformFeesDeducted;

            // ⭐ INCLUSIVE GST MATH: Total = Net + GST (where GST is 10% of Net)
            // T = Net * 1.1 => Net = T / 1.1
            const listedPriceNet = Number((listedPriceTotal / (1 + GST_RATE)).toFixed(2));
            const listedPriceGST = Number((listedPriceTotal - listedPriceNet).toFixed(2));

            // Service Fee breakdown (if exists)
            let serviceFeeGST = 0;
            let serviceFeeNet = 0;
            let serviceFeeTotal = 0;
            if (serviceFeeAmount && serviceFeeAmount > 0) {
                serviceFeeTotal = serviceFeeAmount;
                serviceFeeNet = Number((serviceFeeTotal / (1 + GST_RATE)).toFixed(2));
                serviceFeeGST = Number((serviceFeeTotal - serviceFeeNet).toFixed(2));
            }

            // Total Payout breakdown
            const totalPayoutTotal = Math.max(0, listedPriceTotal - serviceFeeTotal);
            const totalPayoutNet = Number((totalPayoutTotal / (1 + GST_RATE)).toFixed(2));
            const totalPayoutGST = Number((totalPayoutTotal - totalPayoutNet).toFixed(2));

            // Table Header with Background
            const tableHeaderColor = "#f0f0f0";
            doc
                .rect(50, yPosition - 5, 500, 25)
                .fill(tableHeaderColor)
                .stroke();

            doc
                .fillColor("#000000")
                .fontSize(10)
                .font("Helvetica-Bold")
                .text("Description", 60, yPosition + 5)
                .text("GST (10%)", 250, yPosition + 5, { width: 80, align: "right" })
                .text("Net Amount", 340, yPosition + 5, { width: 100, align: "right" })
                .text("Total", 450, yPosition + 5, { width: 90, align: "right" });

            yPosition += 20;

            // Draw vertical lines for the table
            const tableTop = yPosition - 25;
            let tableBottom = yPosition + 5; // Will update as we add rows

            // Helper to draw rows with borders
            const drawRow = (label, gst, net, total, isBold = false) => {
                const h = 20;
                doc.rect(50, yPosition, 500, h).stroke();

                // Draw vertical separators
                doc.moveTo(240, yPosition).lineTo(240, yPosition + h).stroke();
                doc.moveTo(335, yPosition).lineTo(335, yPosition + h).stroke();
                doc.moveTo(445, yPosition).lineTo(445, yPosition + h).stroke();

                const formatCurrency = (val) => {
                    const absVal = Math.abs(val).toFixed(2);
                    return val < 0 ? `-$${absVal}` : `$${absVal}`;
                };

                doc
                    .font(isBold ? "Helvetica-Bold" : "Helvetica")
                    .fontSize(9)
                    .text(label, 60, yPosition + 6)
                    .text(formatCurrency(gst), 250, yPosition + 6, { width: 80, align: "right" })
                    .text(formatCurrency(net), 340, yPosition + 6, { width: 100, align: "right" })
                    .text(formatCurrency(total), 450, yPosition + 6, { width: 90, align: "right" });

                yPosition += h;
            };

            yPosition += 5; // Gap from header
            drawRow("Listed Price", listedPriceGST, listedPriceNet, listedPriceTotal);

            if (serviceFeeAmount && serviceFeeAmount > 0) {
                drawRow(`Service Fee (${serviceFeePercent}%)`, -serviceFeeGST, -serviceFeeNet, -serviceFeeTotal);
            }

            yPosition += 10;
            drawRow(totalLabel, totalPayoutGST, totalPayoutNet, totalPayoutTotal, true);

            // Order details table removed as requested

            // ========================================
            // ORDER DETAILS TABLE
            // ========================================
            if (orders && orders.length > 0) {
                yPosition += 20;

                // Section heading
                doc
                    .fontSize(11)
                    .font("Helvetica-Bold")
                    .fillColor("#000000")
                    .text("Order Details:", 50, yPosition);

                yPosition += 20;

                // Table column widths & x positions
                const COL = {
                    orderId: { x: 50, w: 110 },
                    items: { x: 160, w: 60 },
                    amount: { x: 220, w: 110 },
                    status: { x: 330, w: 100 },
                    date: { x: 430, w: 120 }
                };
                const ROW_H = 18;

                // Helper to draw vertical lines
                const drawTableLines = (y, h) => {
                    [COL.items.x, COL.amount.x, COL.status.x, COL.date.x].forEach(x => {
                        doc.moveTo(x, y).lineTo(x, y + h).stroke();
                    });
                };

                // Header row
                doc.rect(50, yPosition, 500, ROW_H).fill("#f0f0f0").stroke();
                drawTableLines(yPosition, ROW_H); // Draw lines for header

                doc
                    .fillColor("#000000")
                    .fontSize(8)
                    .font("Helvetica-Bold")
                    .text("Order ID", COL.orderId.x + 4, yPosition + 5, { width: COL.orderId.w - 8, align: "left" })
                    .text("Items", COL.items.x + 4, yPosition + 5, { width: COL.items.w - 8, align: "center" })
                    .text("Amount", COL.amount.x + 4, yPosition + 5, { width: COL.amount.w - 8, align: "right" })
                    .text("Status", COL.status.x + 4, yPosition + 5, { width: COL.status.w - 8, align: "center" })
                    .text("Date", COL.date.x + 4, yPosition + 5, { width: COL.date.w - 8, align: "center" });

                yPosition += ROW_H;

                // Data rows
                orders.forEach((order, idx) => {
                    // Add new page if we're running out of space
                    if (yPosition + ROW_H > doc.page.height - 120) {
                        doc.addPage();
                        yPosition = 50;

                        // Redraw header on new page if needed (Optional but better)
                        doc.rect(50, yPosition, 500, ROW_H).fill("#f0f0f0").stroke();
                        drawTableLines(yPosition, ROW_H);
                        doc.fillColor("#000000").font("Helvetica-Bold")
                            .text("Order ID", COL.orderId.x + 4, yPosition + 5, { width: COL.orderId.w - 8, align: "left" })
                            .text("Items", COL.items.x + 4, yPosition + 5, { width: COL.items.w - 8, align: "center" })
                            .text("Amount", COL.amount.x + 4, yPosition + 5, { width: COL.amount.w - 8, align: "right" })
                            .text("Status", COL.status.x + 4, yPosition + 5, { width: COL.status.w - 8, align: "center" })
                            .text("Date", COL.date.x + 4, yPosition + 5, { width: COL.date.w - 8, align: "center" });
                        yPosition += ROW_H;
                    }

                    // Alternating row background
                    doc.font("Helvetica");
                    if (idx % 2 === 0) {
                        doc.rect(50, yPosition, 500, ROW_H).fill("#fafafa").stroke();
                    } else {
                        doc.rect(50, yPosition, 500, ROW_H).stroke();
                    }

                    // Vertical separators for value row
                    drawTableLines(yPosition, ROW_H);

                    const orderDate = formatDate(order.orderedAt);
                    const orderAmount = `$${Number(order.totalAmount).toFixed(2)}`;

                    doc
                        .fillColor("#000000")
                        .fontSize(8)
                        .text(order.orderDisplayId || String(order.orderId), COL.orderId.x + 4, yPosition + 5, { width: COL.orderId.w - 8, align: "left" })
                        .text(String(order.numberOfItems || 1), COL.items.x + 4, yPosition + 5, { width: COL.items.w - 8, align: "center" })
                        .text(orderAmount, COL.amount.x + 4, yPosition + 5, { width: COL.amount.w - 8, align: "right" })
                        .text(order.status, COL.status.x + 4, yPosition + 5, { width: COL.status.w - 8, align: "center" })
                        .text(orderDate, COL.date.x + 4, yPosition + 5, { width: COL.date.w - 8, align: "center" });

                    yPosition += ROW_H;
                });

                yPosition += 10; // gap after table
            }

            yPosition += 20; // Space


            yPosition += 40; // Add spacing

            // Footer - Check if there's enough space, otherwise add new page
            const footerHeight = 120; // Height needed for footer
            const footerStartPosition = doc.page.height - 100;

            // If current content would overlap with footer, add new page
            if (yPosition + footerHeight > footerStartPosition) {
                doc.addPage();
                yPosition = doc.page.height - 100; // Position footer at bottom of new page
            } else {
                yPosition = footerStartPosition; // Use bottom of current page
            }

            doc
                .fontSize(9)
                .font("Helvetica-Bold")
                .text(
                    "Thank you for choosing ResQBox Food!",
                    50,
                    yPosition,
                    { align: "center", width: 500 }
                )
                .fontSize(8)
                .font("Helvetica")
                .text(
                    "Together we're reducing food waste and supporting local restaurants.",
                    50,
                    yPosition + 15,
                    { align: "center", width: 500 }
                )
                .text(
                    "This is a computer-generated receipt and does not require a signature.",
                    50,
                    yPosition + 35,
                    { align: "center", width: 500 }
                );

            // Finalize PDF
            doc.end();
        } catch (error) {
            reject(error);
        }
    });
}

/**
 * Generate next order invoice number with retry logic to handle concurrent requests
 * Format: ORD-YYYY-NNNNNN (e.g., ORD-2026-000001)
 */
async function getNextOrderInvoiceNumber(retryCount = 0, maxRetries = 5) {
    const currentYear = new Date().getFullYear();

    // Add random delay to reduce collision probability (0-100ms)
    if (retryCount > 0) {
        const delay = Math.floor(Math.random() * 100) + (retryCount * 50);
        await new Promise(resolve => setTimeout(resolve, delay));
    }

    try {
        // Use a transaction to ensure atomicity
        const result = await prisma.$transaction(async (tx) => {
            const latestInvoice = await tx.orderInvoice.findFirst({
                where: {
                    invoiceNumber: {
                        startsWith: `ORD-${currentYear}-`
                    }
                },
                orderBy: {
                    invoiceId: "desc"
                }
            });

            let nextNumber = 1;

            if (latestInvoice) {
                const parts = latestInvoice.invoiceNumber.split("-");
                nextNumber = (parseInt(parts[2]) || 0) + 1;
            }

            return `ORD-${currentYear}-${String(nextNumber).padStart(6, "0")}`;
        });

        return result;
    } catch (error) {
        // If we hit a unique constraint error and haven't exceeded retries, try again
        if (error.code === 'P2002' && retryCount < maxRetries) {
            console.log(`⚠️  [Invoice] Collision detected, retrying... (attempt ${retryCount + 1}/${maxRetries})`);
            return getNextOrderInvoiceNumber(retryCount + 1, maxRetries);
        }
        throw error;
    }
}


/**
 * Generate PDF invoice for customer order (similar to Swiggy invoice)
 */
async function generateOrderInvoice(orderData) {
    const {
        invoiceNumber,
        order,
        customer,
        restaurant,
        orderItems,
        createdAt
    } = orderData;

    const datetime = Date.now();
    const fileName = `${invoiceNumber}-${datetime}.pdf`;

    return new Promise((resolve, reject) => {
        try {
            const doc = new PDFDocument({ margin: 50, size: 'A4' });

            // Collect PDF data in memory
            const chunks = [];
            doc.on('data', (chunk) => chunks.push(chunk));
            doc.on('end', async () => {
                try {
                    const pdfBuffer = Buffer.concat(chunks);

                    // Upload to S3
                    const s3Key = `order-invoices/${fileName}`;
                    const uploadParams = {
                        Bucket: process.env.AWS_BUCKET_NAME,
                        Key: s3Key,
                        Body: pdfBuffer,
                        ContentType: 'application/pdf',
                    };

                    const command = new PutObjectCommand(uploadParams);
                    await s3.send(command);

                    const pdfUrl = `https://d19qgxevt3ep10.cloudfront.net/${s3Key}`;

                    resolve({
                        fileName,
                        pdfUrl
                    });
                } catch (uploadError) {
                    console.error("S3 upload error:", uploadError);
                    reject(uploadError);
                }
            });

            doc.on('error', reject);

            const formatDate = (date) => {
                const d = new Date(date);
                return `${String(d.getDate()).padStart(2, '0')}-${String(d.getMonth() + 1).padStart(2, '0')}-${d.getFullYear()}`;
            };

            const formatCurrency = (amount) => {
                return `$${Number(amount).toFixed(2)}`;
            };

            // ========================================
            // HEADER - Platform Logo/Name
            // ========================================
            doc
                .fontSize(24)
                .font("Helvetica-Bold")
                .fillColor("#FF6B35")
                .text("ResQBox Food", { align: "center" })
                .moveDown(0.5);

            // Horizontal line separator
            doc
                .moveTo(50, doc.y)
                .lineTo(550, doc.y)
                .stroke()
                .moveDown(0.5);

            // ========================================
            // TAX INVOICE TITLE WITH RESTAURANT INFO
            // ========================================
            const titleY = doc.y;

            doc
                .fontSize(18)
                .font("Helvetica-Bold")
                .fillColor("#000000")
                .text("TAX INVOICE", 50, titleY, { width: 250 });

            // Restaurant info on same line as TAX INVOICE
            doc
                .fontSize(8)
                .font("Helvetica-Bold")
                .text("Invoice issued by Nousattva Pty Ltd on behalf of:", 320, titleY, { width: 230 });

            doc.moveDown(2);

            // ========================================
            // TWO COLUMN LAYOUT: Customer & Restaurant
            // ========================================
            let yPos = doc.y;

            // LEFT COLUMN - Customer Details
            doc
                .fontSize(10)
                .font("Helvetica-Bold")
                .text("Invoice To:", 50, yPos);

            yPos += 15;
            doc
                .fontSize(9)
                .font("Helvetica")
                .text(customer.name || "Customer", 50, yPos);

            yPos += 30;
            const orderDisplayId = "OD" + String(order.orderNumber);

            const leftLabelX = 50;
            const leftValueX = 150;

            doc
                .font("Helvetica-Bold")
                .text("Order ID:", leftLabelX, yPos);
            doc
                .font("Helvetica")
                .text(orderDisplayId, leftValueX, yPos);

            // Invoice Metadata (moved here)
            yPos += 20;
            doc
                .fontSize(9)
                .font("Helvetica-Bold")
                .text("Document:", leftLabelX, yPos);
            doc
                .font("Helvetica")
                .text("INV", leftValueX, yPos);

            yPos += 15;
            doc
                .font("Helvetica-Bold")
                .text("Invoice No:", leftLabelX, yPos);
            doc
                .font("Helvetica")
                .text(invoiceNumber, leftValueX, yPos);

            yPos += 15;
            doc
                .font("Helvetica-Bold")
                .text("Date of Invoice:", leftLabelX, yPos);
            doc
                .font("Helvetica")
                .text(formatDate(createdAt), leftValueX, yPos);


            // RIGHT COLUMN - Restaurant Details (Clean Aligned Layout)
            let rightYPos = titleY + 20;

            const labelX = 320;
            const valueX = 440;

            rightYPos += 10;

            // Restaurant Name
            doc
                .fontSize(8)
                .font("Helvetica-Bold")
                .text("Restaurant Name:", labelX, rightYPos);
            doc
                .font("Helvetica")
                .text(restaurant.name, valueX, rightYPos, { width: 110 });

            rightYPos += 15;

            // ABN
            doc
                .font("Helvetica-Bold")
                .text("ABN:", labelX, rightYPos);
            doc
                .font("Helvetica")
                .text(restaurant.gstin || "N/A", valueX, rightYPos);

            rightYPos += 15;

            // Address
            doc
                .font("Helvetica-Bold")
                .text("Address:", labelX, rightYPos);
            const addressHeight = doc.heightOfString(restaurant.address || "N/A", { width: 110 });
            doc
                .font("Helvetica")
                .text(restaurant.address || "N/A", valueX, rightYPos, { width: 110 });

            rightYPos += Math.max(15, addressHeight + 5);

            // State
            doc
                .font("Helvetica-Bold")
                .text("State:", labelX, rightYPos);
            doc
                .font("Helvetica")
                .text(restaurant.state || "N/A", valueX, rightYPos);

            rightYPos += 15;

            // Place of Supply
            doc
                .font("Helvetica-Bold")
                .text("Place of Supply:", labelX, rightYPos);
            doc
                .font("Helvetica")
                .text(restaurant.state || "N/A", valueX, rightYPos);

            rightYPos += 15;

            // Service Description
            doc
                .font("Helvetica-Bold")
                .text("Service Description:", labelX, rightYPos);
            doc
                .font("Helvetica")
                .text("Restaurant Service", valueX, rightYPos);


            // Category and Reverse Charges fields removed


            // ========================================
            // ORDER ITEMS TABLE
            // ========================================
            yPos = Math.max(yPos, rightYPos) + 30;

            // Table Header
            const tableTop = yPos;
            const tableHeaderBg = "#f0f0f0";

            doc
                .rect(50, yPos, 500, 25)
                .fillAndStroke(tableHeaderBg, "#000000");

            doc
                .fillColor("#000000")
                .fontSize(9)
                .font("Helvetica-Bold")
                .text("Sr No", 60, yPos + 8)
                .text("Description", 100, yPos + 8)
                .text("Quantity", 260, yPos + 8)
                .text("GST (10%)", 320, yPos + 8)
                .text("Listed Price", 390, yPos + 8)
                .text("Amount", 470, yPos + 8);

            // gst reverse calculation , 

            yPos += 25;

            // Table Rows
            let srNo = 1;
            let subtotal = 0;
            const GST_RATE = 0.10; // 10% GST

            orderItems.forEach((item) => {
                const rowHeight = 20;

                // Calculate GST for this item (reverse calculation)
                const itemTotal = item.totalPrice;
                const itemNet = Number((itemTotal / (1 + GST_RATE)).toFixed(2));
                const itemGST = Number((itemTotal - itemNet).toFixed(2));

                doc
                    .rect(50, yPos, 500, rowHeight)
                    .stroke();

                // Vertical lines
                doc.moveTo(95, yPos).lineTo(95, yPos + rowHeight).stroke();
                doc.moveTo(255, yPos).lineTo(255, yPos + rowHeight).stroke();
                doc.moveTo(315, yPos).lineTo(315, yPos + rowHeight).stroke();
                doc.moveTo(385, yPos).lineTo(385, yPos + rowHeight).stroke();
                doc.moveTo(465, yPos).lineTo(465, yPos + rowHeight).stroke();

                doc
                    .fontSize(8)
                    .font("Helvetica")
                    .text(srNo.toString(), 60, yPos + 6)
                    .text(item.name, 100, yPos + 6, { width: 150 })
                    .text(item.quantity.toString(), 265, yPos + 6)
                    .text(formatCurrency(itemGST), 320, yPos + 6)
                    .text(formatCurrency(itemNet), 390, yPos + 6)
                    .text(formatCurrency(item.totalPrice), 470, yPos + 6);

                subtotal += item.totalPrice;
                yPos += rowHeight;
                srNo++;
            });

            // Platform Fee Row (if any)
            console.log('🔍 DEBUG - Platform Fee Check:');
            console.log('   order.platformFee:', order.platformFee);
            console.log('   Type:', typeof order.platformFee);
            console.log('   Is truthy?', !!order.platformFee);
            console.log('   Is > 0?', order.platformFee > 0);
            console.log('   Condition result:', !!(order.platformFee && order.platformFee > 0));

            if (order.platformFee && Number(order.platformFee) > 0) {
                console.log('✅ Adding Platform Fee row to invoice');
                const rowHeight = 20;

                // Calculate GST for platform fee
                const pfTotal = Number(order.platformFee);
                const pfNet = Number((pfTotal / (1 + GST_RATE)).toFixed(2));
                const pfGST = Number((pfTotal - pfNet).toFixed(2));

                doc
                    .rect(50, yPos, 500, rowHeight)
                    .stroke();

                doc.moveTo(95, yPos).lineTo(95, yPos + rowHeight).stroke();
                doc.moveTo(255, yPos).lineTo(255, yPos + rowHeight).stroke();
                doc.moveTo(315, yPos).lineTo(315, yPos + rowHeight).stroke();
                doc.moveTo(385, yPos).lineTo(385, yPos + rowHeight).stroke();
                doc.moveTo(465, yPos).lineTo(465, yPos + rowHeight).stroke();

                doc
                    .text(srNo.toString(), 60, yPos + 6)
                    .text("Platform Fee", 100, yPos + 6)
                    .text("1", 265, yPos + 6)
                    .text(formatCurrency(pfGST), 320, yPos + 6)
                    .text(formatCurrency(pfNet), 390, yPos + 6)
                    .text(formatCurrency(order.platformFee), 470, yPos + 6);

                subtotal += Number(order.platformFee);
                yPos += rowHeight;
                srNo++;
            } else {
                console.log('❌ Platform Fee NOT added');
                console.log('   Reason: platformFee is', order.platformFee);
            }

            // Packing Charges Row (if any)
            if (order.packingCharges && order.packingCharges > 0) {
                const rowHeight = 20;

                // Calculate GST for packing charges
                const pcTotal = Number(order.packingCharges);
                const pcNet = Number((pcTotal / (1 + GST_RATE)).toFixed(2));
                const pcGST = Number((pcTotal - pcNet).toFixed(2));

                doc
                    .rect(50, yPos, 500, rowHeight)
                    .stroke();

                doc.moveTo(95, yPos).lineTo(95, yPos + rowHeight).stroke();
                doc.moveTo(255, yPos).lineTo(255, yPos + rowHeight).stroke();
                doc.moveTo(315, yPos).lineTo(315, yPos + rowHeight).stroke();
                doc.moveTo(385, yPos).lineTo(385, yPos + rowHeight).stroke();
                doc.moveTo(465, yPos).lineTo(465, yPos + rowHeight).stroke();

                doc
                    .text(srNo.toString(), 60, yPos + 6)
                    .text("Order Packing Charges", 100, yPos + 6)
                    .text("1", 265, yPos + 6)
                    .text(formatCurrency(pcGST), 320, yPos + 6)
                    .text(formatCurrency(pcNet), 390, yPos + 6)
                    .text(formatCurrency(order.packingCharges), 470, yPos + 6);

                subtotal += order.packingCharges;
                yPos += rowHeight;
            }

            // Subtotal Row
            const subtotalRowHeight = 20;
            doc
                .rect(50, yPos, 500, subtotalRowHeight)
                .stroke();

            doc.moveTo(465, yPos).lineTo(465, yPos + subtotalRowHeight).stroke();

            doc
                .fontSize(9)
                .font("Helvetica-Bold")
                .text("Total Amount", 100, yPos + 6)
                .text(formatCurrency(subtotal), 470, yPos + 6);

            yPos += subtotalRowHeight + 40;

            // ========================================
            // AMOUNT IN WORDS
            // ========================================
            const amountInWords = numberToWords(order.totalAmount);
            doc
                .fontSize(9)
                .font("Helvetica-Bold")
                .text("Invoice total in words", 50, yPos);

            yPos += 15;
            doc
                .font("Helvetica")
                .text(amountInWords, 50, yPos, { width: 500 });

            // ========================================
            // FOOTER
            // ========================================
            const footerY = doc.page.height - 80;

            doc
                .fontSize(8)
                .font("Helvetica-Oblique")
                .fillColor("#666666")
                .text(
                    "This is a computer-generated invoice and does not require a signature.",
                    50,
                    footerY,
                    { align: "center", width: 500 }
                )
                .text(
                    "Thank you for choosing ResQBox Food!",
                    50,
                    footerY + 15,
                    { align: "center", width: 500 }
                );

            // Finalize PDF
            doc.end();
        } catch (error) {
            console.error("Error generating order invoice:", error);
            reject(error);
        }
    });
}

/**
 * Convert number to words (Indian format)
 */
function numberToWords(amount) {
    const ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];
    const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
    const teens = ['Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];

    function convertLessThanThousand(num) {
        if (num === 0) return '';

        let result = '';

        if (num >= 100) {
            result += ones[Math.floor(num / 100)] + ' Hundred ';
            num %= 100;
        }

        if (num >= 20) {
            result += tens[Math.floor(num / 10)] + ' ';
            num %= 10;
        } else if (num >= 10) {
            result += teens[num - 10] + ' ';
            return result;
        }

        if (num > 0) {
            result += ones[num] + ' ';
        }

        return result;
    }

    const dollars = Math.floor(amount);
    const cents = Math.round((amount - dollars) * 100);

    if (dollars === 0 && cents === 0) {
        return 'Zero Dollars Only';
    }

    let words = '';

    if (dollars >= 1000000) {
        words += convertLessThanThousand(Math.floor(dollars / 1000000)) + 'Million ';
        dollars %= 1000000;
    }

    if (dollars >= 1000) {
        words += convertLessThanThousand(Math.floor(dollars / 1000)) + 'Thousand ';
        dollars %= 1000;
    }

    if (dollars > 0) {
        words += convertLessThanThousand(dollars);
    }

    words += 'Dollars';

    if (cents > 0) {
        words += ' and ' + convertLessThanThousand(cents) + 'Cents';
    }

    words += ' Only';

    return words.trim();
}

/**
 * Generate PDF invoice for restaurant (per order) showing Service Fee deduction
 * This is the restaurant's copy showing their net earnings after service fee
 */
async function generateRestaurantOrderInvoice(orderData) {
    const {
        invoiceNumber,
        order,
        restaurant,
        orderItems,
        serviceFeePercent,
        createdAt
    } = orderData;

    const datetime = Date.now();
    const fileName = `REST-${invoiceNumber}-${datetime}.pdf`;

    return new Promise((resolve, reject) => {
        try {
            const doc = new PDFDocument({ margin: 50, size: 'A4' });

            // Collect PDF data in memory
            const chunks = [];
            doc.on('data', (chunk) => chunks.push(chunk));
            doc.on('end', async () => {
                try {
                    const pdfBuffer = Buffer.concat(chunks);

                    // Upload to S3
                    const s3Key = `restaurant-invoices/${fileName}`;
                    const uploadParams = {
                        Bucket: process.env.AWS_BUCKET_NAME,
                        Key: s3Key,
                        Body: pdfBuffer,
                        ContentType: 'application/pdf',
                    };

                    const command = new PutObjectCommand(uploadParams);
                    await s3.send(command);

                    const pdfUrl = `https://d19qgxevt3ep10.cloudfront.net/${s3Key}`;

                    resolve({
                        fileName,
                        pdfUrl
                    });
                } catch (uploadError) {
                    console.error("S3 upload error:", uploadError);
                    reject(uploadError);
                }
            });

            doc.on('error', reject);

            const formatDate = (date) => {
                const d = new Date(date);
                return `${String(d.getDate()).padStart(2, '0')}-${String(d.getMonth() + 1).padStart(2, '0')}-${d.getFullYear()}`;
            };

            const formatCurrency = (amount) => {
                return `$${Number(amount).toFixed(2)}`;
            };

            const GST_RATE = 0.10; // 10% GST

            // ========================================
            // HEADER
            // ========================================
            doc
                .fontSize(24)
                .font("Helvetica-Bold")
                .fillColor("#FF6B35")
                .text("ResQBox Food", { align: "center" })
                .moveDown(0.5);

            doc
                .fontSize(14)
                .fillColor("#000000")
                .text("RESTAURANT ORDER INVOICE", { align: "center" })
                .moveDown(0.5);

            // Horizontal line
            doc
                .moveTo(50, doc.y)
                .lineTo(550, doc.y)
                .stroke()
                .moveDown(1);

            // ========================================
            // INVOICE INFO
            // ========================================
            let yPos = doc.y;

            doc
                .fontSize(10)
                .font("Helvetica-Bold")
                .text("Invoice Number:", 50, yPos);
            doc
                .font("Helvetica")
                .text(invoiceNumber, 150, yPos);

            yPos += 15;
            doc
                .font("Helvetica-Bold")
                .text("Order ID:", 50, yPos);
            doc
                .font("Helvetica")
                .text("OD" + String(order.orderNumber), 150, yPos);

            yPos += 15;
            doc
                .font("Helvetica-Bold")
                .text("Date:", 50, yPos);
            doc
                .font("Helvetica")
                .text(formatDate(createdAt), 150, yPos);

            // Restaurant Details (Right Side)
            let rightY = doc.y - 45;
            doc
                .fontSize(10)
                .font("Helvetica-Bold")
                .text("Restaurant:", 320, rightY);
            doc
                .font("Helvetica")
                .text(restaurant.name, 320, rightY + 15, { width: 230 });

            if (restaurant.gstin) {
                rightY += 35;
                doc
                    .font("Helvetica-Bold")
                    .text("ABN:", 320, rightY);
                doc
                    .font("Helvetica")
                    .text(restaurant.gstin, 380, rightY);
            }

            yPos += 40;

            // ========================================
            // ORDER ITEMS TABLE
            // ========================================
            const tableTop = yPos;

            doc
                .rect(50, yPos, 500, 25)
                .fillAndStroke("#f0f0f0", "#000000");

            doc
                .fillColor("#000000")
                .fontSize(9)
                .font("Helvetica-Bold")
                .text("Item", 60, yPos + 8)
                .text("Qty", 280, yPos + 8)
                .text("Price", 340, yPos + 8)
                .text("GST (10%)", 400, yPos + 8)
                .text("Total", 480, yPos + 8);

            yPos += 25;

            // Table Rows
            let itemsSubtotal = 0;
            orderItems.forEach((item) => {
                const rowHeight = 20;

                // Reverse GST calculation
                const itemTotal = item.totalPrice;
                const itemNet = Number((itemTotal / (1 + GST_RATE)).toFixed(2));
                const itemGST = Number((itemTotal - itemNet).toFixed(2));

                doc
                    .rect(50, yPos, 500, rowHeight)
                    .stroke();

                doc.moveTo(275, yPos).lineTo(275, yPos + rowHeight).stroke();
                doc.moveTo(335, yPos).lineTo(335, yPos + rowHeight).stroke();
                doc.moveTo(395, yPos).lineTo(395, yPos + rowHeight).stroke();
                doc.moveTo(475, yPos).lineTo(475, yPos + rowHeight).stroke();

                doc
                    .fontSize(8)
                    .font("Helvetica")
                    .text(item.name, 60, yPos + 6, { width: 210 })
                    .text(item.quantity.toString(), 285, yPos + 6)
                    .text(formatCurrency(item.price), 340, yPos + 6)
                    .text(formatCurrency(itemGST), 400, yPos + 6)
                    .text(formatCurrency(item.totalPrice), 480, yPos + 6);

                itemsSubtotal += item.totalPrice;
                yPos += rowHeight;
            });

            // Items Subtotal
            const subtotalHeight = 20;
            doc
                .rect(50, yPos, 500, subtotalHeight)
                .stroke();

            doc.moveTo(475, yPos).lineTo(475, yPos + subtotalHeight).stroke();

            doc
                .fontSize(9)
                .font("Helvetica-Bold")
                .text("Items Subtotal", 60, yPos + 6)
                .text(formatCurrency(itemsSubtotal), 480, yPos + 6);

            yPos += subtotalHeight + 20;

            // ========================================
            // EARNINGS BREAKDOWN TABLE
            // ========================================
            doc
                .fontSize(12)
                .font("Helvetica-Bold")
                .text("Restaurant Earnings Breakdown", 50, yPos);

            yPos += 25;

            // Table Header
            doc
                .rect(50, yPos, 500, 25)
                .fillAndStroke("#f0f0f0", "#000000");

            doc
                .fillColor("#000000")
                .fontSize(9)
                .font("Helvetica-Bold")
                .text("Description", 60, yPos + 8)
                .text("GST (10%)", 280, yPos + 8, { width: 80, align: "right" })
                .text("Net Amount", 370, yPos + 8, { width: 80, align: "right" })
                .text("Total", 460, yPos + 8, { width: 80, align: "right" });

            yPos += 25;

            // Calculate Listed Price (Items Total)
            const listedPriceTotal = itemsSubtotal;
            const listedPriceNet = Number((listedPriceTotal / (1 + GST_RATE)).toFixed(2));
            const listedPriceGST = Number((listedPriceTotal - listedPriceNet).toFixed(2));

            // Calculate Service Fee
            const serviceFeeTotal = Number((listedPriceTotal * (serviceFeePercent / 100)).toFixed(2));
            const serviceFeeNet = Number((serviceFeeTotal / (1 + GST_RATE)).toFixed(2));
            const serviceFeeGST = Number((serviceFeeTotal - serviceFeeNet).toFixed(2));

            // Calculate Net Earnings
            const netEarningsTotal = listedPriceTotal - serviceFeeTotal;
            const netEarningsNet = Number((netEarningsTotal / (1 + GST_RATE)).toFixed(2));
            const netEarningsGST = Number((netEarningsTotal - netEarningsNet).toFixed(2));

            // Helper function to draw rows
            const drawRow = (label, gst, net, total, isBold = false) => {
                const h = 20;
                doc.rect(50, yPos, 500, h).stroke();

                doc.moveTo(270, yPos).lineTo(270, yPos + h).stroke();
                doc.moveTo(360, yPos).lineTo(360, yPos + h).stroke();
                doc.moveTo(450, yPos).lineTo(450, yPos + h).stroke();

                const formatVal = (val) => {
                    const absVal = Math.abs(val).toFixed(2);
                    return val < 0 ? `-$${absVal}` : `$${absVal}`;
                };

                doc
                    .font(isBold ? "Helvetica-Bold" : "Helvetica")
                    .fontSize(9)
                    .text(label, 60, yPos + 6)
                    .text(formatVal(gst), 280, yPos + 6, { width: 80, align: "right" })
                    .text(formatVal(net), 370, yPos + 6, { width: 80, align: "right" })
                    .text(formatVal(total), 460, yPos + 6, { width: 80, align: "right" });

                yPos += h;
            };

            // Draw rows
            drawRow("Listed Price", listedPriceGST, listedPriceNet, listedPriceTotal);
            drawRow(`Service Fee (${serviceFeePercent}%)`, -serviceFeeGST, -serviceFeeNet, -serviceFeeTotal);
            yPos += 5;
            drawRow("Net Earnings", netEarningsGST, netEarningsNet, netEarningsTotal, true);

            yPos += 30;

            // ========================================
            // AMOUNT IN WORDS
            // ========================================
            const amountInWords = numberToWords(netEarningsTotal);
            doc
                .fontSize(9)
                .font("Helvetica-Bold")
                .text("Net Earnings in words:", 50, yPos);

            yPos += 15;
            doc
                .font("Helvetica")
                .text(amountInWords, 50, yPos, { width: 500 });

            // ========================================
            // FOOTER
            // ========================================
            const footerY = doc.page.height - 80;

            doc
                .fontSize(8)
                .font("Helvetica-Oblique")
                .fillColor("#666666")
                .text(
                    "This is a computer-generated invoice for restaurant records.",
                    50,
                    footerY,
                    { align: "center", width: 500 }
                )
                .text(
                    "Thank you for partnering with ResQBox Food!",
                    50,
                    footerY + 15,
                    { align: "center", width: 500 }
                );

            // Finalize PDF
            doc.end();
        } catch (error) {
            console.error("Error generating restaurant order invoice:", error);
            reject(error);
        }
    });
}

module.exports = {
    getNextInvoiceNumber,
    generatePayoutInvoice,
    getNextOrderInvoiceNumber,
    generateOrderInvoice,
    generateRestaurantOrderInvoice
};
