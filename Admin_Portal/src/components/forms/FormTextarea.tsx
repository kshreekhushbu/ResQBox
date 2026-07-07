import * as React from "react";
import { UseFormRegisterReturn, FieldError } from "react-hook-form";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { AlertCircle } from "lucide-react";
import { cn } from "@/lib/utils";

export interface FormTextareaProps
  extends React.ComponentProps<typeof Textarea> {
  label?: string;
  error?: FieldError | string;
  register?: UseFormRegisterReturn;
  helperText?: string;
  required?: boolean;
  containerClassName?: string;
}

export const FormTextarea = React.forwardRef<HTMLTextAreaElement, FormTextareaProps>(
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
      ...props
    },
    ref
  ) => {
    const errorMessage = typeof error === "string" ? error : error?.message;
    const textareaId =
      id || register?.name || label?.toLowerCase().replace(/\s+/g, "-");

    return (
      <div className={cn("space-y-2", containerClassName)}>
        {label && (
          <Label
            htmlFor={textareaId}
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
          <Textarea
            id={textareaId}
            ref={ref || register?.ref}
            className={cn(
              errorMessage &&
                "border-destructive focus-visible:ring-destructive",
              className
            )}
            aria-invalid={!!errorMessage}
            aria-describedby={errorMessage ? `${textareaId}-error` : undefined}
            {...register}
            {...props}
          />
          {errorMessage && (
            <AlertCircle className="absolute right-3 top-3 h-4 w-4 text-destructive" />
          )}
        </div>
        {errorMessage ? (
          <p
            id={`${textareaId}-error`}
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

FormTextarea.displayName = "FormTextarea";



{/* <FormTextarea
  label="Description"
  register={register("description")}
  error={errors.description}
  placeholder="Enter description"
  required
/> */}