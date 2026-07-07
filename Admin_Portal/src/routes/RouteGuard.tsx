import { useLayoutEffect, useState } from "react";
import { Navigate, Outlet } from "react-router-dom";

interface AccessItem {
  PageName: string;
  read?: number;
  edit?: number;
  write?: number;
  delete?: number;
  [key: string]: any;
}

interface RouteGuardProps {
  pageName: string;
  requiredPermission: keyof AccessItem;
}

const RouteGuard: React.FC<RouteGuardProps> = ({
  pageName,
  requiredPermission,
}) => {
  const [permissionState, setPermissionState] = useState<
    "granted" | "forbidden" | "unauthorized"
  >("unauthorized");

  useLayoutEffect(() => {
    const stored = localStorage.getItem("AccessItems");
    const AccessItems: AccessItem[] = stored ? JSON.parse(stored) : [];

    const page = AccessItems.find((item) => item?.PageName === pageName);

    if (!page) {
      setPermissionState("unauthorized");
    } else if (page[requiredPermission] === 1) {
      setPermissionState("granted");
    } else {
      setPermissionState("forbidden");
    }
  }, [pageName, requiredPermission]);

  if (permissionState === "granted") return <Outlet />;
  if (permissionState === "forbidden") return <Navigate to="/403" replace />;
  return <Navigate to="/forbidden" replace />;
};

export default RouteGuard;
