import React, { useEffect, useState } from "react";
import { useForm, Controller } from "react-hook-form";
import { yupResolver } from "@hookform/resolvers/yup";
import * as yup from "yup";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { FormInput } from "@/components/forms/FormInput";
import { FormSelect } from "@/components/forms/FormSelect";
import ImageUpload from "@/components/FileUpload/ImageUpload";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "@/store/store";
import {
  bannerAdd,
  editBanner,
  getAllBanners,
  getBannerbyId,
} from "../bannersSlice";
import { AddBanner, Banner } from "../types";
import { toast } from "sonner";
import { Loader2 } from "lucide-react";
// import { set } from "date-fns";

interface BannerFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  banner?: Banner | null;
  mode: "add" | "edit";
  id: string | null;
}

const bannerSchema = yup.object().shape({
  banner: yup.string().required("Banner Image is required"),
  // If you have a name field, add similar validation as below:
  // name: yup
  //   .string()
  //   .required("Name is required")
  //   .matches(/^(?! )[A-Za-z]+( {1,2}[A-Za-z]+)*$/, "Only alphabets, max 2 spaces, no leading spaces"),
  linkUrl: yup
    .string()
    .transform((value, originalValue) =>
      typeof originalValue === "string" && originalValue.trim() === ""
        ? undefined
        : value
    )
    .test(
      "no-leading-space",
      "No leading spaces allowed",
      (value) => !value || !/^\s/.test(value)
    )
    .test(
      "max-two-spaces",
      "No more than 2 consecutive spaces allowed",
      (value) => !value || !/ {3,}/.test(value)
    )
    .matches(/^[A-Za-z0-9:/?&=._\- ]*$/, "Only valid URL characters allowed")
    .url("Must be a valid URL")
    .notRequired(),
  linkType: yup.string().notRequired(),
  isActive: yup.number().oneOf([0, 1]).notRequired(),
});

type BannerFormData = yup.InferType<typeof bannerSchema>;

const linkTypeOptions = [
  { value: "EXTERNAL", label: "External Link" },
  { value: "INTERNAL", label: "Internal Link" },
];

export const BannerFormModal: React.FC<BannerFormModalProps> = ({
  isOpen,
  onClose,
  banner,
  mode,
  id,
}) => {
  const dispatch = useDispatch<AppDispatch>();
  const { loading } = useSelector((state: RootState) => state.banners);
  const [image, setImage] = useState<string>("");
  const [imageUrl, setImageUrl] = useState<string>("");

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    setValue,
    watch,
    control,
  } = useForm<BannerFormData>({
    resolver: yupResolver(bannerSchema),
    defaultValues: {
      banner: "",
      linkUrl: "",
      linkType: "",
      isActive: 1,
    },
  });

  const isActive = watch("isActive");

  useEffect(() => {
    if (mode === "edit" && id) {
      const fetchBannerDetails = async () => {
        try {
          const res = await dispatch(getBannerbyId(id)).unwrap();
          if (res) {
            reset({
              linkUrl: res?.linkUrl,
              linkType: res?.linkType,
              isActive: res?.isActive,
            });
            setImageUrl(res?.banner);
            let imgFile = "";
            if (res?.banner && typeof res.banner === "string") {
              imgFile = res?.banner.split("/").pop() || "";
            }
            setImage(imgFile);
            setValue("banner", imgFile, { shouldValidate: false });
          }
        } catch (error: any) {
          const errorMsg =
            error instanceof Error
              ? error.message
              : typeof error === "string"
                ? error
                : "Failed to fetch banner details";
          toast.error(errorMsg);
        }
      };
      fetchBannerDetails();
    }
  }, [mode, id, reset]);

  const handleImageUploadSuccess = (url: string, fileName: string) => {
    setImage(fileName);
    setImageUrl(url);
    setValue("banner", fileName, { shouldValidate: true });
  };

  const onSubmit = async (data: BannerFormData) => {
    try {
      if (mode === "add") {
        const addData: AddBanner = {
          banner: image,
          linkUrl: data.linkUrl,
          linkType: data.linkType,
        };

        const res = await dispatch(bannerAdd(addData)).unwrap();
        toast.success(res.message);
      } else if (mode === "edit" && id) {
        const res = await dispatch(
          editBanner({
            id: id.toString(),
            data: {
              banner: image,
              linkUrl: data.linkUrl,
              linkType: data.linkType,
              isActive: data.isActive,
            },
          })
        ).unwrap();
        toast.success(res.message);
      }
      await dispatch(getAllBanners());
      handleClose();
    } catch (error: any) {
      const errorMsg =
        error instanceof Error
          ? error.message
          : typeof error === "string"
            ? error
            : "Failed to save banner";
      toast.error(errorMsg);
    }
  };

  const handleClose = () => {
    reset();
    setImage("");
    setImageUrl("");
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-2xl">
            {mode === "add" ? "Create New Banner" : "Edit Banner"}
          </DialogTitle>
          <DialogDescription>
            {mode === "add"
              ? "Add a new promotional banner with redirect link"
              : "Update the banner details"}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-5 py-4">
          <div className="space-y-2">
            <ImageUpload
              label="Banner"
              file={imageUrl}
              folder="banners"
              setPreviewImage={setImageUrl}
              onUploadSuccess={handleImageUploadSuccess}
              uploadId="banner"
            />
            {errors.banner && (
              <p className="text-xs text-destructive flex items-center gap-1">
                {errors.banner.message}
              </p>
            )}
          </div>

          <FormInput
            label="Redirect URL"
            placeholder="https://example.com"
            register={register("linkUrl")}
            error={errors.linkUrl}
            required={false}
            helperText="The URL where users will be redirected when clicking the banner"
            maxConsecutiveSpaces={2}
          />

          <FormSelect
            name="linkType"
            control={control}
            label="Link Type"
            options={linkTypeOptions}
            error={errors.linkType}
            required={false}
            placeholder="Select Link Type"
          />
          {mode === "edit" && (
            <div className="flex items-center justify-between rounded-lg border p-4 bg-muted/30">
              <div className="space-y-0.5">
                <Label htmlFor="isActive" className="text-sm font-medium">
                  Active Status
                </Label>
                <p className="text-xs text-muted-foreground">
                  {isActive === 1
                    ? "Banner is currently active and visible to users"
                    : "Banner is currently inactive and hidden from users"}
                </p>
              </div>
              <Switch
                id="isActive"
                checked={isActive === 1}
                onCheckedChange={(checked) =>
                  setValue("isActive", checked ? 1 : 0)
                }
              />
            </div>
          )}
          <DialogFooter className="mt-6 pt-4 border-t flex gap-3 flex-row justify-end">
            <Button
              type="button"
              variant="outline"
              onClick={handleClose}
              disabled={loading}
              className="min-w-24"
            >
              Cancel
            </Button>
            <Button
              type="submit"
              className="bg-success hover:bg-success/90 min-w-24"
              disabled={loading}
            >
              {loading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  {mode === "add" ? "Creating..." : "Updating..."}
                </>
              ) : mode === "add" ? (
                "Create"
              ) : (
                "Update"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
};
