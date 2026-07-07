import React, { useState } from "react";
import { GrCloudUpload } from "react-icons/gr";
import { FileText, Eye, X } from "lucide-react";
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

const FileUpload: React.FC<FileUploadProps> = ({
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
    const allowedTypes = ["image/png", "image/jpeg", "image/webp"];

    if (!selectedFile) return;

    if (!allowedTypes.includes(selectedFile.type)) {
      setError("Only *.jpeg, *.png, *.webp files are accepted.");
      return;
    }

    setError(null);
    setIsUploading(true);

    const formData = new FormData();
    formData.append("file", selectedFile);
    formData.append("folder", folder);

    try {
      const res = await UplaodImage(formData);
      if (res?.data?.status === 1 || res?.data?.Status === 1) {
        const filename = res?.data?.fileName;
        const url = res?.data?.fileUrl;
        setPreviewImage(filename);
        onUploadSuccess(url, filename);
      } else {
        ErrorMessage(res?.data?.message || res?.message);
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
    <div className="w-full space-y-2">
      <label className="block text-sm font-medium text-foreground">
        {label}
      </label>
      <div className="w-full">
        {!file ? (
          <>
            <input
              type="file"
              accept="image/jpeg,image/png,image/webp"
              onChange={handleFileChange}
              className="hidden"
              id={`doc-file-upload-${uploadId}`}
              disabled={isUploading}
            />
            <label
              htmlFor={`doc-file-upload-${uploadId}`}
              className="group flex w-full cursor-pointer flex-col items-center justify-center gap-2 rounded-lg border border-dashed border-border bg-background p-6 text-center transition-colors hover:border-primary/50 hover:bg-muted"
            >
              <div className="mb-2 flex items-center text-muted-foreground">
                <GrCloudUpload size={32} />
              </div>
              <span className="text-sm font-medium text-foreground">
                Upload and Crop Image
              </span>
              <span className="text-xs text-muted-foreground">
                (Only *.jpeg, *.png, *.webp will be accepted)
              </span>
            </label>
            {error && (
              <div className="mt-2 text-xs text-destructive">{error}</div>
            )}
          </>
        ) : (
          <div className="rounded-lg border border-border bg-card">
            <div className="flex items-center justify-between gap-3 border-b px-3 py-2">
              <div className="flex min-w-0 items-center gap-2">
                <FileText className="h-4 w-4 text-muted-foreground" />
                <span className="truncate text-sm text-foreground">{file}</span>
              </div>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={togglePreview}
                  className="inline-flex h-8 items-center gap-1 rounded-md border border-input bg-background px-2 text-xs font-medium text-foreground hover:bg-muted"
                  title="Preview Image"
                >
                  <Eye size={16} />
                  <span>Preview</span>
                </button>
                <button
                  type="button"
                  onClick={handleRemove}
                  className="inline-flex h-8 items-center gap-1 rounded-md bg-destructive px-2 text-xs font-medium text-destructive-foreground hover:opacity-90"
                  title="Remove Image"
                >
                  <X size={16} />
                  <span>Remove</span>
                </button>
              </div>
            </div>
            {showPreview && (
              <div className="px-3 py-3">
                <img
                  src={file}
                  alt="Preview"
                  className="max-h-28 w-auto rounded-md object-contain ring-1 ring-border"
                />
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default FileUpload;
