import { LucideIcon } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";
import { TrendingUp, TrendingDown } from "lucide-react";
import { useEffect, useState } from "react";

interface StatCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  variant?: "success" | "warning" | "default" | "info";
  trend?: {
    value: number;
    isPositive: boolean;
  };
  loading?: boolean;
  onClick?: () => void;
}

export function StatCard({
  title,
  value,
  icon: Icon,
  variant = "default",
  trend,
  loading = false,
  onClick,
}: StatCardProps) {
  const [displayValue, setDisplayValue] = useState(0);

  // Animated counter effect
  useEffect(() => {
    if (loading) return;

    const numericValue = typeof value === 'string'
      ? parseInt(value.replace(/,/g, ''))
      : value;

    if (isNaN(numericValue)) {
      return;
    }

    let start = 0;
    const duration = 1000;
    const increment = numericValue / (duration / 16);

    const timer = setInterval(() => {
      start += increment;
      if (start >= numericValue) {
        setDisplayValue(numericValue);
        clearInterval(timer);
      } else {
        setDisplayValue(Math.floor(start));
      }
    }, 16);

    return () => clearInterval(timer);
  }, [value, loading]);

  const variantStyles = {
    success: "from-green-500/10 via-green-500/5 to-transparent border-green-500/20 hover:border-green-500/40",
    warning: "from-orange-500/10 via-orange-500/5 to-transparent border-orange-500/20 hover:border-orange-500/40",
    info: "from-blue-500/10 via-blue-500/5 to-transparent border-blue-500/20 hover:border-blue-500/40",
    default: "from-primary/10 via-primary/5 to-transparent border-border hover:border-primary/40",
  };

  const iconVariantStyles = {
    success: "bg-gradient-to-br from-green-500/20 to-green-500/10 text-green-600 dark:text-green-400",
    warning: "bg-gradient-to-br from-orange-500/20 to-orange-500/10 text-orange-600 dark:text-orange-400",
    info: "bg-gradient-to-br from-blue-500/20 to-blue-500/10 text-blue-600 dark:text-blue-400",
    default: "bg-gradient-to-br from-primary/20 to-primary/10 text-primary",
  };

  const trendColorStyles = {
    success: "text-green-600 dark:text-green-400",
    warning: "text-orange-600 dark:text-orange-400",
    info: "text-blue-600 dark:text-blue-400",
    default: "text-primary",
  };

  if (loading) {
    return (
      <Card className="border bg-gradient-to-br from-muted/50 to-transparent">
        <CardContent className="p-6">
          <div className="flex items-start justify-between">
            <div className="space-y-3 flex-1">
              <Skeleton className="h-4 w-24" />
              <Skeleton className="h-8 w-20" />
              <Skeleton className="h-3 w-16" />
            </div>
            <Skeleton className="h-12 w-12 rounded-xl" />
          </div>
        </CardContent>
      </Card>
    );
  }

  const formattedValue = typeof value === 'string' ? value : displayValue.toLocaleString();

  const valueColorStyles = {
    success: "text-green-600 dark:text-green-400 drop-shadow-sm",
    warning: "text-orange-600 dark:text-orange-400 drop-shadow-sm",
    info: "text-blue-600 dark:text-blue-400 drop-shadow-sm",
    default: "text-primary drop-shadow-sm",
  };

  return (
    <Card
      onClick={onClick}
      className={cn(
        "group relative overflow-hidden border bg-gradient-to-br transition-all duration-300 hover:shadow-hover hover:scale-[1.05]",
        onClick && "cursor-pointer",
        variantStyles[variant]
      )}
    >
      <div className="absolute inset-0 bg-gradient-to-br from-transparent via-transparent to-primary/10 opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
      <CardContent className="relative p-7">
        <div className="flex items-center justify-between gap-4">
          <div className="space-y-1.5 flex-1 min-w-0">
            <p className={cn("text-[11px] font-bold uppercase tracking-[0.2em] mb-1 opacity-80", trendColorStyles[variant])}>
              {title}
            </p>
            <p className={cn("text-3xl font-black tracking-tighter truncate transition-all duration-300 group-hover:scale-105 origin-left", valueColorStyles[variant])}>
              {formattedValue}
            </p>
            {trend && (
              <div className="flex items-center gap-2 mt-2">
                <div className={cn("flex items-center gap-0.5 px-1.5 py-0.5 rounded-md text-[10px] font-bold",
                  trend.isPositive ? iconVariantStyles[variant] : "bg-destructive/10 text-destructive")}>
                  {trend.isPositive ? (
                    <TrendingUp className="h-3 w-3" />
                  ) : (
                    <TrendingDown className="h-3 w-3" />
                  )}
                  {trend.value}%
                </div>
                <span className="text-[10px] font-medium text-muted-foreground/60 italic whitespace-nowrap">vs last mth</span>
              </div>
            )}
          </div>
          <div
            className={cn(
              "p-4 rounded-2xl transition-all duration-500 group-hover:scale-110 group-hover:rotate-3 shadow-sm shrink-0",
              iconVariantStyles[variant]
            )}
          >
            <Icon className="h-8 w-8" />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
