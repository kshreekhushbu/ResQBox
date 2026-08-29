import { useState, useMemo } from "react";
import { useForm } from "react-hook-form";
import { Layout } from "@/components/admin/Layout";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { User, Key, Loader2, Eye, EyeOff, Save } from "lucide-react";
import { changePassword } from "@/features/auth/authService";
import { toast } from "@/hooks/use-toast";
import { cn } from "@/lib/utils";

interface StoredUser {
  adminId?: number;
  name?: string;
  emailId?: string;
  roleId?: number;
  role?: string;
}

interface ResetFormData {
  oldPassword: string;
  password: string;
  confirmPassword: string;
}

const Profile: React.FC = () => {
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [showOldPassword, setShowOldPassword] = useState(false);
  const [isResetting, setIsResetting] = useState(false);

  const { register, handleSubmit, formState: { errors }, watch, reset } = useForm<ResetFormData>();
  const password = watch("password");

  const user: StoredUser = useMemo(() => {
    const raw = localStorage.getItem("admindata");
    if (raw) {
      try {
        return JSON.parse(raw);
      } catch {
        return {};
      }
    }
    return {};
  }, []);

  const strengthScore = useMemo(() => {
    if (!password) return 0;
    if (password.length < 8) return 1;
    let score = 1;
    if (/[a-z]/.test(password) && /[A-Z]/.test(password)) score++;
    if (/\d/.test(password)) score++;
    if (/[^a-zA-Z\d]/.test(password)) score++;
    return Math.min(score, 4);
  }, [password]);

  const strengthProps = {
    0: { label: "", color: "bg-gray-200" },
    1: { label: "Weak", color: "bg-red-500" },
    2: { label: "Fair", color: "bg-yellow-500" },
    3: { label: "Good", color: "bg-teal-500" },
    4: { label: "Strong", color: "bg-green-500" },
  } as const;

  const currentStrength = strengthProps[strengthScore as keyof typeof strengthProps];

  const getUserInitials = () => {
    if (user?.name) {
      const names = user.name.split(" ");
      if (names.length >= 2) {
        return `${names[0][0]}${names[1][0]}`.toUpperCase();
      }
      return user.name.substring(0, 2).toUpperCase();
    }
    return "SA";
  };

  const onSubmit = async (data: ResetFormData) => {
    try {
      setIsResetting(true);
      await changePassword({
        oldPassword: data.oldPassword,
        newPassword: data.password,
      });

      toast({
        title: "Success",
        description: "Password has been reset successfully.",
        className: "bg-green-500 text-white font-bold",
      });
      reset();
    } catch (error: any) {
      toast({
        title: "Error",
        description: error?.message || "Failed to reset password.",
        variant: "destructive",
      });
    } finally {
      setIsResetting(false);
    }
  };

  return (
    <Layout Active="Profile" header={{ title: "My Profile" }}>
      <div className="max-w-4xl mx-auto space-y-6">

        <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
          <CardHeader>
            <div className="flex items-center gap-3">
              <div className="p-2 bg-primary/10 rounded-lg">
                <User className="h-6 w-6 text-primary" />
              </div>
              <div>
                <CardTitle>Account Information</CardTitle>
                <CardDescription>Your profile details</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="flex flex-col sm:flex-row items-start sm:items-center gap-6">
              <Avatar className="h-20 w-20">
                <AvatarFallback className="bg-primary text-white text-xl font-semibold">
                  {getUserInitials()}
                </AvatarFallback>
              </Avatar>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-12 gap-y-4 flex-1">
                <div>
                  <Label className="text-xs text-muted-foreground">Full Name</Label>
                  <p className="font-medium">{user.name || "N/A"}</p>
                </div>
                <div>
                  <Label className="text-xs text-muted-foreground">Email Address</Label>
                  <p className="font-medium">{user.emailId || "N/A"}</p>
                </div>
                <div>
                  <Label className="text-xs text-muted-foreground">Role</Label>
                  <p className="font-medium">{user.role || "N/A"}</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
          <CardHeader>
            <div className="flex items-center gap-3">
              <div className="p-2 bg-primary/10 rounded-lg">
                <Key className="h-6 w-6 text-primary" />
              </div>
              <div>
                <CardTitle>Change Password</CardTitle>
                <CardDescription>Update your account password</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2 md:col-span-2">
                  <Label htmlFor="oldPassword">
                    Current Password <span className="text-destructive">*</span>
                  </Label>
                  <div className="relative">
                    <Input
                      id="oldPassword"
                      type={showOldPassword ? "text" : "password"}
                      placeholder="Enter current password"
                      {...register("oldPassword", {
                        required: "Current password is required",
                      })}
                      className={cn("pr-10", errors.oldPassword && "border-destructive focus-visible:ring-destructive")}
                    />
                    <button
                      type="button"
                      onClick={() => setShowOldPassword(!showOldPassword)}
                      className="absolute right-3 top-2.5 text-gray-400 hover:text-gray-600"
                    >
                      {showOldPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                    </button>
                  </div>
                  {errors.oldPassword && (
                    <p className="text-xs text-destructive">{errors.oldPassword.message}</p>
                  )}
                </div>
                <div className="space-y-2">
                  <Label htmlFor="password">
                    New Password <span className="text-destructive">*</span>
                  </Label>
                  <div className="relative">
                    <Input
                      id="password"
                      type={showPassword ? "text" : "password"}
                      placeholder="Enter new password"
                      {...register("password", {
                        required: "Password is required",
                        minLength: { value: 8, message: "Min 8 characters" },
                        pattern: {
                          value: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
                          message: "Include uppercase, lowercase, number & special char",
                        },
                      })}
                      className={cn("pr-10", errors.password && "border-destructive focus-visible:ring-destructive")}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
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
                    <span className="text-xs text-destructive">{errors.password.message}</span>
                  )}
                </div>

                <div className="space-y-2">
                  <Label htmlFor="confirmPassword">
                    Confirm Password <span className="text-destructive">*</span>
                  </Label>
                  <div className="relative">
                    <Input
                      id="confirmPassword"
                      type={showConfirm ? "text" : "password"}
                      placeholder="Confirm new password"
                      {...register("confirmPassword", {
                        required: "Please confirm password",
                        validate: (value) => value === watch("password") || "Passwords do not match",
                      })}
                      className={cn("pr-10", errors.confirmPassword && "border-destructive focus-visible:ring-destructive")}
                    />
                    <button
                      type="button"
                      onClick={() => setShowConfirm(!showConfirm)}
                      className="absolute right-3 top-2.5 text-gray-400 hover:text-gray-600"
                    >
                      {showConfirm ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                    </button>
                  </div>
                  {errors.confirmPassword && (
                    <span className="text-xs text-destructive">{errors.confirmPassword.message}</span>
                  )}
                </div>
              </div>

              <div className="flex justify-end">
                <Button
                  type="submit"
                  disabled={isResetting}
                  className="bg-primary hover:bg-primary/90 min-w-[140px]"
                >
                  {isResetting ? (
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  ) : (
                    <Save className="mr-2 h-4 w-4" />
                  )}
                  Update Password
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </Layout>
  );
};

export default Profile;
