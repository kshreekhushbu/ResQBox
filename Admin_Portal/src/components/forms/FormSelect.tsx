import * as React from "react";
import { Controller, Control, FieldError } from "react-hook-form";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { AlertCircle } from "lucide-react";
import { cn } from "@/lib/utils";

export interface SelectOption {
  value: string | number;
  label: string;
  disabled?: boolean;
}

export interface FormSelectProps {
  name: string;
  control: Control<any>;
  label?: string;
  options: SelectOption[];
  placeholder?: string;
  error?: FieldError | string;
  helperText?: string;
  required?: boolean;
  containerClassName?: string;
  disabled?: boolean;
}

export const FormSelect = React.forwardRef<HTMLButtonElement, FormSelectProps>(
  (
    {
      name,
      control,
      label,
      options,
      placeholder = "Select an option",
      error,
      helperText,
      required,
      containerClassName,
      disabled,
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
            <div className="relative">
              <Select
                value={field.value?.toString()}
                onValueChange={(value) => {
                  // Convert to number if original value was number
                  const option = options.find(
                    (opt) => opt.value.toString() === value
                  );
                  field.onChange(option?.value ?? value);
                }}
                disabled={disabled}
              >
                <SelectTrigger
                  ref={ref}
                  id={selectId}
                  className={cn(
                    errorMessage && "border-destructive focus:ring-destructive",
                    "w-full"
                  )}
                  aria-invalid={!!errorMessage}
                  aria-describedby={
                    errorMessage ? `${selectId}-error` : undefined
                  }
                >
                  <SelectValue placeholder={placeholder} />
                </SelectTrigger>
                <SelectContent>
                  {options.map((option) => (
                    <SelectItem
                      key={option.value.toString()}
                      value={option.value.toString()}
                      disabled={option.disabled}
                    >
                      {option.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errorMessage && (
                <AlertCircle className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-destructive pointer-events-none" />
              )}
            </div>
          )}
        />
        {errorMessage ? (
          <p
            id={`${selectId}-error`}
            className="text-sm text-destructive flex items-center gap-1"
          >
            <AlertCircle className="h-3 w-3" />
            {errorMessage}
          </p>
        ) : helperText ? (
          <p className="text-sm text-muted-foreground">{helperText}</p>
        ) : null}
      </div>
    );
  }
);

FormSelect.displayName = "FormSelect";

{
  /* <FormSelect
  name="role"
  control={control}
  label="User Role"
  options={[
    { value: "admin", label: "Admin" },
    { value: "staff", label: "Staff" },
    { value: "manager", label: "Manager" },
  ]}
  error={errors.role}
  required
  placeholder="Select role"
/> */
}
