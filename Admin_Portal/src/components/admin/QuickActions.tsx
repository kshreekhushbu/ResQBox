import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useNavigate } from "react-router-dom";
import {
  Plus,
  FileText,
  Users,
  Settings,
  Bell,
  TrendingUp,
} from "lucide-react";
import { cn } from "@/lib/utils";

interface QuickAction {
  title: string;
  description: string;
  icon: React.ElementType;
  path: string;
  variant: "default" | "success" | "warning" | "info";
}

const actions: QuickAction[] = [
  {
    title: "Manage Restaurants",
    description: "Manage Restaurants",
    icon: Plus,
    path: "/restaurants",
    variant: "success",
  },
  {
    title: "View Reports",
    description: "Analytics & insights (On Hold)",
    icon: FileText,
    path: "",
    variant: "info",
  },
  {
    title: "Manage Users",
    description: "User administration",
    icon: Users,
    path: "/users",
    variant: "default",
  },
  {
    title: "Settings",
    description: "System configuration",
    icon: Settings,
    path: "/config",
    variant: "default",
  },
];

export function QuickActions() {
  const navigate = useNavigate();

  const variantStyles = {
    success: "from-green-500/20 to-green-500/10 border-green-500/30 hover:border-green-500/50 text-green-700 dark:text-green-400 font-bold",
    info: "from-blue-500/20 to-blue-500/10 border-blue-500/30 hover:border-blue-500/50 text-blue-700 dark:text-blue-400 font-bold",
    default: "from-primary/20 to-primary/10 border-primary/30 hover:border-primary/50 text-primary font-bold",
  };

  return (
    <Card className="border">
      <CardHeader>
        <CardTitle className="text-lg font-semibold flex items-center gap-2">
          <TrendingUp className="h-5 w-5" />
          Quick Actions
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {actions.map((action, index) => {
          const Icon = action.icon;
          return (
            <button
              key={index}
              onClick={() => action.path && navigate(action.path)}
              disabled={!action.path}
              className={cn(
                "group w-full flex items-center gap-4 p-4 rounded-lg border bg-gradient-to-br transition-all duration-300 hover:shadow-md hover:scale-[1.02]",
                variantStyles[action.variant],
                !action.path && "opacity-60 cursor-not-allowed hover:scale-100 hover:shadow-none"
              )}
            >
              <div className="p-2 rounded-lg bg-background/50 group-hover:scale-110 transition-transform duration-300">
                <Icon className="h-5 w-5" />
              </div>
              <div className="flex-1 text-left">
                <p className="font-semibold text-sm text-foreground">
                  {action.title}
                </p>
                <p className="text-xs text-muted-foreground">
                  {action.description}
                </p>
              </div>
              <div className="opacity-0 group-hover:opacity-100 transition-opacity">
                <svg
                  className="h-5 w-5"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 5l7 7-7 7"
                  />
                </svg>
              </div>
            </button>
          );
        })}
      </CardContent>
    </Card>
  );
}
