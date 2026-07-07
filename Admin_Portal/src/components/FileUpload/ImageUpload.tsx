import React, { useState } from "react";
import { GrCloudUpload } from "react-icons/gr";
import { FileText, X } from "lucide-react";
import { UplaodImage } from "./imageService";
import { toast } from "sonner";

interface FileUploadProps {
  label: string;
  file: string | null;
  folder: string;
  setPreviewImage: (file: string) => void;
  onUploadSuccess: (url: string, fileName: string) => void;
  uploadId?: string;
}

const ImageUpload: React.FC<FileUploadProps> = ({
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
        toast.error(res?.message);
      }
    } catch (err: any) {
      toast.error(err?.response?.data?.message || "An error occurred");
    } finally {
      setIsUploading(false);
    }
  };

  const handleRemove = () => {
    setPreviewImage("");
    onUploadSuccess("", "");
  };

  return (
    <div className="w-full space-y-2">
      <label className="block text-sm font-medium text-foreground">
        {label}
        <span className="text-destructive">*</span>
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
                Upload Image
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
          <div className="rounded-lg border border-border bg-card overflow-hidden">
            <div className="relative group">
              <img
                src={file}
                alt="Preview"
                className="w-full h-48 object-cover"
                onError={(e) => {
                  (e.target as HTMLImageElement).src =
                    "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='400' height='300'%3E%3Crect fill='%23ddd' width='400' height='300'/%3E%3Ctext fill='%23999' font-family='sans-serif' font-size='20' dy='10.5' font-weight='bold' x='50%25' y='50%25' text-anchor='middle'%3EImage not found%3C/text%3E%3C/svg%3E";
                }}
              />
              <div className="absolute top-2 right-2 flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                <button
                  type="button"
                  onClick={handleRemove}
                  className="inline-flex h-8 items-center gap-1 rounded-md bg-destructive px-2 text-xs font-medium text-destructive-foreground hover:opacity-90 shadow-lg"
                  title="Remove Image"
                >
                  <X size={16} />
                  <span>Remove</span>
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ImageUpload;
