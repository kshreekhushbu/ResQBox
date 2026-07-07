import { useState, useRef, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
    Bell,
    AlertCircle,
    Clock,
    FileText,
    Calendar,
    Image as ImageIcon,
    X,
} from "lucide-react";
import {
    Sheet,
    SheetClose,
    SheetContent,
    SheetDescription,
    SheetHeader,
    SheetTitle,
    SheetTrigger,
} from "@/components/ui/sheet";
import {
    Accordion,
    AccordionContent,
    AccordionItem,
    AccordionTrigger,
} from "@/components/ui/accordion";
import { AdminAlert } from "../types";
import { markAlertAsViewed } from "../kitchenService";

interface AlertsDrawerProps {
    alerts: AdminAlert[];
    alertsLoading: boolean;
    unviewedCount: number;
    onRefresh: () => void;
    onAlertViewed: (alertId: number) => void;
    onLoadMore: () => void;
    hasMore: boolean;
    loadingMore: boolean;
    totalCount?: number;
}

export function AlertsDrawer({
    alerts,
    alertsLoading,
    unviewedCount,
    onRefresh,
    onAlertViewed,
    onLoadMore,
    hasMore,
    loadingMore,
    totalCount = 0,
}: AlertsDrawerProps) {
    const navigate = useNavigate();
    const [isOpen, setIsOpen] = useState(false);
    const [expandedAlert, setExpandedAlert] = useState<string>("");
    const observer = useRef<IntersectionObserver>();
    const lastAlertElementRef = useCallback(
        (node: HTMLDivElement) => {
            if (alertsLoading || loadingMore) return;
            if (observer.current) observer.current.disconnect();

            observer.current = new IntersectionObserver((entries) => {
                if (entries[0].isIntersecting && hasMore) {
                    onLoadMore();
                }
            });

            if (node) observer.current.observe(node);
        },
        [alertsLoading, loadingMore, hasMore, onLoadMore]
    );

    const formatRelativeTime = (dateString: string) => {
        const date = new Date(dateString);
        const now = new Date();
        const diffMs = now.getTime() - date.getTime();
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        const diffDays = Math.floor(diffMs / 86400000);

        if (diffMins < 60) return `${diffMins} min${diffMins !== 1 ? "s" : ""} ago`;
        if (diffHours < 24)
            return `${diffHours} hour${diffHours !== 1 ? "s" : ""} ago`;
        return `${diffDays} day${diffDays !== 1 ? "s" : ""} ago`;
    };

    const handleAccordionChange = async (value: string) => {
        setExpandedAlert(value);

        if (value) {
            const alertId = parseInt(value);
            const alert = alerts.find((a) => a.id === alertId);
            if (alert && !alert.isViewed) {
                try {
                    await markAlertAsViewed(alertId);
                    onAlertViewed(alertId);
                } catch (error: any) {
                    console.error("Failed to mark alert as viewed:", error);
                }
            }
        }
    };

    const formatMetadataValue = (key: string, value: any): string => {
        if (value === null || value === undefined) return "N/A";

        if (
            key.toLowerCase().includes("date") ||
            key.toLowerCase().includes("at")
        ) {
            try {
                return new Date(value).toLocaleString();
            } catch {
                return String(value);
            }
        }

        if (key.toLowerCase().includes("image") && typeof value === "string") {
            return value;
        }

        return String(value);
    };

    return (
        <Sheet open={isOpen} onOpenChange={setIsOpen}>
            <SheetTrigger asChild>
                <Button
                    variant="ghost"
                    size="icon"
                    className="relative h-9 w-9 hover:bg-primary/10 transition-colors rounded-full"
                >
                    <Bell className="h-5 w-5 text-muted-foreground" />
                    {unviewedCount > 0 && (
                        <span className="absolute -top-0.5 -right-0.5 h-4 w-4 rounded-full bg-destructive text-white text-[10px] flex items-center justify-center font-bold animate-pulse shadow-sm">
                            {unviewedCount}
                        </span>
                    )}
                    <span className="sr-only">Toggle Alerts Dashboard</span>
                </Button>
            </SheetTrigger>
            <SheetContent
                side="right"
                className="w-full sm:w-[600px] md:w-[700px] p-0 flex flex-col"
            >
                <SheetHeader className="border-b bg-gradient-to-r from-background to-muted/20 px-6 py-4 flex-shrink-0">
                    <SheetTitle className="text-2xl font-bold flex items-center gap-2">
                        <AlertCircle className="h-6 w-6 text-destructive" />
                        Critical Alerts
                    </SheetTitle>
                    <SheetDescription className="mt-1">
                        {totalCount} notification{totalCount !== 1 ? "s" : ""} •{" "}
                        {unviewedCount} unviewed
                    </SheetDescription>
                </SheetHeader>

                <div
                    className="flex-1 overflow-y-auto px-6 py-4"
                    style={{ minHeight: 0 }}
                >
                    {alertsLoading ? (
                        <div className="flex items-center justify-center h-full">
                            <div className="text-center space-y-3">
                                <div className="animate-spin h-8 w-8 border-4 border-primary border-t-transparent rounded-full mx-auto"></div>
                                <p className="text-sm text-muted-foreground">
                                    Loading alerts...
                                </p>
                            </div>
                        </div>
                    ) : alerts.length === 0 ? (
                        <div className="flex items-center justify-center h-full">
                            <div className="text-center space-y-3">
                                <Bell className="h-12 w-12 text-muted-foreground mx-auto opacity-50" />
                                <p className="text-muted-foreground">No alerts available</p>
                            </div>
                        </div>
                    ) : (
                        <Accordion
                            type="single"
                            collapsible
                            value={expandedAlert}
                            onValueChange={handleAccordionChange}
                            className="space-y-3"
                        >
                            {alerts.map((alert) => (
                                <AccordionItem
                                    key={alert.id}
                                    value={alert.id.toString()}
                                    className={`border rounded-lg overflow-hidden transition-all ${!alert.isViewed
                                        ? "border-l-4 border-l-destructive bg-destructive/5"
                                        : "bg-card"
                                        }`}
                                >
                                    <AccordionTrigger className="px-4 py-3 hover:no-underline hover:bg-muted/30 transition-colors">
                                        <div className="flex items-start gap-3 w-full text-left">
                                            <div className="flex-shrink-0 mt-1">
                                                <div
                                                    className={`h-10 w-10 rounded-full flex items-center justify-center ${!alert.isViewed ? "bg-destructive/10" : "bg-muted"
                                                        }`}
                                                >
                                                    <AlertCircle
                                                        className={`h-5 w-5 ${!alert.isViewed
                                                            ? "text-destructive"
                                                            : "text-muted-foreground"
                                                            }`}
                                                    />
                                                </div>
                                            </div>
                                            <div className="flex-1 space-y-2 pr-4 min-w-0">
                                                <div className="flex items-start justify-between gap-2">
                                                    <h4 className="font-semibold text-sm leading-tight break-all">
                                                        {alert.title}
                                                    </h4>
                                                    {!alert.isViewed && (
                                                        <Badge
                                                            variant="destructive"
                                                            className="text-xs px-2 py-0 h-5"
                                                        >
                                                            New
                                                        </Badge>
                                                    )}
                                                </div>
                                                <p className="text-sm text-foreground/80 leading-relaxed line-clamp-2 break-all">
                                                    {alert.message}
                                                </p>
                                                <div className="flex items-center gap-1 text-xs text-muted-foreground">
                                                    <Clock className="h-3 w-3" />
                                                    {formatRelativeTime(alert.createdAt)}
                                                </div>
                                            </div>
                                        </div>
                                    </AccordionTrigger>
                                    <AccordionContent className="px-4 pb-4 pt-2">
                                        <div className="pl-[52px] space-y-4">
                                            <div className="space-y-2">
                                                <div className="flex items-center gap-2 text-xs font-semibold text-muted-foreground uppercase tracking-wide">
                                                    <FileText className="h-3 w-3" />
                                                    Full Details
                                                </div>
                                                <p className="text-sm text-foreground/90 leading-relaxed bg-muted/30 p-3 rounded-md break-all">
                                                    {alert.message}
                                                </p>
                                            </div>
                                            {alert.kitchen && (
                                                <div className="space-y-3">
                                                    <div className="flex items-center justify-between">
                                                        <div className="text-xs font-semibold text-muted-foreground uppercase tracking-wide">
                                                            Kitchen Information
                                                        </div>
                                                        <a
                                                            className="text-xs font-medium text-primary underline hover:text-primary/80 transition-colors cursor-pointer"
                                                            onClick={(e) => {
                                                                e.preventDefault();
                                                                navigate(`/restaurants/${alert.kitchen!.kitchenId}`);
                                                                setIsOpen(false);
                                                            }}
                                                        >
                                                            View Kitchen
                                                        </a>
                                                    </div>
                                                    <div className="flex flex-wrap items-center gap-2">
                                                        <Badge variant="outline" className="text-xs break-all">
                                                            {alert.kitchen.kitchenName}
                                                        </Badge>
                                                        <Badge variant="secondary" className="text-xs">
                                                            ID: {alert.kitchen.kitchenId}
                                                        </Badge>
                                                        <Badge variant="secondary" className="text-xs break-all">
                                                            {alert.alertType.replace(/_/g, " ")}
                                                        </Badge>
                                                    </div>
                                                </div>
                                            )}

                                            {alert.metadata &&
                                                Object.keys(alert.metadata).length > 0 && (
                                                    <div className="space-y-2">
                                                        <div className="flex items-center gap-2 text-xs font-semibold text-muted-foreground uppercase tracking-wide">
                                                            <Calendar className="h-3 w-3" />
                                                            Additional Information
                                                        </div>
                                                        <div className="bg-muted/30 rounded-md p-3 space-y-2">
                                                            {Object.entries(alert.metadata).map(
                                                                ([key, value]) => {
                                                                    if (value === null || value === undefined)
                                                                        return null;

                                                                    const isImage =
                                                                        key.toLowerCase().includes("image") &&
                                                                        typeof value === "string";

                                                                    return (
                                                                        <div
                                                                            key={key}
                                                                            className="flex items-start gap-2 text-sm"
                                                                        >
                                                                            <span className="font-medium text-foreground/70 capitalize min-w-[120px]">
                                                                                {key
                                                                                    .replace(/([A-Z])/g, " $1")
                                                                                    .replace(/_/g, " ")
                                                                                    .trim()}
                                                                                :
                                                                            </span>
                                                                            {isImage ? (
                                                                                <div className="flex items-center gap-2">
                                                                                    <ImageIcon className="h-4 w-4 text-muted-foreground" />
                                                                                    <a
                                                                                        href={value}
                                                                                        target="_blank"
                                                                                        rel="noopener noreferrer"
                                                                                        className="text-primary hover:underline text-xs"
                                                                                    >
                                                                                        View Image
                                                                                    </a>
                                                                                </div>
                                                                            ) : (
                                                                                <span className="text-foreground/90 flex-1 break-all">
                                                                                    {formatMetadataValue(key, value)}
                                                                                </span>
                                                                            )}
                                                                        </div>
                                                                    );
                                                                }
                                                            )}
                                                        </div>
                                                    </div>
                                                )}

                                            <div className="space-y-2 pt-2 border-t">
                                                <div className="grid grid-cols-2 gap-3 text-xs">
                                                    {alert.viewedAt && (
                                                        <div>
                                                            <span className="text-muted-foreground">
                                                                Viewed:
                                                            </span>
                                                            <p className="font-medium text-foreground/80 mt-1">
                                                                {new Date(alert.viewedAt).toLocaleString()}
                                                            </p>
                                                        </div>
                                                    )}
                                                </div>
                                            </div>
                                        </div>
                                    </AccordionContent>
                                </AccordionItem>
                            ))}
                        </Accordion>
                    )}

                    {/* Infinite Scroll Sentinel & Loader */}
                    {(hasMore || loadingMore) && (
                        <div
                            ref={lastAlertElementRef}
                            className="py-4 flex flex-col items-center justify-center text-muted-foreground w-full"
                        >
                            {loadingMore && (
                                <div className="flex items-center gap-2 text-xs">
                                    <div className="h-4 w-4 animate-spin rounded-full border-2 border-primary border-t-transparent"></div>
                                    <span>Loading more alerts...</span>
                                </div>
                            )}
                        </div>
                    )}
                </div>

                <div className="border-t p-4 bg-muted/20 flex-shrink-0">
                    <div className="flex gap-2">
                        <Button
                            variant="outline"
                            className="flex-1"
                            onClick={onRefresh}
                            disabled={alertsLoading}
                        >
                            Refresh
                        </Button>
                        <SheetClose asChild>
                            <Button variant="default" className="flex-1">
                                Close
                            </Button>
                        </SheetClose>
                    </div>
                </div>
            </SheetContent>
        </Sheet >
    );
}
