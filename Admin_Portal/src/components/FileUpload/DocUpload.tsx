import React, { useState } from "react";
import { GrCloudUpload } from "react-icons/gr";
import { FileText, Eye, X } from "lucide-react";
import { ErrorMessage } from "@/utils/Toast";
import { UplaodImage } from "./imageService";
import styles from "./DocUpload.module.css";

interface FileUploadProps {
  label: string;
  file: string | null;
  folder: string;
  setPreviewImage: (file: string) => void;
  onUploadSuccess: (url: string, fileName: string) => void;
  uploadId?: string;
}

const DocUpload: React.FC<FileUploadProps> = ({
  file,
  label,
  folder,
  setPreviewImage,
  onUploadSuccess,
  uploadId = "default",
}) => {
  const [error, setError] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [showPreview, setShowPreview] = useState(false);

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0];
    const allowedTypes = ["application/pdf"];

    if (!selectedFile) return;

    if (!allowedTypes.includes(selectedFile.type)) {
      setError("Only *.pdf files are accepted.");
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
    setShowPreview(false);
    onUploadSuccess("", "");
  };

  const togglePreview = () => {
    setShowPreview(!showPreview);
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
                  onClick={togglePreview}
                  className={styles["doc-preview-view-btn"]}
                  title="Preview Document"
                >
                  <Eye size={16} />
                  <span>Preview</span>
                </button>
                <button
                  type="button"
                  onClick={handleRemove}
                  className={styles["doc-preview-delete-btn"]}
                  title="Remove Document"
                >
                  <X size={16} />
                  <span>Remove</span>
                </button>
              </div>
            </div>

            {showPreview && (
              <div className={styles["doc-preview-overlay"]}>
                <div className={styles["doc-preview-dialog"]}>
                  <div className={styles["doc-preview-dialog-header"]}>
                    <h4>Document Preview</h4>
                    <button
                      type="button"
                      onClick={togglePreview}
                      className={styles["doc-preview-close-btn"]}
                    >
                      <X size={20} />
                    </button>
                  </div>
                  <div className={styles["doc-preview-content-area"]}>
                    <iframe
                      src={`${file}#toolbar=0&navpanes=0&scrollbar=0`}
                      title="Document Preview"
                      className={styles["doc-preview-iframe-view"]}
                    />
                  </div>
                </div>
              </div>
            )}
          </div>
        ) : (
          <>
            <input
              type="file"
              accept="application/pdf"
              onChange={handleFileChange}
              className={styles["doc-file-input-field"]}
              id={`doc-file-upload-${uploadId}`}
              disabled={isUploading}
              style={{ display: "none" }}
            />
            <label
              htmlFor={`doc-file-upload-${uploadId}`}
              className={styles["doc-upload-drop-zone"]}
            >
              <GrCloudUpload size={40} />
              <span className={styles["doc-upload-instruction"]}>
                {isUploading ? "Uploading..." : "Drag Your Files Here"}
              </span>
              <span className={styles["doc-upload-file-types"]}>
                (Only *.pdf will be accepted)
              </span>
            </label>
            {error && <div className={styles["doc-upload-error"]}>{error}</div>}
          </>
        )}
      </div>
    </div>
  );
};

export default DocUpload;
