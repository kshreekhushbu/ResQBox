import React, { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { yupResolver } from "@hookform/resolvers/yup";
import * as yup from "yup";
import {
  nameRegex,
  noLeadingSpace,
  maxTwoSpaces,
  normalizeInput,
} from "@/lib/utils";
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
import ImageUpload from "@/components/FileUpload/ImageUpload";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "@/store/store";
import {
  cuisineAdd,
  editCuisine,
  getAllCuisines,
  fetchCuisinebyId,
} from "../cuisinesSlice";
import { AddCuisine, Cuisine } from "../types";
import { toast } from "sonner";
import { Loader2 } from "lucide-react";

interface CuisineFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  cuisine?: Cuisine | null;
  mode: "add" | "edit";
  id: string | null;
}

const cuisineSchema = yup.object().shape({
  name: yup
    .string()
    .required("Cuisine name is required")
    .test("no-leading-space", "No leading spaces allowed", noLeadingSpace)
    .test(
      "max-two-spaces",
      "No more than 2 consecutive spaces allowed",
      maxTwoSpaces
    )
    .matches(nameRegex, "Only alphabets, max 2 spaces, no leading spaces"),
  isActive: yup.number().required(),
  is_popular: yup.number().default(0),
  image: yup.string().when("is_popular", {
    is: (val: number) => val === 1,
    then: (schema) => schema.required("Cuisine image is required when popular"),
    otherwise: (schema) => schema.optional(),
  }),
});

type CuisineFormData = yup.InferType<typeof cuisineSchema>;

export const CuisineFormModal: React.FC<CuisineFormModalProps> = ({
  isOpen,
  onClose,
  cuisine,
  mode,
  id,
}) => {
  const dispatch = useDispatch<AppDispatch>();
  const { loading } = useSelector((state: RootState) => state.cuisines);
  const [image, setImage] = useState<string>("");
  const [imageUrl, setImageUrl] = useState<string>("");

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    setValue,
    watch,
  } = useForm<CuisineFormData>({
    resolver: yupResolver(cuisineSchema),
    defaultValues: {
      name: "",
      image: "",
      isActive: 1,
      is_popular: 0,
    },
  });

  const isActive = watch("isActive");
  const isPopular = watch("is_popular");

  useEffect(() => {
    if (mode === "edit" && id) {
      const fetchCuisineDetails = async () => {
        try {
          const res = await dispatch(fetchCuisinebyId(id)).unwrap();
          if (res) {
            reset({
              name: res?.name,
              isActive: res?.isActive,
              is_popular: res?.is_popular || 0,
            });
            setImageUrl(res?.image);
            let imgFile = "";
            if (res?.image && typeof res.image === "string") {
              imgFile = res?.image.split("/").pop() || "";
            }
            setImage(imgFile);
          }
        } catch (error: any) {
          const errorMsg =
            error instanceof Error
              ? error.message
              : typeof error === "string"
                ? error
                : "Failed to fetch cuisine details";
          toast.error(errorMsg);
        }
      };
      fetchCuisineDetails();
    }
  }, [mode, id, reset, dispatch]);

  useEffect(() => {
    if (isPopular === 0) {
      setValue("image", "");
      setImage("");
      setImageUrl("");
    }
  }, [isPopular, setValue]);

  const handleImageUploadSuccess = (url: string, fileName: string) => {
    setImage(fileName);
    setImageUrl(url);
    setValue("image", fileName, { shouldValidate: true });
  };

  const onSubmit = async (data: CuisineFormData) => {
    try {
      if (mode === "add") {
        const addData: AddCuisine = {
          name: data.name,
          image: image,
          isActive: data.isActive,
          is_popular: data.is_popular,
        };

        const res = await dispatch(cuisineAdd(addData)).unwrap();
        toast.success(res.message || "Cuisine added successfully");
      } else if (mode === "edit" && cuisine) {
        const res = await dispatch(
          editCuisine({
            id: cuisine.id.toString(),
            data: {
              name: data.name,
              image: image,
              isActive: data.isActive,
              is_popular: data.is_popular,
            },
          })
        ).unwrap();
        toast.success(res.message || "Cuisine updated successfully");
      }
      await dispatch(getAllCuisines({ page: 1, limit: 10 }));
      handleClose();
    } catch (error: any) {
      const errorMsg =
        error instanceof Error
          ? error.message
          : typeof error === "string"
            ? error
            : "Failed to save cuisine";
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
            {mode === "add" ? "Create New Cuisine" : "Edit Cuisine"}
          </DialogTitle>
          <DialogDescription>
            {mode === "add"
              ? "Add a new cuisine for restaurants"
              : "Update the cuisine details"}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-5 py-4">
          <FormInput
            label="Cuisine Name"
            placeholder="e.g., South Indian, Italian, Chinese"
            register={register("name", {
              setValueAs: normalizeInput,
            })}
            error={errors.name}
            required={true}
            helperText="Enter a descriptive name for the cuisine"
            alphaSpacesOnly
            maxConsecutiveSpaces={2}
          />
          <div className="flex items-center justify-between rounded-lg border p-4 bg-muted/30">
            <div className="space-y-0.5">
              <Label htmlFor="is_popular" className="text-sm font-medium">
                Popular Cuisine
              </Label>
              <p className="text-xs text-muted-foreground">
                {isPopular === 1
                  ? "Cuisine is marked as popular (Image Required)"
                  : "Cuisine is not marked as popular"}
              </p>
            </div>
            <Switch
              id="is_popular"
              checked={isPopular === 1}
              onCheckedChange={(checked) =>
                setValue("is_popular", checked ? 1 : 0)
              }
            />
          </div>
          {isPopular === 1 && (
            <div className="space-y-2">
              <ImageUpload
                label="Cuisine Image"
                file={imageUrl}
                folder="cuisines"
                setPreviewImage={setImageUrl}
                onUploadSuccess={handleImageUploadSuccess}
                uploadId="cuisine"
              />
              {errors.image && (
                <p className="text-xs text-destructive flex items-center gap-1">
                  {errors.image.message}
                </p>
              )}
            </div>
          )}

          {mode === "edit" && (
            <div className="flex items-center justify-between rounded-lg border p-4 bg-muted/30">
              <div className="space-y-0.5">
                <Label htmlFor="isActive" className="text-sm font-medium">
                  Active Status
                </Label>
                <p className="text-xs text-muted-foreground">
                  {isActive === 1
                    ? "Cuisine is currently active and visible"
                    : "Cuisine is currently inactive and hidden"}
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
