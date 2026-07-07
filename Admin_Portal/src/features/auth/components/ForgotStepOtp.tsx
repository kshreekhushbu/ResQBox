import React, { useRef, useState, useEffect } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

type Props = {
  email: string;
  onVerify: (email: string, otp: string) => void;
  onBack: () => void;
  onResend: () => void;
  loading?: boolean;
};

const ForgotStepOtp: React.FC<Props> = ({
  email,
  onVerify,
  onBack,
  onResend,
  loading,
}) => {
  const [otp, setOtp] = useState<string[]>(["", "", "", "", "", ""]);
  const [error, setError] = useState<string>("");
  const [timer, setTimer] = useState<number>(30);
  const [canResend, setCanResend] = useState<boolean>(false);
  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

  useEffect(() => {
    inputRefs.current[0]?.focus();
  }, []);

  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (timer > 0) {
      interval = setInterval(() => {
        setTimer((prev) => prev - 1);
      }, 1000);
    } else {
      setCanResend(true);
    }
    return () => clearInterval(interval);
  }, [timer]);

  const handleResend = () => {
    onResend();
    setTimer(30);
    setCanResend(false);
  };

  const handleChange = (index: number, value: string) => {
    if (value.length > 1) {
      value = value.slice(-1);
    }

    if (value && !/^\d$/.test(value)) return;

    const newOtp = [...otp];
    newOtp[index] = value;
    setOtp(newOtp);
    setError("");

    if (value && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Backspace" && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    e.preventDefault();
    const pastedData = e.clipboardData.getData("text").slice(0, 6);
    if (!/^\d+$/.test(pastedData)) return;

    const newOtp = [...otp];
    pastedData.split("").forEach((char, i) => {
      if (i < 6) newOtp[i] = char;
    });
    setOtp(newOtp);

    const lastIndex = Math.min(pastedData.length - 1, 5);
    inputRefs.current[lastIndex]?.focus();
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const otpValue = otp.join("");

    if (otpValue.length !== 6) {
      setError("Please enter all 6 digits");
      return;
    }

    onVerify(email, otpValue);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
        <Input value={email} disabled className="h-10 bg-muted/50" />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Enter 6-digit OTP <span className="text-red-500">*</span>
        </label>
        <div className="flex gap-3 justify-center">
          {otp.map((digit, index) => (
            <input
              key={index}
              ref={(el) => (inputRefs.current[index] = el)}
              type="text"
              inputMode="numeric"
              maxLength={1}
              value={digit}
              onChange={(e) => handleChange(index, e.target.value)}
              onKeyDown={(e) => handleKeyDown(index, e)}
              onPaste={handlePaste}
              className="w-10 h-10 text-center text-lg font-semibold border border-gray-300 rounded-[5px] focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-colors"
            />
          ))}
        </div>
        {error && (
          <p className="text-xs text-red-500 mt-2 text-center">{error}</p>
        )}
        <div className="flex justify-end mt-2">
          {canResend ? (
            <button
              type="button"
              onClick={handleResend}
              className="text-xs text-primary font-medium hover:underline"
            >
              Resend OTP
            </button>
          ) : (
            <span className="text-xs text-muted-foreground">
              Resend OTP in {timer}s
            </span>
          )}
        </div>
      </div>

      <Button
        type="submit"
        disabled={loading}
        className="w-full h-10 bg-primary hover:bg-primary/90 text-white font-medium rounded-sm"
      >
        {loading ? "Verifying..." : "Verify OTP"}
      </Button>
      <p className="text-center text-sm text-muted-foreground">
        Want to try again?{" "}
        <button type="button" onClick={onBack} className="text-primary font-medium hover:underline">
          Go Back
        </button>
      </p>
    </form>
  );
};

export default ForgotStepOtp;

