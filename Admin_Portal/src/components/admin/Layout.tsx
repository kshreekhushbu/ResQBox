import { SidebarInset, SidebarProvider } from "@/components/ui/sidebar";
import { AdminSidebar } from "./AdminSidebar";
import { Header } from "./Header";

interface AdminLayoutProps {
  children: React.ReactNode;
  Active?: string;
  header?: {
    title: string;
    subtitle?: string;
    actions?: React.ReactNode;
    showNotifications?: boolean;
    showUserMenu?: boolean;
  };
}

export function Layout({ children, Active, header }: AdminLayoutProps) {
  return (
    <SidebarProvider>
      <div className="flex min-h-screen w-full">
        <AdminSidebar activePage={Active} />
        <SidebarInset className="bg-background w-full overflow-x-hidden">
          {header && (
            <Header
              title={header.title}
              subtitle={header.subtitle}
              actions={header.actions}
              showNotifications={header.showNotifications}
              showUserMenu={header.showUserMenu}
            />
          )}
          <div className="container mx-auto p-4 sm:p-6 space-y-6">{children}</div>
        </SidebarInset>
      </div>
    </SidebarProvider>
  );
}
