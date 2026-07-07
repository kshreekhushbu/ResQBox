import React, { useState, useRef, useCallback } from "react";
import { GrCloudUpload } from "react-icons/gr";
import Fileclasses from "./image.module.css";
import { ErrorMessage } from "@/utils/Toast";
import { UplaodImage } from "./imageService";

interface FileUploadProps {
  label: string;
  files: string[];
  folder: string;
  setPreviewImages: (files: string[]) => void;
  onUploadSuccess: (urls: string[], fileNames: string[]) => void;
  uploadId?: string;
}

const FileMultiUpload: React.FC<FileUploadProps> = ({
  label,
  files,
  folder,
  setPreviewImages,
  onUploadSuccess,
  uploadId = "default",
}) => {
  const [error, setError] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [isDragOver, setIsDragOver] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFiles = Array.from(e.target.files || []);
    await processFiles(selectedFiles);
  };

  const processFiles = async (selectedFiles: File[]) => {
    const allowedTypes = ["image/png", "image/jpeg", "image/webp"];

    const validFiles = selectedFiles.filter((file) =>
      allowedTypes.includes(file.type)
    );

    if (validFiles.length === 0) {
      setError("Only *.jpeg, *.png, *.webp files are accepted.");
      return;
    }

    setError(null);
    setIsUploading(true);

    const uploadedUrls: string[] = [];
    const uploadedFileNames: string[] = [];

    try {
      for (const file of validFiles) {
        const formData = new FormData();
        formData.append("fileimg", file);
        formData.append("folder", folder);

        const res = await UplaodImage(formData);
        console.log("Upload response:", res);
        if (res?.data?.Status === 1 || res?.data?.status === 1) {
          const fileName = res?.data?.fileName;
          const fileUrl = res?.data?.fileUrl;
          console.log("Upload successful:", { fileName, fileUrl });
          uploadedUrls.push(fileUrl);
          uploadedFileNames.push(fileName);
        } else {
          console.log("Upload failed:", res?.data);
          ErrorMessage(res?.data?.message || "Upload failed");
        }
      }

      if (uploadedUrls.length > 0) {
        const allUrls = [...files, ...uploadedUrls];
        const allFileNames = [...files, ...uploadedUrls].map((url) => {
          const parts = url ? url.split("/") : [];
          return parts.length > 0 ? parts[parts.length - 1] : "";
        });
        setPreviewImages(allUrls);
        onUploadSuccess(allUrls, allFileNames);
      }
    } catch (err: any) {
      console.error(err);
      ErrorMessage(
        err?.response?.data?.message || "An error occurred while uploading."
      );
    } finally {
      setIsUploading(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
    }
  };

  const removeImage = (urlToRemove: string) => {
    const updatedUrls = files.filter((url) => url !== urlToRemove);
    const updatedFileNames = updatedUrls.map((url) => {
      const parts = url ? url.split("/") : [];
      return parts.length > 0 ? parts[parts.length - 1] : "";
    });

    setPreviewImages(updatedUrls);
    onUploadSuccess(updatedUrls, updatedFileNames);
  };

  // Drag and drop handlers
  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
  }, []);

  const handleDrop = useCallback(
    async (e: React.DragEvent) => {
      e.preventDefault();
      setIsDragOver(false);

      if (isUploading) return;

      const droppedFiles = Array.from(e.dataTransfer.files);
      await processFiles(droppedFiles);
    },
    [isUploading]
  );

  const handleClick = () => {
    if (!isUploading && fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  return (
    <div className={Fileclasses.fileUploadContainer}>
      {label && (
        <label
          style={{
            display: "block",
            marginBottom: "8px",
            fontWeight: "500",
            color: "#333",
          }}
        >
          {label}
        </label>
      )}

      <div
        className={`${Fileclasses.fileUploadBox} ${isUploading ? Fileclasses.disabled : ""
          }`}
      >
        <div
          className={`${Fileclasses.dropZone} ${isDragOver ? Fileclasses.dragover : ""
            }`}
          onDragOver={handleDragOver}
          onDragLeave={handleDragLeave}
          onDrop={handleDrop}
          onClick={handleClick}
          style={{ cursor: isUploading ? "not-allowed" : "pointer" }}
        >
          <input
            ref={fileInputRef}
            type="file"
            multiple
            accept="image/png,image/jpeg,image/webp"
            onChange={handleFileChange}
            className={Fileclasses.fileInput}
            id={`file-upload-${uploadId}`}
            disabled={isUploading}
            style={{ display: "none" }}
          />

          <div className={Fileclasses.uploadIcon}>
            {isUploading ? (
              <div className={Fileclasses.loadingSpinner} />
            ) : (
              <GrCloudUpload size={28} />
            )}
          </div>

          <p
            className={`${Fileclasses.uploadText} ${isUploading ? Fileclasses.uploadingText : ""
              }`}
          >
            {isUploading ? "Uploading..." : "Drag Your Files here"}
          </p>

          <p className={Fileclasses.uploadSubtext}>
            (Only *.jpeg, *.png will be accepted)
          </p>
        </div>
        {files.length > 0 && (
          <div className={Fileclasses.previewContainer}>
            {files.map((url, idx) => (
              <div key={idx} className={Fileclasses.imageWrapper}>
                <img
                  src={url}
                  alt={`Preview ${idx + 1}`}
                  className={Fileclasses.previewImage}
                />
                <button
                  type="button"
                  onClick={() => removeImage(url)}
                  className={Fileclasses.removeButton}
                  title="Remove image"
                />
              </div>
            ))}
          </div>
        )}

        {error && <div className={Fileclasses.errorMessage}>{error}</div>}
      </div>
    </div>
  );
};

export default FileMultiUpload;
