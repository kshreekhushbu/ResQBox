import React, { useState } from "react";
import { GrCloudUpload } from "react-icons/gr";
import { FileText, X } from "lucide-react";
import { ErrorMessage } from "@/utils/Toast";
import { UplaodImage } from "./imageService";
import styles from "./DocUpload.module.css";

interface ExcelUploadProps {
  label: string;
  file: string | null;
  folder: string;
  setPreviewImage: (file: string) => void;
  onUploadSuccess: (url: string, fileName: string) => void;
  uploadId?: string;
}

const ExcelUpload: React.FC<ExcelUploadProps> = ({
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
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", // .xlsx
      "application/vnd.ms-excel", // .xls
    ];

    if (!selectedFile) return;

    if (!allowedTypes.includes(selectedFile.type)) {
      setError("Only *.xlsx and *.xls files are accepted.");
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

  const handleRemove = () => {
    setPreviewImage("");
    onUploadSuccess("", "");
  };

  return (
    <div className={styles["doc-upload-wrapper"]}>
      <label className={styles["doc-upload-label-text"]}>{label}</label>
      <div className={styles["doc-upload-main-box"]}>
        {file ? (
          <div className={styles["doc-preview-wrapper"]}>
            <div className={styles["doc-preview-info-bar"]}>
              <div className={styles["doc-preview-file-info"]}>
                <FileText className={styles["doc-preview-file-icon"]} />
                <span className={styles["doc-preview-file-name"]}>{file}</span>
              </div>
              <div className={styles["doc-preview-controls"]}>
                <button
                  type="button"
                  onClick={handleRemove}
                  className={styles["doc-preview-delete-btn"]}
                  title="Remove File"
                >
                  <X size={16} />
                  <span>Remove</span>
                </button>
              </div>
            </div>
          </div>
        ) : (
          <>
            <input
              type="file"
              accept=".xlsx,.xls,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel"
              onChange={handleFileChange}
              className={styles["doc-file-input-field"]}
              id={`excel-file-upload-${uploadId}`}
              disabled={isUploading}
              style={{ display: "none" }}
            />
            <label
              htmlFor={`excel-file-upload-${uploadId}`}
              className={styles["doc-upload-drop-zone"]}
            >
              <GrCloudUpload size={40} />
              <span className={styles["doc-upload-instruction"]}>
                {isUploading ? "Uploading..." : "Drag Your Files Here"}
              </span>
              <span className={styles["doc-upload-file-types"]}>
                (Only *.xlsx, *.xls will be accepted)
              </span>
            </label>
            {error && <div className={styles["doc-upload-error"]}>{error}</div>}
          </>
        )}
      </div>
    </div>
  );
};

export default ExcelUpload;
