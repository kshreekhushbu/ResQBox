import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Send, Inbox } from "lucide-react";
import ComposeNotification from "../components/ComposeNotification";
import NotificationHistory from "../components/NotificationHistory";
import { usePermissions } from "@/hooks/usePermissions";


export default function Notifications() {
    const navigate = useNavigate();
    const permissions = usePermissions("notifications");
    const [activeTab, setActiveTab] = useState("compose");

    useEffect(() => {
        if (!permissions.hasRead) {
            navigate("/403", { replace: true });
        }
    }, [permissions.hasRead, navigate]);

    return (
        <div className="space-y-6">
            <Tabs defaultValue="compose" value={activeTab} onValueChange={setActiveTab} className="w-full space-y-8">
                <TabsList className="grid w-full grid-cols-2 max-w-[400px]">
                    <TabsTrigger value="compose" className="flex items-center gap-2">
                        <Send className="w-4 h-4" />
                        Compose
                    </TabsTrigger>
                    <TabsTrigger value="history" className="flex items-center gap-2">
                        <Inbox className="w-4 h-4" />
                        History
                    </TabsTrigger>
                </TabsList>

                <TabsContent value="compose" className="focus-visible:outline-none focus-visible:ring-0">
                    <ComposeNotification />
                </TabsContent>

                <TabsContent value="history" className="focus-visible:outline-none focus-visible:ring-0">
                    <NotificationHistory />
                </TabsContent>
            </Tabs>
        </div>
    );
}
