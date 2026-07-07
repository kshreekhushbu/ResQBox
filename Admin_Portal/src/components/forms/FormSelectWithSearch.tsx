import * as React from "react";
import { Controller, Control, FieldError } from "react-hook-form";
import { SelectWithSearch, SelectOption } from "./SelectWithSearch";
import { Label } from "@/components/ui/label";
import { AlertCircle } from "lucide-react";
import { cn } from "@/lib/utils";

export interface FormSelectWithSearchProps {
  name: string;
  control: Control<any>;
  options: SelectOption[];
  label?: string;
  placeholder?: string;
  searchPlaceholder?: string;
  error?: FieldError | string;
  helperText?: string;
  required?: boolean;
  disabled?: boolean;
  containerClassName?: string;
}

export const FormSelectWithSearch = React.forwardRef<
  HTMLButtonElement,
  FormSelectWithSearchProps
>(
  (
    {
      name,
      control,
      options,
      label,
      placeholder,
      searchPlaceholder,
      error,
      helperText,
      required,
      disabled,
      containerClassName,
    },
    ref
  ) => {
    const errorMessage = typeof error === "string" ? error : error?.message;
    const selectId = name || label?.toLowerCase().replace(/\s+/g, "-");

    return (
      <div className={cn("space-y-2", containerClassName)}>
        {label && (
          <Label
            htmlFor={selectId}
            className={
              required
                ? "after:content-['*'] after:ml-0.5 after:text-destructive"
                : ""
            }
          >
            {label}
          </Label>
        )}
        <Controller
          name={name}
          control={control}
          render={({ field }) => (
            <SelectWithSearch
              options={options}
              value={field.value}
              onChange={field.onChange}
              placeholder={placeholder}
              searchPlaceholder={searchPlaceholder}
              error={errorMessage}
              helperText={helperText}
              disabled={disabled}
            />
          )}
        />
      </div>
    );
  }
);

FormSelectWithSearch.displayName = "FormSelectWithSearch";

{
  /* <FormSelectWithSearch
  name="country"
  control={control}
  label="Country"
  options={[
    { label: "India", value: "IN" },
    { label: "United States", value: "US" },
    { label: "Canada", value: "CA" },
  ]}
  placeholder="Select country"
  searchPlaceholder="Search countries..."
  error={errors.country}
  required
/> */
}
