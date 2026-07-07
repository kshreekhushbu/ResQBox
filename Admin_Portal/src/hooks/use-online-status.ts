import { useState, useEffect } from "react";

interface UseOnlineStatusReturn {
  isOnline: boolean;
  wasOffline: boolean;
}

/**
 * Custom hook to track online/offline status
 * @returns Object with isOnline status and wasOffline flag
 */
export function useOnlineStatus(): UseOnlineStatusReturn {
  const [isOnline, setIsOnline] = useState<boolean>(() => {
    if (typeof window !== "undefined" && "navigator" in window) {
      return navigator.onLine;
    }
    return true;
  });

  const [wasOffline, setWasOffline] = useState<boolean>(false);

  useEffect(() => {
    // Set initial state
    setIsOnline(navigator.onLine);

    const handleOnline = () => {
      setIsOnline(true);
      if (wasOffline) {
        // Keep wasOffline true briefly to show reconnection notification
        setTimeout(() => {
          setWasOffline(false);
        }, 100);
      }
    };

    const handleOffline = () => {
      setIsOnline(false);
      setWasOffline(true);
    };

    // Add event listeners
    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);

    // Cleanup
    return () => {
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
    };
  }, [wasOffline]);

  return { isOnline, wasOffline };
}
