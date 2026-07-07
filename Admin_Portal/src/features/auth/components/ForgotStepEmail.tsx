import React from "react";
import { useForm } from "react-hook-form";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

type Props = {
  onSend: (email: string) => void;
  loading?: boolean;
  defaultEmail?: string;
  onBack?: () => void;
};

const ForgotStepEmail: React.FC<Props> = ({
  onSend,
  loading,
  defaultEmail,
  onBack,
}) => {
  const { register, handleSubmit, formState } = useForm<{ email: string }>({
    defaultValues: { email: defaultEmail || "" },
  });
  const { errors } = formState;

  return (
    <form onSubmit={handleSubmit((d) => onSend(d.email))} className="space-y-3">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Email <span className="text-red-500">*</span>
        </label>
        <Input
          {...register("email", {
            required: "Email is required",
            pattern: {
              value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
              message: "Invalid email address"
            }
          })}
          placeholder="admin@example.com"
          className="h-10"
        />
        {errors.email && (
          <p className="text-xs text-red-500 mt-1">{errors.email.message}</p>
        )}
      </div>
      <Button
        type="submit"
        disabled={loading}
        className="w-full h-10 bg-primary hover:bg-primary/90 text-white font-medium rounded-sm"
      >
        {loading ? "Sending..." : "Send OTP"}
      </Button>
      <p className="text-center text-sm text-muted-foreground mt-3">
        Remember your password?{" "}
        <button type="button" onClick={onBack} className="text-primary font-medium hover:underline">
          Login
        </button>
      </p>
    </form>
  );
};

export default ForgotStepEmail;
