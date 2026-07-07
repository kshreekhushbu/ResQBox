import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "@/store/store";
import { checkActiveTickets } from "@/features/support/supportSlice";
import { checkDeletionRequests } from "@/features/users/usersSlice";
import { NavLink } from "@/components/NavLink";
import { useLocation } from "react-router-dom";
import { useState, useEffect } from "react";
import { HelpCircle } from "lucide-react";
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar,
} from "@/components/ui/sidebar";
import { Button } from "@/components/ui/button";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import resqboxLogo from "@/assets/logo.png";
import { MdMenuOpen } from "react-icons/md";
import { MenuItem, menuItems } from "./config";

export interface Permission {
  PageName: string;
  read: number;
  write: number;
  edit: number;
  delete: number;
}

export function AdminSidebar({ activePage }: { activePage?: string }) {
  const { open, toggleSidebar } = useSidebar();
  const location = useLocation();
  const dispatch = useDispatch<AppDispatch>();
  const currentPath = location.pathname;

  const isActive = (item: MenuItem) => {
    if (activePage) {
      return item.active === activePage;
    }
    return currentPath === item.menuLink;
  };
  const collapsed = !open;

  const { hasActiveTickets } = useSelector((state: RootState) => state.support);
  const { hasDeletionRequests } = useSelector((state: RootState) => state.users);

  useEffect(() => {
    dispatch(checkActiveTickets());
    dispatch(checkDeletionRequests());
    const interval = setInterval(() => {
      dispatch(checkActiveTickets());
      dispatch(checkDeletionRequests());
    }, 30000);
    return () => clearInterval(interval);
  }, [dispatch]);

  const hasPermission = (permissionKey: string): boolean => {
    const storageData = localStorage.getItem("AccessItems");

    const parsedData: Permission[] = storageData ? JSON.parse(storageData) : [];

    const requiredItem = parsedData.find(
      (item) => item.PageName === permissionKey
    );

    return !!requiredItem && requiredItem.read === 1;
  };

  return (
    <TooltipProvider delayDuration={0}>
      <Sidebar
        className="border-r border-sidebar-border bg-sidebar transition-all duration-300"
        collapsible="icon"
      >
        <div
          className={`flex h-16 items-center border-b border-sidebar-border ${collapsed ? "justify-center px-0 relative" : "justify-between px-4"
            }`}
        >
          {!collapsed ? (
            <>
              <div className="flex items-center gap-3 flex-1">
                <img src={resqboxLogo} alt="ResQBox" className="h-8 w-auto" />
              </div>
              <Button
                variant="ghost"
                size="icon"
                onClick={toggleSidebar}
                className="h-8 w-8 hover:bg-sidebar-accent transition-colors"
              >
                <MdMenuOpen className="h-5 w-5" />
                <span className="sr-only">Toggle Sidebar</span>
              </Button>
            </>
          ) : (
            <>
              <Button
                variant="ghost"
                size="icon"
                onClick={toggleSidebar}
                className="absolute top-2 right-1 h-7 w-7 hover:bg-sidebar-accent transition-colors"
              >
                <MdMenuOpen className="h-5 w-5" />
              </Button>
            </>
          )}
        </div>

        <SidebarContent className={collapsed ? "px-0 py-4" : "px-2 py-4"}>
          <SidebarGroup>
            {!collapsed && (
              <SidebarGroupLabel className="px-3 text-xs font-semibold text-sidebar-foreground/60 uppercase tracking-wider mb-2">
                Main Menu
              </SidebarGroupLabel>
            )}

            <SidebarGroupContent>
              <SidebarMenu
                className={collapsed ? "space-y-1 px-0" : "space-y-1"}
              >
                {menuItems
                  .filter((item) => hasPermission(item.permissionKey))
                  .map((item: MenuItem) => {
                    const active = isActive(item);
                    const isSupport = item.name === "Support Requests";
                    const isUsers = item.name === "Users";
                    const showIndicator = (isSupport && hasActiveTickets) || (isUsers && hasDeletionRequests);

                    if (collapsed) {
                      return (
                        <SidebarMenuItem key={item.name}>
                          <Tooltip>
                            <TooltipTrigger asChild>
                              <SidebarMenuButton
                                asChild
                                className={`
                                w-full justify-center px-0 py-2.5 rounded-lg transition-all duration-200 mx-auto relative
                                ${active
                                    ? "bg-gradient-to-r from-primary/15 to-primary/5 text-primary font-medium shadow-sm"
                                    : "text-sidebar-foreground/70 hover:bg-sidebar-accent hover:text-sidebar-foreground"
                                  }
                              `}
                              >
                                <NavLink
                                  to={item.menuLink}
                                  end
                                  className="flex items-center justify-center w-full h-full"
                                  activeClassName=""
                                >
                                  <div className="relative">
                                    <item.icon
                                      className={`flex-shrink-0 transition-transform ${active ? "scale-110" : ""
                                        }`}
                                      style={{ width: "20px", height: "20px" }}
                                    />
                                    {showIndicator && (
                                      <span className="absolute -top-1 -right-1 flex h-2.5 w-2.5">
                                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
                                        <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-red-500"></span>
                                      </span>
                                    )}
                                  </div>
                                </NavLink>
                              </SidebarMenuButton>
                            </TooltipTrigger>
                            <TooltipContent side="right" className="ml-2">
                              <p className="font-medium">{item.name}</p>
                            </TooltipContent>
                          </Tooltip>
                        </SidebarMenuItem>
                      );
                    }

                    return (
                      <SidebarMenuItem key={item.name}>
                        <SidebarMenuButton
                          asChild
                          className={`
                          w-full justify-start gap-3 px-3 py-2.5 rounded-lg transition-all duration-200
                          ${active
                              ? "bg-gradient-to-r from-primary/15 to-primary/5 text-primary font-medium shadow-sm border-l-2 border-primary"
                              : "text-sidebar-foreground/70 hover:bg-sidebar-accent hover:text-sidebar-foreground"
                            }
                        `}
                        >
                          <NavLink
                            to={item.menuLink}
                            end
                            className="flex items-center gap-3 w-full relative"
                            activeClassName=""
                          >
                            <div className="relative">
                              <item.icon
                                className={`flex-shrink-0 transition-transform ${active ? "scale-110" : ""
                                  }`}
                                style={{ width: "18px", height: "18px" }}
                              />
                            </div>
                            <span className="text-sm font-medium truncate flex-1">
                              {item.name}
                            </span>
                            {showIndicator && (
                              <span className="flex h-2.5 w-2.5">
                                <span className="animate-ping absolute inline-flex h-2.5 w-2.5 rounded-full bg-red-400 opacity-75"></span>
                                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-red-500"></span>
                              </span>
                            )}
                          </NavLink>
                        </SidebarMenuButton>
                      </SidebarMenuItem>
                    );
                  })}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        </SidebarContent>

        {!collapsed && (
          <div className="border-t border-sidebar-border p-4">
            <div className="bg-gradient-to-br from-primary/10 via-primary/5 to-secondary/10 rounded-lg p-4 border border-primary/20">
              <div className="flex items-start gap-2">
                <div className="rounded-full bg-primary/20 p-1.5">
                  <HelpCircle className="h-3.5 w-3.5 text-primary" />
                </div>
                <div>
                  <p className="text-xs font-semibold text-sidebar-foreground mb-0.5">
                    ResQBox Food Mission
                  </p>
                  <p className="text-xs text-sidebar-foreground/70 leading-relaxed">
                    Making every meal count
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}
      </Sidebar>
    </TooltipProvider>
  );
}
