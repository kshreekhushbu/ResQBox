import { useState, useMemo, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Bell, User, LogOut, Settings, AlertTriangle, PanelLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { useSidebar } from "@/components/ui/sidebar";
import { useSelector, useDispatch } from "react-redux";
import { RootState, AppDispatch } from "@/store/store";
import { fetchAdminAlerts, markAlertLocally } from "@/features/restarents/kitchensSlice";
import { logout } from "@/features/auth/authSlice";
import { logoutUser } from "@/features/auth/authService";
import { disconnectSocket } from "@/services/socket";
import { AlertsDrawer } from "@/features/restarents/components/AlertsDrawer";

interface HeaderProps {
  title: string;
  subtitle?: string;
  actions?: React.ReactNode;
  showNotifications?: boolean;
  showUserMenu?: boolean;
  tagline?: string;
  align?: "left" | "center";
}

export function Header({
  title,
  subtitle,
  actions,
  showNotifications = true,
  showUserMenu = true,
  tagline,
  align = "left",
}: HeaderProps) {
  const navigate = useNavigate();
  const dispatch = useDispatch<AppDispatch>();
  const { user } = useSelector((state: RootState) => state.auth);
  const { unviewedCount, alerts, alertsLoading, moreAlertsLoading, alertsPagination } = useSelector((state: RootState) => state.kitchens);
  const { toggleSidebar } = useSidebar();
  const [showLogoutDialog, setShowLogoutDialog] = useState(false);

  useEffect(() => {
    dispatch(fetchAdminAlerts());
  }, [dispatch]);

  const handleAlertViewed = (alertId: number) => {
    dispatch(markAlertLocally(alertId));
  };

  const handleLoadMore = () => {
    if (alertsPagination && !moreAlertsLoading && alertsPagination.page < alertsPagination.totalPages) {
      dispatch(fetchAdminAlerts({ page: alertsPagination.page + 1 }));
    }
  };
  // ... existing code ...

  interface StoredUser {
    adminId?: number;
    name?: string;
    emailId?: string;
    roleId?: number;
    role?: string;
  }

  const resolvedUser: StoredUser = useMemo(() => {
    const raw = localStorage.getItem("admindata");
    if (raw) {
      try {
        return JSON.parse(raw);
      } catch {
        return user || {};
      }
    }
    return user || {};
  }, [user]);

  // ... (inside component)
  const handleLogout = async () => {
    try {
      await logoutUser();
    } catch {
      // Continue local logout even if the server call fails
    }
    disconnectSocket();
    dispatch(logout());
    navigate("/", { replace: true });
  };

  const getUserInitials = () => {
    if (resolvedUser?.name) {
      const names = resolvedUser.name.split(" ");
      if (names.length >= 2) {
        return `${names[0][0]}${names[1][0]}`.toUpperCase();
      }
      return resolvedUser.name.substring(0, 2).toUpperCase();
    }
    return "SA";
  };

  return (
    <>
      <header className="sticky top-0 z-20 rounded-2xl bg-card/90 backdrop-blur supports-[backdrop-filter]:bg-card/70 border border-border/50 mx-2 my-2 px-3 py-2 sm:mx-4 sm:my-4 sm:px-6 sm:py-4 shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-2 sm:gap-4">
          <div className="flex items-center gap-2 sm:gap-3 min-w-0">
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8 cursor-pointer shrink-0"
              onClick={toggleSidebar}
            >
              <PanelLeft className="h-5 w-5" />
              <span className="sr-only">Toggle Sidebar</span>
            </Button>
            <div
              className={`flex flex-col ${align === "center"
                ? "items-center text-center w-full"
                : "items-start"
                } gap-0.5 sm:gap-1 min-w-0`}
            >
              <h1 className="font-bold tracking-tight text-xl sm:text-2xl lg:text-3xl text-black leading-tight truncate max-w-full">
                {title}
              </h1>
              {subtitle && (
                <p className="text-xs sm:text-sm text-muted-foreground leading-relaxed line-clamp-1 sm:line-clamp-2">
                  {subtitle}
                </p>
              )}
              {tagline && (
                <p className="text-[10px] sm:text-xs text-muted-foreground/80 italic truncate max-w-full">
                  {tagline}
                </p>
              )}
            </div>
          </div>

          <div className="flex items-center gap-1 sm:gap-3 ml-auto shrink-0">
            {actions}
            {showNotifications && (
              <AlertsDrawer
                alerts={alerts}
                alertsLoading={alertsLoading}
                unviewedCount={unviewedCount}
                onRefresh={() => dispatch(fetchAdminAlerts({ page: 1 }))}
                onAlertViewed={handleAlertViewed}
                onLoadMore={handleLoadMore}
                hasMore={!!alertsPagination && alertsPagination.page < alertsPagination.totalPages}
                loadingMore={moreAlertsLoading}
                totalCount={alertsPagination?.total || 0}
              />
            )}

            {showUserMenu && (
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button
                    variant="ghost"
                    className="flex items-center gap-2 hover:bg-primary/10 transition-colors shrink-0"
                  >
                    <Avatar className="h-8 w-8">
                      <AvatarFallback className="bg-gradient-to-br from-emerald-600 to-emerald-500 text-white font-semibold">
                        {getUserInitials()}
                      </AvatarFallback>
                    </Avatar>
                    <div className="text-left hidden md:block max-w-[160px]">
                      <p className="text-sm font-medium truncate">
                        {resolvedUser?.name || user?.name || "Admin User"}
                      </p>
                      <p className="text-xs text-muted-foreground truncate">
                        {resolvedUser?.role || user?.role || "Administrator"}
                      </p>
                    </div>
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-56">
                  <DropdownMenuLabel>My Account</DropdownMenuLabel>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem
                    className="cursor-pointer"
                    onClick={() => navigate("/profile")}
                  >
                    <User className="mr-2 h-4 w-4" />
                    <span>Profile</span>
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem
                    className="text-destructive cursor-pointer hover:bg-destructive/10 focus:bg-destructive/10 focus:text-destructive"
                    onClick={() => setShowLogoutDialog(true)}
                  >
                    <LogOut className="mr-2 h-4 w-4" />
                    <span>Logout</span>
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            )}
          </div>
        </div>
      </header>

      {/* Logout Confirmation Dialog */}
      <AlertDialog open={showLogoutDialog} onOpenChange={setShowLogoutDialog}>
        <AlertDialogContent className="max-w-md overflow-hidden border-2 border-destructive/20 animate-modal-in">
          {/* Animated background gradient */}
          <div className="absolute inset-0 bg-gradient-to-br from-destructive/5 via-transparent to-destructive/5 animate-gradient-shift" />

          {/* Animated warning icon circle */}
          <div className="absolute -top-12 -right-12 w-32 h-32 bg-destructive/10 rounded-full blur-2xl animate-pulse-slow" />
          <div
            className="absolute -bottom-12 -left-12 w-32 h-32 bg-orange-500/10 rounded-full blur-2xl animate-pulse-slow"
            style={{ animationDelay: "1s" }}
          />

          <AlertDialogHeader className="relative z-10">
            <div className="flex items-center justify-center mb-4">
              <div className="relative">
                {/* Animated rotating ring */}
                <div className="absolute inset-0 rounded-full border-4 border-destructive/20 animate-spin-slow" />
                <div className="absolute inset-2 rounded-full border-4 border-t-destructive border-r-transparent border-b-transparent border-l-transparent animate-spin" />

                {/* Icon container */}
                <div className="relative bg-gradient-to-br from-destructive/20 to-destructive/10 rounded-full p-6 animate-bounce-gentle">
                  <AlertTriangle className="h-12 w-12 text-destructive animate-pulse" />
                </div>
              </div>
            </div>

            <AlertDialogTitle className="text-2xl font-bold text-center animate-slide-down">
              <span className="bg-gradient-to-r from-destructive to-orange-600 bg-clip-text text-transparent">
                Confirm Logout
              </span>
            </AlertDialogTitle>

            <AlertDialogDescription className="text-center text-base pt-3 leading-relaxed animate-slide-up">
              Are you sure you want to logout?
              <br />
              <span className="text-muted-foreground/80">
                You will need to sign in again to access the admin dashboard.
              </span>
            </AlertDialogDescription>
          </AlertDialogHeader>

          <AlertDialogFooter
            className="gap-3 sm:gap-3 relative z-10 mt-6 animate-slide-up"
            style={{ animationDelay: "0.1s" }}
          >
            <AlertDialogCancel className="flex-1 hover:bg-muted transition-all hover:scale-105 active:scale-95">
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={handleLogout}
              className="flex-1 bg-gradient-to-r from-destructive to-orange-600 hover:from-destructive/90 hover:to-orange-600/90 text-white shadow-lg shadow-destructive/30 transition-all hover:scale-105 active:scale-95 hover:shadow-xl hover:shadow-destructive/40"
            >
              <LogOut className="mr-2 h-4 w-4" />
              Yes, Logout
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
