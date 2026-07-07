import { v4 as uuidV4 } from "uuid";
import {
  Bell,
  FolderTree,
  Image,
  LayoutDashboard,
  MessageCircleHeart,
  Package,
  Settings,
  Shield,
  UserCog,
  Users,
  Wallet,
} from "lucide-react";
import { LiaFileInvoiceDollarSolid } from "react-icons/lia";
import { IoRestaurant } from "react-icons/io5";

export interface MenuItem {
  id: string;
  name: string;
  menuLink: string;
  active: string;
  icon: React.ElementType;
  permissionKey: string;
}

export const menuItems: MenuItem[] = [
  {
    id: uuidV4(),
    name: "Dashboard",
    menuLink: "/dashboard",
    active: "Dashboard",
    icon: LayoutDashboard,
    permissionKey: "dashboard",
  },
  {
    id: uuidV4(),
    name: "Banners",
    menuLink: "/banners",
    active: "Banners",
    icon: Image,
    permissionKey: "banners",
  },
  {
    id: uuidV4(),
    name: "Categories",
    menuLink: "/categories",
    active: "Categories",
    icon: FolderTree,
    permissionKey: "categories",
  },
  {
    id: uuidV4(),
    name: "Restaurants",
    menuLink: "/restaurants",
    active: "Restaurants",
    icon: IoRestaurant,
    permissionKey: "restaurants",
  },
  {
    id: uuidV4(),
    name: "Users",
    menuLink: "/users",
    active: "Users",
    icon: Users,
    permissionKey: "users",
  },
  {
    id: uuidV4(),
    name: "Orders",
    menuLink: "/orders",
    active: "Orders",
    icon: Package,
    permissionKey: "orders",
  },

  {
    id: uuidV4(),
    name: "Roles",
    menuLink: "/roles",
    active: "Roles",
    icon: Shield,
    permissionKey: "roles",
  },
  {
    id: uuidV4(),
    name: "Teams",
    menuLink: "/teams",
    active: "Teams",
    icon: UserCog,
    permissionKey: "teams",
  },

  {
    id: uuidV4(),
    name: "Payouts",
    menuLink: "/payouts",
    active: "Payouts",
    icon: Wallet,
    permissionKey: "payouts",
  },
  {
    id: uuidV4(),
    name: "Invoices",
    menuLink: "/invoices",
    active: "Invoices",
    icon: LiaFileInvoiceDollarSolid,
    permissionKey: "invoices",
  },
  {
    id: uuidV4(),
    name: "Config",
    menuLink: "/config",
    active: "Config",
    icon: Settings,
    permissionKey: "config",
  },
  {
    id: uuidV4(),
    name: "Notifications",
    menuLink: "/notifications",
    active: "Notifications",
    icon: Bell,
    permissionKey: "notifications",
  },
  {
    id: uuidV4(),
    name: "Support Requests",
    menuLink: "/support-requests",
    active: "Support Requests",
    icon: MessageCircleHeart,
    permissionKey: "support requests",
  },
];
