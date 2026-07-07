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
  createFoodTypeThunk,
  updateFoodTypeThunk,
  getAllFoodTypesThunk,
  getFoodTypeByIdThunk,
} from "../foodTypesSlice";
import { AddFoodType, FoodType } from "../types";
import { toast } from "sonner";
import { Loader2 } from "lucide-react";

interface FoodTypeFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  foodType?: FoodType | null;
  mode: "add" | "edit";
  id: string | null;
}

const foodTypeSchema = yup.object().shape({
  name: yup
    .string()
    .required("Food type name is required")
    .test("no-leading-space", "No leading spaces allowed", noLeadingSpace)
    .test(
      "max-two-spaces",
      "No more than 2 consecutive spaces allowed",
      maxTwoSpaces
    )
    .matches(nameRegex, "Only alphabets, max 2 spaces, no leading spaces"),
  question: yup
    .string()
    .required("Question is required")
    .test("no-leading-space", "No leading spaces allowed", noLeadingSpace)
    .min(3, "Question must be at least 3 characters"),
  image: yup.string().optional(),
  isActive: yup.number().required(),
});

type FoodTypeFormData = yup.InferType<typeof foodTypeSchema>;

export const FoodTypeFormModal: React.FC<FoodTypeFormModalProps> = ({
  isOpen,
  onClose,
  foodType,
  mode,
  id,
}) => {
  const dispatch = useDispatch<AppDispatch>();
  const { loading } = useSelector((state: RootState) => state.foodTypes);
  const [image, setImage] = useState<string>("");
  const [imageUrl, setImageUrl] = useState<string>("");

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    setValue,
    watch,
  } = useForm<FoodTypeFormData>({
    resolver: yupResolver(foodTypeSchema),
    defaultValues: {
      name: "",
      image: "",
      question: "",
      isActive: 0,
    },
  });

  const isActive = watch("isActive");

  useEffect(() => {
    if (mode === "edit" && id) {
      const fetchFoodTypeDetails = async () => {
        try {
          const res = await dispatch(getFoodTypeByIdThunk(id)).unwrap();
          if (res && res.name && res.image) {
            reset({
              name: res.name,
              isActive: res.isActive || 0,
              question: res.question || "",
            });
            setImageUrl(res.image);
            let imgFile = res.image.split("/").pop() || "";
            setImage(imgFile);
            setValue("image", imgFile, { shouldValidate: false });
          }
        } catch (error: any) {
          const errorMsg =
            error instanceof Error
              ? error.message
              : typeof error === "string"
                ? error
                : "Failed to fetch food type details";
          toast.error(errorMsg);
        }
      };
      fetchFoodTypeDetails();
    }
  }, [mode, id, reset, dispatch]);

  const handleImageUploadSuccess = (url: string, fileName: string) => {
    setImage(fileName);
    setImageUrl(url);
    setValue("image", fileName, { shouldValidate: true });
  };

  const onSubmit = async (data: FoodTypeFormData) => {
    try {


      if (mode === "add") {
        const addData: AddFoodType = {
          name: data.name,
          question: data.question,
          image: image,

        };

        const result = await dispatch(createFoodTypeThunk(addData)).unwrap();
        if (result) {
          toast.success(result.message);
          await dispatch(getAllFoodTypesThunk({ page: 1, limit: 10 })).unwrap();
          handleClose();
        }
      } else if (mode === "edit" && id) {
        const result = await dispatch(
          updateFoodTypeThunk({
            id: id,
            data: {
              name: data.name,
              image: image,
              question: data.question,
              isActive: data.isActive || 0,
            },
          })
        ).unwrap();
        if (result) {
          toast.success("Food type updated successfully");
          await dispatch(getAllFoodTypesThunk({ page: 1, limit: 10 })).unwrap();
          handleClose();
        }
      }
    } catch (error: any) {
      const errorMsg =
        error instanceof Error
          ? error.message
          : typeof error === "string"
            ? error
            : "Failed to save food type";
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
            {mode === "add" ? "Create New Restaurant Type" : "Edit Restaurant Type"}
          </DialogTitle>
          <DialogDescription>
            {mode === "add"
              ? "Add a new restaurant type with image"
              : "Update the restaurant type details"}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-5 py-4">
          <div className="space-y-2">
            <ImageUpload
              label="Restaurant Type Image"
              file={imageUrl}
              folder="categories"
              setPreviewImage={setImageUrl}
              onUploadSuccess={handleImageUploadSuccess}
              uploadId="foodType"
            />
            {errors.image && (
              <p className="text-xs text-destructive flex items-center gap-1">
                {errors.image.message}
              </p>
            )}
          </div>

          <FormInput
            label="Restaurant Type Name"
            placeholder="e.g., Vegetarian, Non-Vegetarian"
            register={register("name", {
              setValueAs: normalizeInput,
            })}
            error={errors.name}
            required
            alphaSpacesOnly
            maxConsecutiveSpaces={2}
          />
          <FormInput
            label="Question"
            placeholder="Enter Question"
            register={register("question")}
            error={errors.question}
            required
            skipNormalize
          />

          {mode === "edit" && (
            <div className="flex items-center justify-between rounded-lg border p-4 bg-muted/30">
              <div className="space-y-0.5">
                <Label htmlFor="isActive" className="text-sm font-medium">
                  Active Status
                </Label>
                <p className="text-xs text-muted-foreground">
                  {isActive === 1
                    ? "Food type is currently active and visible"
                    : "Food type is currently inactive and hidden"}
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
