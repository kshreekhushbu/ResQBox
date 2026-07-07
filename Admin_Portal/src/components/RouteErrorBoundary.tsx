import { ReactNode } from "react";
import ErrorBoundary from "./ErrorBoundary";

interface RouteErrorBoundaryProps {
  children: ReactNode;
}

export function RouteErrorBoundary({
  children,
}: RouteErrorBoundaryProps) {
  return <ErrorBoundary>{children}</ErrorBoundary>;
}
