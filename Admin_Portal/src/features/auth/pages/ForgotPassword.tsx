import React, { useState } from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";
import { Card, CardContent } from "@/components/ui/card";
import omIcon from "@/assets/logo.png";
import { useToast } from "@/hooks/use-toast";
import ForgotStepEmail from "../components/ForgotStepEmail";
import ForgotStepOtp from "../components/ForgotStepOtp";
import ForgotStepReset from "../components/ForgotStepReset";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "@/store/store";
import { sendOTPThunk, verifyOTPThunk, resetPasswordThunk } from "../authSlice";

type EmailForm = { emailId: string };
type OtpForm = { emailId: string; otp: string };
type ResetForm = { emailId: string; password: string; confirmPassword: string };

const ForgotPassword: React.FC = () => {
  const [step, setStep] = useState(1);
  const navigate = useNavigate();
  const { toast } = useToast();



  const [email, setEmail] = useState<string>("");
  const { loading, error } = useSelector((state: RootState) => state.auth);
  const dispatch = useDispatch<AppDispatch>();

  const {
    register: regEmail,
    handleSubmit: submitEmail,
    formState: { errors: emailErrors },
  } = useForm<EmailForm>();

  const {
    register: regOtp,
    handleSubmit: submitOtp,
    formState: { errors: otpErrors },
  } = useForm<OtpForm>();

  const {
    register: regReset,
    handleSubmit: submitReset,
    watch,
    formState: { errors: resetErrors },
  } = useForm<ResetForm>();

  const onSubmitEmail = async (emailId: string) => {
    try {
      const resultAction = await dispatch(sendOTPThunk({ email: emailId }));

      if (sendOTPThunk.fulfilled.match(resultAction)) {
        setEmail(emailId);
        toast({
          title: "Success",
          description: resultAction.payload.message,
          variant: "default",
          className: "bg-green-500 text-white font-bold",
        });
        setStep(2);
      } else if (sendOTPThunk.rejected.match(resultAction)) {
        toast({
          variant: "destructive",
          title: "Error",
          description: (resultAction.payload as string) || "Failed to send OTP",
        });
      }
    } catch (err: any) {
      console.error(err);
      toast({
        variant: "destructive",
        title: "Error",
        description: "Failed to send OTP",
      });
    }
  };

  const onSubmitOtp = async (em: string, otp: string) => {
    try {
      const resultAction = await dispatch(verifyOTPThunk({ email: em, otp }));

      if (verifyOTPThunk.fulfilled.match(resultAction)) {
        toast({
          title: "Success",
          description: resultAction.payload.message,
          variant: "default",
          className: "bg-green-500 text-white font-bold",
        });
        setStep(3);
      } else if (verifyOTPThunk.rejected.match(resultAction)) {
        toast({
          variant: "destructive",
          title: "Error",
          description: (resultAction.payload as string) || "Invalid OTP",
        });
      }
    } catch (err: any) {
      console.error(err);
      toast({
        variant: "destructive",
        title: "Error",
        description: "Failed to verify OTP",
      });
    }
  };

  const onSubmitReset = async (em: string, password: string, confirmPassword: string) => {
    if (password !== confirmPassword) {
      toast({
        variant: "destructive",
        title: "Error",
        description: "Passwords do not match",
      });
      return;
    }

    try {
      const resultAction = await dispatch(
        resetPasswordThunk({ email: em, newPassword: password, confirmPassword })
      );

      if (resetPasswordThunk.fulfilled.match(resultAction)) {
        toast({
          title: "Success",
          description: "Password reset successfully!",
        });
        navigate("/");
      } else if (resetPasswordThunk.rejected.match(resultAction)) {
        toast({
          variant: "destructive",
          title: "Error",
          description: (resultAction.payload as string) || "Failed to reset password",
        });
      }
    } catch (err: any) {
      console.error(err);
      toast({
        variant: "destructive",
        title: "Error",
        description: "Failed to reset password",
      });
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center px-4">
      <div className="w-full max-w-sm">
        <Card className="shadow-lg border-0 bg-white rounded-[5px] overflow-hidden">
          <div className="text-center pt-6 pb-4 px-6">
            <div className="mx-auto mb-4 w-20 h-12">
              <img
                src={omIcon}
                alt="resqbox"
                className="w-full h-full object-contain"
              />
            </div>
            <h1 className="text-xl font-semibold text-gray-900 mb-1">
              {step === 1 && "Forgot Password?"}
              {step === 2 && "Verify OTP"}
              {step === 3 && "Reset your Password"}
            </h1>
            <p className="text-muted-foreground text-xs">
              {step === 1 && "Enter your email to receive verification code"}
              {step === 2 && "Enter the code sent to your email"}
              {step === 3 && "Create a strong new password"}
            </p>
          </div>

          <CardContent className="px-6 pb-6">
            {step === 1 && (
              <ForgotStepEmail
                onSend={onSubmitEmail}
                loading={loading}
                defaultEmail={email}
                onBack={() => navigate("/")}
              />
            )}

            {step === 2 && (
              <ForgotStepOtp
                email={email}
                onVerify={onSubmitOtp}
                onBack={() => setStep(1)}
                onResend={() => onSubmitEmail(email)}
                loading={loading}
              />
            )}

            {step === 3 && (
              <ForgotStepReset
                email={email}
                onReset={onSubmitReset}
                onBack={() => setStep(2)}
                loading={loading}
              />
            )}
          </CardContent>
        </Card>

        <p className="mt-4 text-center text-[10px] text-muted-foreground">
          © {new Date().getFullYear()} ResQBox. All rights reserved.
        </p>
      </div>
    </div>
  );
};

export default ForgotPassword;
