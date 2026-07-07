import Banners from "@/features/banners/pages/banners";
import Categories from "@/features/categories/pages/categories";
import AddEditConfig from "@/features/configs/pages/AddEditConfig";
import Dashboard from "@/features/dashboard/pages/dashboard";
import Payouts from "@/features/payouts/pages/payouts";
import Restaurants from "@/features/restarents/pages/restarents";
import Permissions from "@/features/permissions/pages/permissions";
import AddEditRole from "@/features/permissions/pages/AddEditRole";
import SupportRequests from "@/features/support/pages/support";
import Teams from "@/features/team/pages/Teams";
import Notifications from "@/features/notifications/pages/Notifications";
import Users from "@/features/users/pages/users";
import orders from "@/features/orders/pages/orders";
import OrderDetails from "@/features/orders/pages/orderDetails";
import Invoices from "@/features/invoices/pages/invoices";
import AddEditTeam from "@/features/team/pages/AddEditTeam";
import Configs from "@/features/configs/pages/Configs";
import PayoutDetails from "@/features/payouts/pages/PayoutDetails";
import KitchenDetails from "@/features/restarents/pages/KitchenDetails";

interface RouteConfig {
  path: string;
  Element: React.ComponentType;
  Type: string;
  Name: string;
}

export const Config: RouteConfig[] = [
  {
    path: "/dashboard",
    Element: Dashboard,
    Type: "read",
    Name: "Dashboard",
  },
  {
    path: "/banners",
    Element: Banners,
    Type: "read",
    Name: "Banners",
  },
  {
    path: "/roles",
    Element: Permissions,
    Type: "read",
    Name: "Roles",
  },
  {
    path: "/roles/add",
    Element: AddEditRole,
    Type: "write",
    Name: "Roles",
  },
  {
    path: "/roles/edit/:id",
    Element: AddEditRole,
    Type: "update",
    Name: "Roles",
  },
  {
    path: "/teams",
    Element: Teams,
    Type: "read",
    Name: "Teams",
  },
  {
    path: "/teams/add",
    Element: AddEditTeam,
    Type: "write",
    Name: "Teams",
  },
  {
    path: "/teams/edit/:id",
    Element: AddEditTeam,
    Type: "update",
    Name: "Teams",
  },
  {
    path: "/categories",
    Element: Categories,
    Type: "read",
    Name: "Categories",
  },
  {
    path: "/restaurants",
    Element: Restaurants,
    Type: "read",
    Name: "Restaurants",
  },
  {
    path: "/restaurants/:id",
    Element: KitchenDetails,
    Type: "read",
    Name: "Restaurants",
  },
  {
    path: "/users",
    Element: Users,
    Type: "read",
    Name: "Users",
  },
  {
    path: "/orders",
    Element: orders,
    Type: "read",
    Name: "Orders",
  },
  {
    path: "/orders/:id",
    Element: OrderDetails,
    Type: "read",
    Name: "Orders",
  },

  {
    path: "/config",
    Element: Configs,
    Type: "read",
    Name: "Config",
  },
  {
    path: "/config/edit/:id",
    Element: AddEditConfig,
    Type: "update",
    Name: "Config",
  },
  {
    path: "/payouts",
    Element: Payouts,
    Type: "read",
    Name: "Payouts",
  },
  {
    path: "/payouts/:kitchenId",
    Element: PayoutDetails,
    Type: "read",
    Name: "Payouts",
  },
  {
    path: "/support-requests",
    Element: SupportRequests,
    Type: "read",
    Name: "Support Requests",
  },
  {
    path: "/notifications",
    Element: Notifications,
    Type: "read",
    Name: "Notifications",
  },
  {
    path: "/invoices",
    Element: Invoices,
    Type: "read",
    Name: "Invoices",
  },
];
