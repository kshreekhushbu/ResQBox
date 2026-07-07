import { useEffect, useState } from "react";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Plus,
  Pencil,
  Trash2,
  ExternalLink,
  Loader2,
  AlertCircle,
} from "lucide-react";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "@/store/store";
import { getAllBanners, removeBanner } from "../bannersSlice";
import { Banner } from "../types";
import { BannerFormModal } from "./addBanner";
import { ConfirmationModal } from "@/components/modals/ConfirmationModal";
import { toast } from "sonner";
import { ErrorDisplay } from "@/components/ErrorDisplay/ErrorDisplay";
import { useNavigate } from "react-router-dom";
import { usePermissions } from "@/hooks/usePermissions";

const Banners: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const navigate = useNavigate();
  const permissions = usePermissions("banners");
  const { banners, loading, error } = useSelector(
    (state: RootState) => state.banners
  );

  const [isFormModalOpen, setIsFormModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [selectedBanner, setSelectedBanner] = useState<Banner | null>(null);
  const [modalMode, setModalMode] = useState<"add" | "edit">("add");
  const [isDeleting, setIsDeleting] = useState(false);
  const [id, setId] = useState<string>("");

  // Check read permission on mount
  useEffect(() => {
    if (!permissions.hasRead) {
      navigate("/403", { replace: true });
    }
  }, [permissions.hasRead, navigate]);

  useEffect(() => {
    fetchBanners();
  }, []);

  const fetchBanners = async () => {
    try {
      await dispatch(getAllBanners()).unwrap();
    } catch (error: any) {
      const errorMsg =
        error instanceof Error
          ? error.message
          : typeof error === "string"
            ? error
            : "Failed to fetch banners";
      toast.error(errorMsg);
    }
  };

  const handleAddBanner = () => {
    if (!permissions.checkWrite()) {
      return;
    }
    setModalMode("add");
    setId(null);
    setIsFormModalOpen(true);
  };

  const handleEditBanner = (id: string) => {
    if (!permissions.checkEdit()) {
      return;
    }
    setId(id);
    setModalMode("edit");
    setIsFormModalOpen(true);
  };

  const handleDeleteClick = (id: string) => {
    if (!permissions.checkDelete()) {
      return;
    }
    setId(id);
    setIsDeleteModalOpen(true);
  };

  const handleDeleteConfirm = async () => {
    if (!id) return;

    setIsDeleting(true);
    try {
      const res = await dispatch(removeBanner(id)).unwrap();
      toast.success(res.message);
      setIsDeleteModalOpen(false);
      setId(null);
      await dispatch(getAllBanners());
    } catch (error: any) {
      const errorMsg =
        error instanceof Error
          ? error.message
          : typeof error === "string"
            ? error
            : "Failed to delete banner";
      toast.error(errorMsg);
    } finally {
      setIsDeleting(false);
    }
  };

  const handleCloseFormModal = () => {
    setIsFormModalOpen(false);
    setSelectedBanner(null);
  };

  const handleCloseDeleteModal = () => {
    setIsDeleteModalOpen(false);
    setSelectedBanner(null);
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div className="text-sm text-muted-foreground">
          Total Banners:{" "}
          <span className="font-semibold text-foreground">
            {banners.length}
          </span>
        </div>
        <Button
          onClick={handleAddBanner}
          className="bg-warning hover:bg-warning/90 text-warning-foreground"
          disabled={loading}
        >
          <Plus className="mr-2 h-4 w-4" />
          Add New Banner
        </Button>
      </div>
      {error && <ErrorDisplay message={error} getdata={fetchBanners} />}
      {loading && banners.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-12">
          <Loader2 className="h-12 w-12 animate-spin text-primary" />
          <p className="mt-4 text-sm text-muted-foreground">
            Loading banners...
          </p>
        </div>
      ) : banners.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-12 rounded-lg border-2 border-dashed">
          <div className="rounded-full bg-muted p-3 mb-4">
            <Plus className="h-8 w-8 text-muted-foreground" />
          </div>
          <h3 className="text-lg font-semibold mb-2">No banners yet</h3>
          <p className="text-sm text-muted-foreground mb-4">
            Get started by creating your first promotional banner
          </p>
          <Button
            onClick={handleAddBanner}
            className="bg-warning hover:bg-warning/90"
          >
            <Plus className="mr-2 h-4 w-4" />
            Create First Banner
          </Button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {banners.map((banner: Banner) => (
            <Card
              key={banner.bannerId}
              className="hover-lift card-shadow overflow-hidden"
            >
              <CardContent className="p-0">
                <div className="aspect-video bg-gradient-to-br from-primary/20 to-secondary/20 relative overflow-hidden">
                  {banner.banner ? (
                    <img
                      src={banner.banner}
                      alt="Banner"
                      className="w-full h-full object-cover"
                      onError={(e) => {
                        (e.target as HTMLImageElement).src =
                          "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='400' height='300'%3E%3Crect fill='%23ddd' width='400' height='300'/%3E%3Ctext fill='%23999' font-family='sans-serif' font-size='20' dy='10.5' font-weight='bold' x='50%25' y='50%25' text-anchor='middle'%3EBanner Image%3C/text%3E%3C/svg%3E";
                      }}
                    />
                  ) : (
                    <div className="flex items-center justify-center h-full">
                      <p className="text-sm text-muted-foreground">
                        No Image
                      </p>
                    </div>
                  )}
                  <div className="absolute top-2 right-2">
                    <Badge
                      variant={
                        banner.isActive === 1 ? "default" : "secondary"
                      }
                    >
                      {banner.isActive === 1 ? "Active" : "Inactive"}
                    </Badge>
                  </div>
                </div>
                <div className="p-4 space-y-3 flex flex-col h-full">
                  <div className="flex-1">
                    {banner?.linkUrl !== null && banner?.linkUrl !== "NA" ? (
                      <>
                        <a
                          href={banner?.linkUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-sm text-primary hover:underline flex items-center gap-1 break-all"
                        >
                          <span className="line-clamp-1">
                            {banner.linkUrl}
                          </span>
                          <ExternalLink className="h-3 w-3 flex-shrink-0" />
                        </a>
                      </>
                    ) : (
                      ""
                    )}
                  </div>
                  <p className="text-xs text-muted-foreground">
                    Type:{" "}
                    <span className="capitalize">{banner.linkType}</span>
                  </p>
                  <div className="flex gap-2 pt-2 mt-auto">
                    <Button
                      variant="outline"
                      size="sm"
                      className="flex-1"
                      onClick={() =>
                        handleEditBanner(String(banner.bannerId))
                      }
                    >
                      <Pencil className="h-3 w-3 mr-1" />
                      Edit
                    </Button>
                    <Button
                      variant="destructive"
                      size="sm"
                      onClick={() =>
                        handleDeleteClick(String(banner.bannerId))
                      }
                    >
                      <Trash2 className="h-3 w-3" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <BannerFormModal
        isOpen={isFormModalOpen}
        onClose={handleCloseFormModal}
        id={id}
        mode={modalMode}
      />

      <ConfirmationModal
        isOpen={isDeleteModalOpen}
        onClose={handleCloseDeleteModal}
        onConfirm={handleDeleteConfirm}
        title="Delete Banner"
        description={`Are you sure you want to delete this banner? This action cannot be undone.`}
        confirmText="Delete"
        cancelText="Cancel"
        type="danger"
        isLoading={isDeleting}
      />
    </div >
  );
};

export default Banners;
