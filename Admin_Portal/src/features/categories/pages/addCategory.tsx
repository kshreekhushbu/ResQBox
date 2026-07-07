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
  categoryAdd,
  editCategory,
  getAllCategories,
  fetchCategorybyId,
} from "../categoriesSlice";
import { AddCategory, Category } from "../types";
import { toast } from "sonner";
import { Loader2, Star } from "lucide-react";

interface CategoryFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  category?: Category | null;
  mode: "add" | "edit";
  id: string | null;
}

const categorySchema = yup.object().shape({
  name: yup
    .string()
    .required("Category name is required")
    .test("no-leading-space", "No leading spaces allowed", noLeadingSpace)
    .test(
      "max-two-spaces",
      "No more than 2 consecutive spaces allowed",
      maxTwoSpaces
    )
    .matches(nameRegex, "Only alphabets, max 2 spaces, no leading spaces"),
  image: yup.string().when("isPopular", {
    is: 1,
    then: (schema) => schema.required("Image is required when marked as popular"),
    otherwise: (schema) => schema.optional(),
  }),
  isActive: yup.number().required(),
  isPopular: yup.number().required(),
});

type CategoryFormData = yup.InferType<typeof categorySchema>;

export const CategoryFormModal: React.FC<CategoryFormModalProps> = ({
  isOpen,
  onClose,
  category,
  mode,
  id,
}) => {
  const dispatch = useDispatch<AppDispatch>();
  const { loading } = useSelector((state: RootState) => state.categories);
  const [imagePreview, setImagePreview] = useState<string>("");
  const [imageUrl, setImageUrl] = useState<string>("");

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    setValue,
    watch,
  } = useForm<CategoryFormData>({
    resolver: yupResolver(categorySchema),
    defaultValues: {
      name: "",
      image: "",
      isActive: 1,
      isPopular: 0,
    },
  });

  const isActive = watch("isActive");
  const isPopular = watch("isPopular");

  useEffect(() => {
    if (mode === "edit" && id) {
      const fetchCategoryDetails = async () => {
        try {
          const res = await dispatch(fetchCategorybyId(id)).unwrap();
          if (res) {
            let imgFile = "";
            if (res?.image && typeof res.image === "string") {
              setImageUrl(res?.image);
              imgFile = res?.image.split("/").pop() || "";
              setImagePreview(imgFile);
            }

            reset({
              name: res?.name,
              isActive: res?.isActive,
              isPopular: res?.isPopular ?? 0,
              image: imgFile,
            });
          }
        } catch (error: any) {
          const errorMsg =
            error instanceof Error
              ? error.message
              : typeof error === "string"
                ? error
                : "Failed to fetch category details";
          toast.error(errorMsg);
        }
      };
      fetchCategoryDetails();
    }
  }, [mode, id, reset, dispatch]);

  useEffect(() => {
    if (isPopular === 0) {
      setValue("image", "");
      setImagePreview("");
      setImageUrl("");
    }
  }, [isPopular, setValue]);

  const onSubmit = async (data: CategoryFormData) => {
    try {
      if (mode === "add") {
        const addData: AddCategory = {
          name: data.name,
          image: data.image || "",
          isActive: data.isActive,
          isPopular: data.isPopular,
        };

        const res = await dispatch(categoryAdd(addData)).unwrap();
        toast.success(res.message || "Category added successfully");
      } else if (mode === "edit" && category) {
        const res = await dispatch(
          editCategory({
            id: category.id.toString(),
            data: {
              name: data.name,
              image: data.image || imagePreview,
              isActive: data.isActive,
              isPopular: data.isPopular,
            },
          })
        ).unwrap();
        toast.success(res.message || "Category updated successfully");
      }
      await dispatch(getAllCategories({ page: 1, limit: 10 }));
      handleClose();
    } catch (error: any) {
      const errorMsg =
        error instanceof Error
          ? error.message
          : typeof error === "string"
            ? error
            : "Failed to save category";
      toast.error(errorMsg);
    }
  };

  const handleClose = () => {
    reset();
    setImagePreview("");
    setImageUrl("");
    onClose();
  };

  const handleImageUploadSuccess = (url: string, fileName: string) => {
    setImageUrl(url);
    setValue("image", fileName, { shouldValidate: true });
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-2xl">
            {mode === "add" ? "Create New Category" : "Edit Category"}
          </DialogTitle>
          <DialogDescription>
            {mode === "add"
              ? "Add a new category for your platform"
              : "Update the category details"}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6 py-4">
          <FormInput
            label="Category Name"
            placeholder="e.g., Veg, Non-Veg, Desserts"
            register={register("name", {
              setValueAs: normalizeInput,
            })}
            error={errors.name}
            required={true}
            helperText="Enter a descriptive name for the category"
            alphaSpacesOnly
            maxConsecutiveSpaces={2}
          />

          <div className="flex items-center justify-between rounded-lg border border-zinc-200 dark:border-zinc-800 p-4 bg-zinc-50 dark:bg-zinc-900/50">
            <div className="space-y-0.5">
              <div className="flex items-center gap-2">
                <Star className="h-4 w-4 text-amber-500 fill-amber-500" />
                <Label htmlFor="isPopular" className="text-sm font-semibold text-foreground">
                  Filter Header
                </Label>
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                {isPopular === 1
                  ? "This category will be added to Filter Header"
                  : "Enable to mark this as a Filter Header"}
              </p>
            </div>
            <Switch
              id="isPopular"
              checked={isPopular === 1}
              onCheckedChange={(checked) =>
                setValue("isPopular", checked ? 1 : 0, { shouldValidate: true })
              }
            />
          </div>

          {isPopular === 1 && (
            <div className="space-y-2 animate-in fade-in slide-in-from-top-2 duration-300">
              <ImageUpload
                label="Category Image"
                file={imageUrl || null}
                folder="categories"
                setPreviewImage={setImagePreview}
                onUploadSuccess={handleImageUploadSuccess}
                uploadId="category-image"
              />
              {errors.image && (
                <p className="text-xs text-destructive font-medium">{errors.image.message}</p>
              )}
            </div>
          )}

          {mode === "edit" && (
            <div className="flex items-center justify-between rounded-lg border border-zinc-200 dark:border-zinc-800 p-4 bg-zinc-50 dark:bg-zinc-900/50">
              <div className="space-y-0.5">
                <Label htmlFor="isActive" className="text-sm font-semibold text-foreground">
                  Active Status
                </Label>
                <p className="text-xs text-muted-foreground mt-1">
                  {isActive === 1
                    ? "Category is currently active and visible"
                    : "Category is currently inactive and hidden"}
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

          <DialogFooter className="mt-8 pt-4 border-t flex gap-3 flex-row justify-end">
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
              className="bg-success hover:bg-success/90 min-w-24 text-white font-medium"
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
