import React, { useState, useEffect } from "react";
import { SubmitHandler, useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";
import { Eye, EyeOff, Mail, Lock, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card } from "@/components/ui/card";
import logo from "@/assets/logo.png";
import { toast } from "sonner";
import { useDispatch } from "react-redux";
import { AppDispatch } from "@/store/store";
import { menuItems } from "@/components/admin/config";
import { Permission } from "../types";
import ApiService from "@/services/config";
import { login } from "../authSlice";

interface LoginFormData {
  emailId: string;
  password: string;
}

const Login: React.FC = () => {
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const Navigate = useNavigate();
  const dispatch = useDispatch<AppDispatch>();
  const [isLoading, setIsLoading] = useState<boolean>(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormData>();

  useEffect(() => {
    const token = localStorage.getItem("Token");
    if (token) {
      const accessItems = localStorage.getItem("AccessItems");
      if (accessItems) {
        try {
          const permissions = JSON.parse(accessItems);
          const readablePages =
            permissions?.filter((item: Permission) => item?.read === 1) || [];

          if (readablePages.length === 0) {
            Navigate("/profile");
            return;
          }

          const dashboardAccess = permissions?.find(
            (item: Permission) =>
              item.PageName === "dashboard" && item.read === 1
          );

          if (dashboardAccess) {
            Navigate("/dashboard");
          } else {
            const findMenuLink = (pageName: string) => {
              const menu = menuItems.find(
                (item) =>
                  item?.name.trim().toLowerCase() ===
                  pageName.trim().toLowerCase()
              );
              return menu?.menuLink || null;
            };

            for (let page of readablePages) {
              const link = findMenuLink(page.PageName);
              if (link) {
                Navigate(link);
                return;
              }
            }
            Navigate("/profile");
          }
        } catch (error) {
          console.error("Error parsing permissions:", error);
          Navigate("/profile");
        }
      } else {
        Navigate("/profile");
      }
    }
  }, []);

  const onSubmit: SubmitHandler<LoginFormData> = async (data) => {
    console.log(data);
    try {
      setIsLoading(true);
      const resultAction = await dispatch(login(data));

      if (login.fulfilled.match(resultAction)) {
        const { token, user, permissions, roleId } = resultAction.payload as {
          token: string;
          user: any;
          permissions: Permission[];
          roleId: number;
        };

        ApiService.defaults.headers.common["Authorization"] = `Bearer ${token}`;
        localStorage.setItem("Token", token);
        localStorage.setItem("admindata", JSON.stringify(user));
        localStorage.setItem("AccessItems", JSON.stringify(permissions));
        localStorage.setItem("RoleId", String(roleId));
        console.log("permissions", permissions);

        const AccessItems = permissions || [];

        const readablePages = AccessItems.filter(
          (item: Permission) => item?.read === 1
        );

        if (readablePages.length === 0) {
          Navigate("/profile");
          return;
        }

        const findMenuLink = (pageName: string) => {
          const menu = menuItems.find(
            (item) =>
              item?.name.trim().toLowerCase() === pageName.trim().toLowerCase()
          );
          return menu?.menuLink || null;
        };

        const dashboardAccess = AccessItems.find(
          (item: Permission) => item.PageName === "dashboard" && item.read === 1
        );

        if (dashboardAccess) {
          Navigate("/dashboard");
        } else {
          for (let page of readablePages) {
            const link = findMenuLink(page.PageName);
            if (link) {
              Navigate(link);
              return;
            }
          }
          Navigate("/profile");
        }
      } else if (login.rejected.match(resultAction)) {
        setIsLoading(false);
        toast.error((resultAction.payload as string) || "Login failed");
      }
    } catch (err: any) {
      console.error(err);
      setIsLoading(false);
      toast.error(err?.response?.data?.Message || "Login failed");
    }
  };

  return (
    <div className="min-h-screen w-full bg-gradient-to-br from-emerald-50 via-white to-orange-50 dark:from-emerald-950/20 dark:via-background dark:to-orange-950/20 flex items-center justify-center p-4 relative overflow-hidden">
      <div className="absolute top-20 left-20 w-72 h-72 bg-gradient-to-br from-emerald-400/20 to-emerald-600/20 rounded-full blur-3xl animate-pulse" />
      <div
        className="absolute bottom-20 right-20 w-96 h-96 bg-gradient-to-br from-orange-400/20 to-orange-600/20 rounded-full blur-3xl animate-pulse"
        style={{ animationDelay: "1s" }}
      />
      <div
        className="absolute top-1/2 left-1/2 w-64 h-64 bg-gradient-to-br from-emerald-300/10 to-orange-300/10 rounded-full blur-3xl animate-pulse"
        style={{ animationDelay: "2s" }}
      />

      <div className="w-full max-w-md z-10 animate-fade-in">
        <Card className="p-8 backdrop-blur-xl bg-white/90 dark:bg-card/90 border-border/50 shadow-2xl rounded-2xl">
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center mb-6 transition-transform hover:scale-105 duration-300">
              <div className="relative">
                <div className="absolute inset-0 bg-gradient-to-r from-emerald-500 to-orange-500 rounded-2xl blur-xl opacity-50" />
                <div className="relative bg-white dark:bg-card p-4 rounded-2xl shadow-lg">
                  <img
                    src={logo}
                    alt="ResQBox Logo"
                    className="w-32 h-auto object-contain"
                  />
                </div>
              </div>
            </div>
            <h1 className="text-3xl font-bold bg-gradient-to-r from-emerald-600 to-orange-600 bg-clip-text text-transparent mb-2">
              Welcome Back
            </h1>
            <p className="text-muted-foreground flex items-center justify-center gap-2">
              Sign in to your admin dashboard
            </p>
          </div>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="email" className="text-foreground font-medium">
                Email Address
              </Label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                <Input
                  id="email"
                  type="email"
                  placeholder="admin@resqbox.com"
                  {...register("emailId", {
                    required: "Email is required",
                    pattern: {
                      value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                      message: "Invalid email address",
                    },
                  })}
                  className="pl-10 bg-background/50 border-border/50 focus:border-emerald-500 transition-colors"
                  disabled={isLoading}
                />
              </div>
              {errors.emailId && (
                <p className="text-sm font-medium text-destructive animate-fade-in">
                  {errors.emailId.message}
                </p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="password" className="text-foreground font-medium">
                Password
              </Label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  placeholder="••••••••"
                  {...register("password", {
                    required: "Password is required",
                    minLength: {
                      value: 6,
                      message: "Password must be at least 6 characters",
                    },
                  })}
                  className="pl-10 pr-10 bg-background/50 border-border/50 focus:border-emerald-500 transition-colors"
                  disabled={isLoading}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
                  disabled={isLoading}
                >
                  {showPassword ? (
                    <EyeOff className="w-5 h-5" />
                  ) : (
                    <Eye className="w-5 h-5" />
                  )}
                </button>
              </div>
              {errors.password && (
                <p className="text-sm font-medium text-destructive animate-fade-in">
                  {errors.password.message}
                </p>
              )}
            </div>

            <div className="flex items-center justify-between">
              <label className="flex items-center space-x-2 cursor-pointer group">
                <input
                  type="checkbox"
                  className="w-4 h-4 rounded border-border text-emerald-600 focus:ring-emerald-500 transition-colors"
                  disabled={isLoading}
                />
                <span className="text-sm text-muted-foreground group-hover:text-foreground transition-colors">
                  Remember me
                </span>
              </label>
              <button
                type="button"
                onClick={() => Navigate("/forgotpassword")}
                className="text-sm font-medium bg-gradient-to-r from-emerald-600 to-orange-600 bg-clip-text text-transparent hover:opacity-80 transition-opacity"
              >
                Forgot password?
              </button>
            </div>

            <div>
              <Button
                type="submit"
                className="w-full bg-gradient-to-r from-emerald-600 to-emerald-500 hover:from-emerald-700 hover:to-emerald-600 text-white shadow-lg shadow-emerald-500/30 transition-all duration-300 hover:scale-[1.02] active:scale-[0.98]"
                size="lg"
                disabled={isLoading}
              >
                {isLoading ? (
                  <span className="flex items-center gap-2">
                    <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    Signing in...
                  </span>
                ) : (
                  "Sign In"
                )}
              </Button>
            </div>
          </form>
        </Card>
      </div>
    </div>
  );
};

export default Login;
