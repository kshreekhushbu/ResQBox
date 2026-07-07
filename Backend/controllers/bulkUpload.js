/**
 * Bulk Upload Cuisines from Excel File
 * 
 * Expected Excel format:
 * Column A: Food Category (Cuisine Name)
 * 
 * Example:
 * | Food Category |
 * |---------------|
 * | Acaraje       |
 * | Afghan        |
 * | American      |
 */
const catchAsync = require("../utils/catchAsync");
const xlsx = require("xlsx");
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();
exports.bulkUploadCuisines = catchAsync(async (req, res) => {
    console.log("📤 [BULK UPLOAD] Starting cuisine bulk upload...");

    if (!req.file) {
        return res.status(400).json({
            status: 0,
            message: "Excel file is required"
        });
    }

    try {
        // Read the Excel file from buffer
        const workbook = xlsx.read(req.file.buffer, { type: 'buffer' });

        // Get the first sheet
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];

        // Convert to JSON (expects header in first row)
        const data = xlsx.utils.sheet_to_json(worksheet);

        console.log(`📊 [BULK UPLOAD] Found ${data.length} rows in Excel`);

        if (data.length === 0) {
            return res.status(400).json({
                status: 0,
                message: "Excel file is empty"
            });
        }

        const results = {
            total: data.length,
            inserted: 0,
            skipped: 0,
            errors: []
        };

        // Process each row
        for (let i = 0; i < data.length; i++) {
            const row = data[i];

            // Get cuisine name from first column (could be "Food Category" or any header)
            const cuisineName = row['Food Category'] || row['food category'] || row['Cuisine'] || row['cuisine'] || row['Name'] || row['name'];

            if (!cuisineName || cuisineName.trim() === '') {
                console.log(`⚠️  [BULK UPLOAD] Row ${i + 2}: Empty cuisine name, skipping`);
                results.skipped++;
                results.errors.push({
                    row: i + 2,
                    error: "Empty cuisine name"
                });
                continue;
            }

            const trimmedName = cuisineName.trim();

            try {
                // Check if cuisine already exists
                const existing = await prisma.cuisine.findFirst({
                    where: {
                        name: {
                            equals: trimmedName,
                            mode: 'insensitive' // Case-insensitive search
                        }
                    }
                });

                if (existing) {
                    console.log(`⏭️  [BULK UPLOAD] Row ${i + 2}: "${trimmedName}" already exists, skipping`);
                    results.skipped++;
                    results.errors.push({
                        row: i + 2,
                        name: trimmedName,
                        error: "Already exists"
                    });
                    continue;
                }

                // Insert new cuisine
                await prisma.cuisine.create({
                    data: {
                        name: trimmedName,
                        isActive: 1
                    }
                });

                console.log(`✅ [BULK UPLOAD] Row ${i + 2}: "${trimmedName}" inserted successfully`);
                results.inserted++;

            } catch (error) {
                console.error(`❌ [BULK UPLOAD] Row ${i + 2}: Error inserting "${trimmedName}":`, error.message);
                results.errors.push({
                    row: i + 2,
                    name: trimmedName,
                    error: error.message
                });
            }
        }

        console.log("================================================");
        console.log("📊 [BULK UPLOAD] Summary:");
        console.log(`   Total rows: ${results.total}`);
        console.log(`   Inserted: ${results.inserted}`);
        console.log(`   Skipped: ${results.skipped}`);
        console.log("================================================");

        return res.status(200).json({
            status: 1,
            message: "Bulk upload completed",
            results: {
                total: results.total,
                inserted: results.inserted,
                skipped: results.skipped,
                errors: results.errors.length > 0 ? results.errors : undefined
            }
        });

    } catch (error) {
        console.error("❌ [BULK UPLOAD] Error processing Excel file:", error);
        return res.status(500).json({
            status: 0,
            message: "Error processing Excel file",
            error: error.message
        });
    }
});


exports.bulkUploadFoodCategories = catchAsync(async (req, res) => { 
    console.log("📤 [BULK UPLOAD] Starting food category bulk upload...");

    if (!req.file) {
        return res.status(400).json({
            status: 0,
            message: "Excel file is required"
        });
    }

    try {
        // Read the Excel file from buffer
        const workbook = xlsx.read(req.file.buffer, { type: 'buffer' });

        // Get the first sheet
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];

        // Convert to JSON (expects header in first row)
        const data = xlsx.utils.sheet_to_json(worksheet);

        console.log(`📊 [BULK UPLOAD] Found ${data.length} rows in Excel`);

        if (data.length === 0) {
            return res.status(400).json({
                status: 0,
                message: "Excel file is empty"
            });
        }

        const results = {
            total: data.length,
            inserted: 0,
            skipped: 0,
            errors: []
        };

        // Process each row
        for (let i = 0; i < data.length; i++) {
            const row = data[i];

            // Get category name from first column (could be "Food Category" or any header)
            const categoryName = row['Food Category'] || row['food category'] || row['Category'] || row['category'] || row['Name'] || row['name'];

            if (!categoryName || categoryName.trim() === '') {
                console.log(`⚠️  [BULK UPLOAD] Row ${i + 2}: Empty category name, skipping`);
                results.skipped++;
                results.errors.push({
                    row: i + 2,
                    error: "Empty category name"
                });
                continue;
            }

            const trimmedName = categoryName.trim();

            try {
                // Check if category already exists
                const existing = await prisma.category.findFirst({
                    where: {
                        name: {
                            equals: trimmedName,
                            mode: 'insensitive' // Case-insensitive search
                        }
                    }
                });

                if (existing) {
                    console.log(`⏭️  [BULK UPLOAD] Row ${i + 2}: "${trimmedName}" already exists, skipping`);
                    results.skipped++;
                    results.errors.push({
                        row: i + 2,
                        name: trimmedName,
                        error: "Already exists"
                    });
                    continue;
                }

                // Insert new category
                await prisma.category.create({
                    data: {
                        name: trimmedName,
                        isActive: 1
                    }
                });

                console.log(`✅ [BULK UPLOAD] Row ${i + 2}: "${trimmedName}" inserted successfully`);
                results.inserted++;

            } catch (error) {
                console.error(`❌ [BULK UPLOAD] Row ${i + 2}: Error inserting "${trimmedName}":`, error.message);
                results.errors.push({
                    row: i + 2,
                    name: trimmedName,
                    error: error.message
                });
            }
        }

        console.log("================================================");
        console.log("📊 [BULK UPLOAD] Summary:");
        console.log(`   Total rows: ${results.total}`);
        console.log(`   Inserted: ${results.inserted}`);
        console.log(`   Skipped: ${results.skipped}`);
        console.log("================================================");

        return res.status(200).json({
            status: 1,
            message: "Bulk upload completed",
            results: {
                total: results.total,
                inserted: results.inserted,
                skipped: results.skipped,
                errors: results.errors.length > 0 ? results.errors : undefined
            }
        });

    } catch (error) {
        console.error("❌ [BULK UPLOAD] Error processing Excel file:", error);
        return res.status(500).json({
            status: 0,
            message: "Error processing Excel file",
            error: error.message
        });
    }
});