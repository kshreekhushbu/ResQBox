const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const path = require("path");
const dotenv = require("dotenv");
const catchAsync = require("../utils/catchAsync");

dotenv.config({ path: path.join(__dirname, "../../.env") });

const s3 = new S3Client({
    region: process.env.AWS_REGION,
    credentials: {
        accessKeyId: process.env.AWS_ACCESSKEYID,
        secretAccessKey: process.env.AWS_SECRETACCESSKEY,
    },
});

const uploadImage = catchAsync(async (req, res) => {
    const file = req.file;
    const { folder } = req.body;

    console.log("File received:", file);
    console.log("Folder received:", folder);
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/jpg', 'application/pdf', 'image/webp'];
    if (!file || !allowedMimeTypes.includes(file.mimetype)) {
        return res.status(400).json({
            status: 0,
            message: "Invalid file type. Only image files are allowed.",
        });
    }


    const uploadResult = await uploadImageToS3(file, folder);
    console.log("Upload Result:", uploadResult);

    if (!uploadResult || !uploadResult.fileName) {
        return res.status(500).json({ status: 0, message: "Upload failed", debug: uploadResult });
    }

    res.status(200).json({
        status: 1,
        message: "File uploaded successfully",
        fileName: uploadResult.fileName,
        fileUrl: uploadResult.fileUrl,
    });
});

const uploadMultipleImages = catchAsync(async (req, res) => {
    const files = req.files;
    const { folder } = req.body;

    console.log("Files received:", files);
    console.log("Folder received:", folder);

    if (!files || files.length === 0) {
        return res.status(400).json({
            status: 0,
            message: "No files uploaded.",
        });
    }

    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/jpg', 'image/webp', 'application/pdf'];

    const uploadedFiles = [];

    for (const file of files) {
        if (!allowedMimeTypes.includes(file.mimetype)) {
            return res.status(400).json({
                status: 0,
                message: `Invalid file type for ${file.originalname}. Only image files are allowed.`,
            });
        }

        const uploadResult = await uploadImageToS3(file, folder);
        uploadedFiles.push(uploadResult);
    }

    res.status(200).json({
        status: 1,
        message: "Files uploaded successfully",
        files: uploadedFiles,
    });
});


const uploadImageToS3 = async (file, folder) => {
    // Get actual file extension from mimetype or original filename
    let fileExtension = '.png'; // default fallback

    if (file.mimetype === 'image/jpeg' || file.mimetype === 'image/jpg') {
        fileExtension = '.jpg';
    } else if (file.mimetype === 'image/png') {
        fileExtension = '.png';
    } else if (file.mimetype === 'image/gif') {
        fileExtension = '.gif';
    } else if (file.mimetype === 'image/webp') {
        fileExtension = '.webp';
    } else if (file.mimetype === 'application/pdf') {
        fileExtension = '.pdf';
    } else if (file.originalname) {
        // Fallback to original extension if mimetype doesn't match
        const ext = path.extname(file.originalname).toLowerCase();
        if (ext) fileExtension = ext;
    }

    const fileName = `${Date.now()}${fileExtension}`;
    const filePath = `${folder}/${fileName}`;

    const params = {
        Bucket: process.env.AWS_BUCKET_NAME,
        Key: filePath,
        Body: file.buffer,
        ContentType: file.mimetype,
    };

    const command = new PutObjectCommand(params);
    const response = await s3.send(command);

    console.log("S3 Response:", response);

    return {
        fileName: fileName,
        fileUrl: `https://d19qgxevt3ep10.cloudfront.net/${filePath}`,
    };

};

module.exports = { uploadImage, uploadMultipleImages };

