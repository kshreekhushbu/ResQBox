import React, { useState, useMemo } from "react";
import { useForm } from "react-hook-form";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Eye, EyeOff } from "lucide-react";
import { cn } from "@/lib/utils";

type Props = {
  email: string;
  onReset: (email: string, password: string, confirmPassword: string) => void;
  onBack: () => void;
  loading?: boolean;
};

const ForgotStepReset: React.FC<Props> = ({
  email,
  onReset,
  onBack,
  loading,
}) => {
  const { register, handleSubmit, formState, watch } = useForm<{
    password: string;
    confirmPassword: string;
  }>();
  const { errors } = formState;
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  const password = watch("password");

  const strengthScore = useMemo(() => {
    if (!password) return 0;
    if (password.length < 8) return 1;

    let score = 1;
    let checks = 0;
    if (/[a-z]/.test(password) && /[A-Z]/.test(password)) checks++;
    if (/\d/.test(password)) checks++;
    if (/[^a-zA-Z\d]/.test(password)) checks++;

    return Math.min(score + checks, 4);
  }, [password]);

  const strengthProperties = {
    0: { label: "Enter password", color: "bg-gray-200" },
    1: { label: "Weak", color: "bg-red-500" },
    2: { label: "Fair", color: "bg-yellow-500" },
    3: { label: "Good", color: "bg-teal-500" },
    4: { label: "Strong", color: "bg-green-500" },
  } as const; 

  const currentStrength = strengthProperties[strengthScore as keyof typeof strengthProperties];

  return (
    <form
      onSubmit={handleSubmit((d) =>
        onReset(email, d.password, d.confirmPassword)
      )}
      className="space-y-3"
    >
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Password <span className="text-red-500">*</span>
        </label>
        <div className="relative">
          <Input
            type={showPassword ? "text" : "password"}
            {...register("password", {
              required: "Password is required",
              minLength: {
                value: 8,
                message: "Min 8 characters",
              },
              pattern: {
                value: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
                message: "Include uppercase, lowercase, number & special char",
              },
            })}
            className="pr-10 h-10"
            placeholder="Enter password"
          />
          <button
            type="button"
            onClick={() => setShowPassword((s) => !s)}
            className="absolute right-3 top-2.5 text-gray-400 hover:text-gray-600"
          >
            {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
          </button>
        </div>

        {password && (
          <div className="mt-1.5">
            <div className="flex gap-1">
              {[1, 2, 3, 4].map((level) => (
                <div
                  key={level}
                  className={cn(
                    "h-1 flex-1 rounded-full transition-colors",
                    strengthScore >= level ? currentStrength.color : "bg-gray-200"
                  )}
                />
              ))}
            </div>
            <p className="text-[10px] text-muted-foreground mt-0.5">
              Password strength: <span className="font-medium">{currentStrength.label}</span>
            </p>
          </div>
        )}
        {errors.password && (
          <p className="text-xs text-red-500 mt-1">{errors.password.message}</p>
        )}
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Confirm Password <span className="text-red-500">*</span>
        </label>
        <div className="relative">
          <Input
            type={showConfirm ? "text" : "password"}
            {...register("confirmPassword", {
              required: "Please confirm password",
              validate: (value) =>
                value === watch("password") || "Passwords do not match",
            })}
            className="pr-10 h-10"
            placeholder="Confirm password"
          />
          <button
            type="button"
            onClick={() => setShowConfirm((s) => !s)}
            className="absolute right-3 top-2.5 text-gray-400 hover:text-gray-600"
          >
            {showConfirm ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
          </button>
        </div>
        {errors.confirmPassword && (
          <p className="text-xs text-red-500 mt-1">{errors.confirmPassword.message}</p>
        )}
      </div>

      <Button
        type="submit"
        disabled={loading}
        className="w-full h-10 bg-primary hover:bg-primary/90 text-white font-medium rounded-sm"
      >
        {loading ? "Resetting..." : "Reset Password"}
      </Button>
      <p className="text-center text-sm text-muted-foreground mt-3">
        Go back?{" "}
        <button type="button" onClick={onBack} className="text-primary font-medium hover:underline">
          Previous Step
        </button>
      </p>
    </form>
  );
};

export default ForgotStepReset;
