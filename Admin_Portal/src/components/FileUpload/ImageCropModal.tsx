import React, { useState, useRef, useCallback, useEffect } from "react";
import ReactCrop, { Crop, PixelCrop } from "react-image-crop";
import "react-image-crop/dist/ReactCrop.css";
import Fileclasses from "./File.module.css";

interface ImageCropModalProps {
  isOpen: boolean;
  onClose: () => void;
  imageSrc: string;
  onCropComplete: (croppedImageBlob: Blob) => void;
}

const ImageCropModal: React.FC<ImageCropModalProps> = ({
  isOpen,
  onClose,
  imageSrc,
  onCropComplete,
}) => {
  const [crop, setCrop] = useState<Crop>();
  const [completedCrop, setCompletedCrop] = useState<PixelCrop>();
  const [isProcessing, setIsProcessing] = useState(false);
  const imgRef = useRef<HTMLImageElement>(null);
  const previewCanvasRef = useRef<HTMLCanvasElement>(null);

  const onImageLoad = useCallback(() => {
    // Don't set any initial crop - let user see full image and drag freely
    setCrop(undefined);
  }, []);

  // Upload original image without cropping
  const onUploadOriginalClick = useCallback(() => {
    if (!imgRef.current || isProcessing) return;
    setIsProcessing(true);
    // Convert image src to blob
    fetch(imageSrc)
      .then((res) => res.blob())
      .then((blob) => {
        onCropComplete(blob);
        onClose();
      })
      .catch(() => setIsProcessing(false));
  }, [imageSrc, onCropComplete, onClose, isProcessing]);

  const onDownloadCropClick = useCallback(() => {
    if (isProcessing) return;
    setIsProcessing(true);
    // If crop is selected, process crop
    if (completedCrop && previewCanvasRef.current && imgRef.current) {
      const canvas = previewCanvasRef.current;
      const image = imgRef.current;
      const crop = completedCrop;
      const scaleX = image.naturalWidth / image.width;
      const scaleY = image.naturalHeight / image.height;
      const ctx = canvas.getContext("2d");
      if (!ctx) {
        setIsProcessing(false);
        throw new Error("No 2d context");
      }
      canvas.width = Math.round(crop.width * scaleX);
      canvas.height = Math.round(crop.height * scaleY);
      ctx.imageSmoothingEnabled = false;
      ctx.imageSmoothingQuality = "high";
      ctx.drawImage(
        image,
        Math.round(crop.x * scaleX),
        Math.round(crop.y * scaleY),
        Math.round(crop.width * scaleX),
        Math.round(crop.height * scaleY),
        0,
        0,
        Math.round(crop.width * scaleX),
        Math.round(crop.height * scaleY)
      );
      canvas.toBlob(
        (blob) => {
          if (blob) {
            onCropComplete(blob);
            onClose();
          } else {
            setIsProcessing(false);
          }
        },
        "image/png",
        undefined
      );
    } else {
      // No crop selected, upload original image
      fetch(imageSrc)
        .then((res) => res.blob())
        .then((blob) => {
          onCropComplete(blob);
          onClose();
        })
        .catch(() => setIsProcessing(false));
    }
  }, [completedCrop, onCropComplete, onClose, isProcessing, imageSrc]);

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!isOpen) return;

      switch (e.key) {
        case "Escape":
          onClose();
          break;
        case "Enter":
          if (completedCrop) {
            onDownloadCropClick();
          }
          break;
      }
    };

    if (isOpen) {
      document.addEventListener("keydown", handleKeyDown);
      return () => document.removeEventListener("keydown", handleKeyDown);
    }
  }, [isOpen, onClose, completedCrop, onDownloadCropClick]);

  if (!isOpen) return null;

  const handleOverlayClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      handleClose();
    }
  };

  const handleClose = () => {
    setIsProcessing(false);
    onClose();
  };

  return (
    <div className={Fileclasses.modalOverlay} onClick={handleOverlayClick}>
      <div
        className={Fileclasses.modalContent}
        onClick={(e) => e.stopPropagation()}
      >
        <div className={Fileclasses.modalHeader}>
          <div>
            <h3>Crop Image</h3>
          </div>
          <button className={Fileclasses.closeButton} onClick={handleClose}>
            ×
          </button>
        </div>

        <div className={Fileclasses.cropperContainer}>
          <ReactCrop
            crop={crop}
            onChange={(_, percentCrop) => setCrop(percentCrop)}
            onComplete={(c) => setCompletedCrop(c)}
            aspect={undefined}
            minWidth={50}
            minHeight={50}
          >
            <img
              ref={imgRef}
              alt="Crop me"
              src={imageSrc}
              style={{
                width: "100%",
                height: "100%",
                objectFit: "contain",
              }}
              onLoad={onImageLoad}
            />
          </ReactCrop>
        </div>

        <div className={Fileclasses.modalActions}>
          <button className={Fileclasses.cancelButton} onClick={handleClose}>
            Cancel
          </button>
          <button
            className={Fileclasses.cropButton}
            onClick={onDownloadCropClick}
            disabled={isProcessing}
          >
            {isProcessing ? "Processing..." : "Upload"}
          </button>
        </div>

        {/* Hidden canvas for processing */}
        <canvas
          ref={previewCanvasRef}
          style={{
            display: "none",
          }}
        />
      </div>
    </div>
  );
};

export default ImageCropModal;
