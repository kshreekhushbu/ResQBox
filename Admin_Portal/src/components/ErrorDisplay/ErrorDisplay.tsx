import React from "react";
import { AlertCircle, RefreshCcw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";

interface ErrorDisplayProps {
  message?: string;
  title?: string;
  getdata?: () => void;
  fullScreen?: boolean;
}

export const ErrorDisplay: React.FC<ErrorDisplayProps> = ({
  message = "An unexpected error occurred. Please try again.",
  title = "Something went wrong",
  getdata,
  fullScreen = true
}) => {
  const [isRetrying, setIsRetrying] = React.useState(false);

  const handleRetry = async () => {
    setIsRetrying(true);
    try {
      if (getdata) {
        await Promise.resolve(getdata());
      } else {
        window.location.reload();
      }
    } catch (err) {
      console.error("Retry failed:", err);
    } finally {
      setIsRetrying(false);
    }
  };

  return (
    <div
      role="alert"
      className={`w-full flex items-center justify-center p-6 animate-in fade-in duration-700 ${fullScreen ? "min-h-[70vh]" : "h-full"
        }`}
    >
      <div className="relative w-full max-w-lg">
        {/* Decorative elements */}
        <div className="absolute -top-12 -left-12 w-48 h-48 bg-red-500/10 rounded-full blur-3xl animate-pulse" />
        <div className="absolute -bottom-12 -right-12 w-48 h-48 bg-red-500/5 rounded-full blur-3xl animate-pulse delay-700" />

        <Card className="relative border-none shadow-[0_8px_30px_rgb(0,0,0,0.04)] dark:shadow-[0_8px_30px_rgb(0,0,0,0.2)] bg-card/60 backdrop-blur-xl overflow-hidden group">
          <div className="absolute inset-0 bg-gradient-to-br from-red-500/[0.02] to-transparent pointer-events-none" />

          <CardContent className="flex flex-col items-center text-center p-12 space-y-6">
            <div className="relative">
              <div className="absolute inset-0 bg-red-500/20 rounded-full blur-2xl animate-pulse scale-150 opacity-50" />
              <div className="relative p-6 rounded-3xl bg-gradient-to-br from-red-500/10 to-red-500/5 ring-1 ring-red-500/20 group-hover:ring-red-500/40 transition-all duration-500 shadow-inner">
                <AlertCircle className="h-10 w-10 text-red-500" />
              </div>
            </div>

            <div className="space-y-3">
              <h3 className="text-2xl font-bold tracking-tight text-foreground/90">
                {title}
              </h3>
              <p className="text-muted-foreground leading-relaxed max-w-sm mx-auto text-base">
                {message}
              </p>
            </div>

            <div className="pt-4 w-full max-w-[240px]">
              <Button
                onClick={handleRetry}
                disabled={isRetrying}
                size="lg"
                className="w-full h-12 gap-3 bg-red-500 hover:bg-red-600 text-white border-none shadow-[0_4px_14px_0_rgba(239,68,68,0.39)] hover:shadow-[0_6px_20px_rgba(239,68,68,0.23)] transition-all duration-300 rounded-2xl font-medium active:scale-[0.98]"
              >
                <RefreshCcw className={`h-4 w-4 ${isRetrying ? "animate-spin" : ""}`} />
                {isRetrying ? "Retrying..." : "Try Again"}
              </Button>
            </div>

            {message.toLowerCase().includes("stripe") && (
              <p className="text-xs text-muted-foreground/60 italic">
                Need help? Contact support or check your onboarding status.
              </p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
};


