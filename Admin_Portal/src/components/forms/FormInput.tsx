import * as React from "react";
import { UseFormRegisterReturn, FieldError } from "react-hook-form";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { AlertCircle } from "lucide-react";
import { cn } from "@/lib/utils";
import { normalizeInput } from "@/lib/utils";

export interface FormInputProps extends React.ComponentProps<typeof Input> {
  label?: string;
  error?: FieldError | string;
  register?: UseFormRegisterReturn;
  helperText?: string;
  required?: boolean;
  containerClassName?: string;
  alphaSpacesOnly?: boolean;
  maxConsecutiveSpaces?: number;
  digitsOnly?: boolean; 
  strictSpaces?: boolean; 
  skipNormalize?: boolean; 
}

export const FormInput = React.forwardRef<HTMLInputElement, FormInputProps>(
  (
    {
      label,
      error,
      register,
      helperText,
      required,
      containerClassName,
      className,
      id,
      alphaSpacesOnly = false,
      maxConsecutiveSpaces = 2,
      ...props
    },
    ref
  ) => {
    const errorMessage = typeof error === "string" ? error : error?.message;
    const inputId =
      id || register?.name || label?.toLowerCase().replace(/\s+/g, "-");

   
    const handleInput = (e: React.ChangeEvent<HTMLInputElement>) => {
      let value = e.target.value;
      if (props.skipNormalize) {
        if (props.onChange) props.onChange(e);
        return;
      } else if (props.digitsOnly) {
        value = value.replace(/\D+/g, "");
      } else if (props.strictSpaces) {
        value = value.replace(/[^A-Za-z ]/g, "");
        value = value.replace(/^\s+/, ""); 
        value = value.replace(/ {3,}/g, "  "); 
        value = value.replace(/(  ) +/g, "  "); 
      } else if (alphaSpacesOnly) {
        value = normalizeInput(value);
        value = value.replace(/[^A-Za-z ]/g, "");
        const spaceRe = new RegExp(` {${maxConsecutiveSpaces + 1},}`, "g");
        value = value.replace(spaceRe, " ".repeat(maxConsecutiveSpaces));
        value = value.replace(/^\s+/, "");
      } else {
        value = normalizeInput(value);
      }
      e.target.value = value;
      if (props.onChange) props.onChange(e);
    };

    return (
      <div className={cn("space-y-2", containerClassName)}>
        {label && (
          <Label
            htmlFor={inputId}
            className={
              required
                ? "after:content-['*'] after:ml-0.5 after:text-destructive"
                : ""
            }
          >
            {label}
          </Label>
        )}
        <div className="relative">
          <Input
            id={inputId}
            ref={ref || register?.ref}
            className={cn(
              errorMessage &&
              "border-destructive focus-visible:ring-destructive",
              className
            )}
            aria-invalid={!!errorMessage}
            aria-describedby={errorMessage ? `${inputId}-error` : undefined}
            {...register}
            {...props}
            onInput={handleInput}
          />
          {errorMessage && (
            <AlertCircle className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-destructive" />
          )}
        </div>
        {errorMessage ? (
          <p
            id={`${inputId}-error`}
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

FormInput.displayName = "FormInput";

{
  /* <FormInput
  label="Name"
  register={register("name")}
  error={errors.name}
  placeholder="Enter name"
  required
/> */
}
