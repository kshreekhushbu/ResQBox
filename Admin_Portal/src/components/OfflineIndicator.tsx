import { useEffect, useState } from "react";
import { Wifi } from "lucide-react";
import {
  Card,
  CardContent,
} from "@/components/ui/card";
import { useOnlineStatus } from "@/hooks/use-online-status";
import OfflinePage from "@/features/OfflinePage";

export function OfflineIndicator() {
  const { isOnline, wasOffline } = useOnlineStatus();
  const [showOnlineNotification, setShowOnlineNotification] = useState(false);

  useEffect(() => {
    if (!isOnline) {
      setShowOnlineNotification(false);
    } else if (wasOffline && isOnline) {
      setShowOnlineNotification(true);
      const timer = setTimeout(() => {
        setShowOnlineNotification(false);
      }, 3000);
      return () => clearTimeout(timer);
    }
  }, [isOnline, wasOffline]);

  // Show full-screen offline page
  if (!isOnline) {
    return <OfflinePage />;
  }

  if (showOnlineNotification) {
    return (
      <div className="fixed top-4 right-4 z-50 animate-in slide-in-from-top-5">
        <Card className="w-80 shadow-lg">
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="rounded-full bg-green-500/10 p-2">
                <Wifi className="h-5 w-5 text-green-600 dark:text-green-400" />
              </div>
              <div className="flex-1">
                <p className="font-semibold">Back Online!</p>
                <p className="text-sm text-muted-foreground">
                  Connection restored
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return null;
}
