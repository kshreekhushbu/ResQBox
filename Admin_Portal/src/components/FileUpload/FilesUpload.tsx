import React, { useState } from "react";
import { GrCloudUpload } from "react-icons/gr";
import Fileclasses from "./File.module.css";
import { ErrorMessage } from "@/utils/Toast";
import { UplaodImage } from "./imageService";

interface FileUploadProps {
  label: string;
  file: string | null;
  folder: string;
  setPreviewImage: (file: string) => void;
  onUploadSuccess: (url: string, fileName: string) => void;
  uploadId?: string;
}

const DocumentUpload: React.FC<FileUploadProps> = ({
  file,
  label,
  folder,
  setPreviewImage,
  onUploadSuccess,
  uploadId = "default",
}) => {
  const [error, setError] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0];
    const allowedTypes = [
      "application/pdf",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ];

    if (!selectedFile) return;

    if (!allowedTypes.includes(selectedFile.type)) {
      setError("Only *.pdf and *.docx files are accepted.");
      return;
    }

    setError(null);
    setIsUploading(true);

    const formData = new FormData();
    formData.append("fileimg", selectedFile);
    formData.append("folder", folder);

    try {
      const res = await UplaodImage(formData);
      if (res?.data?.status === 1) {
        const filename = res?.data?.fileName;
        const url = res?.data?.fileUrl;
        setPreviewImage(filename);
        onUploadSuccess(url, filename);
      } else {
        ErrorMessage(res?.data?.message);
      }
    } catch (err: any) {
      console.error(err);
      ErrorMessage(err?.response?.data?.message || "An error occurred");
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div className={Fileclasses.fileUploadContainer}>
      <label>{label}</label>
      <div className={Fileclasses.fileUploadBox}>
        {file ? (
          <div className={Fileclasses.previewContainer}>
            <p className={Fileclasses.previewText}>{file}</p>
            <button
              type="button"
              onClick={() => setPreviewImage("")}
              className={Fileclasses.removeButton}
            >
              Remove
            </button>
          </div>
        ) : (
          <>
            <input
              type="file"
              accept=".pdf,.docx,application/pdf,application/vnd.openxmlformats-officedocument.wordprocessingml.document"
              onChange={handleFileChange}
              className={Fileclasses.fileInput}
              id={`file-upload-${uploadId}`}
              disabled={isUploading}
              style={{ display: "none" }}
            />
            <label
              htmlFor={`file-upload-${uploadId}`}
              className={Fileclasses.fileUploadLabel}
            >
              <GrCloudUpload size={40} />
              <span className={Fileclasses.uploadText}>
                {isUploading ? "Uploading..." : "Drag Your Files Here"}
              </span>
              <span className={Fileclasses.acceptedFormats}>
                (Only *.pdf, *.docx will be accepted)
              </span>
            </label>
            {error && <div className={Fileclasses.errorMessage}>{error}</div>}
          </>
        )}
      </div>
    </div>
  );
};

export default DocumentUpload;
