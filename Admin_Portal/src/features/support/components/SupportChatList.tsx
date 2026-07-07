import React, { useState, useEffect } from "react";
import { Search, MessageSquare } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { DynamicTable, TableColumn } from "@/components/table/DynamicTable";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { cn } from "@/lib/utils";
import { format } from "date-fns";
import type { SupportChatUI } from "../types";
import Pagination from "@/components/Pagination/Pagination";

interface SupportChatListProps {
    userChats: SupportChatUI[];
    kitchenChats: SupportChatUI[];
    activeTab: "users" | "kitchens";
    onTabChange: (tab: "users" | "kitchens") => void;
    searchTerm: string;
    onSearchChange: (term: string) => void;
    isLoading: boolean;
    onChatSelect: (chat: SupportChatUI) => void;
}

export const SupportChatList: React.FC<SupportChatListProps> = ({
    userChats,
    kitchenChats,
    activeTab,
    onTabChange,
    searchTerm,
    onSearchChange,
    isLoading,
    onChatSelect
}) => {
    const [currentPage, setCurrentPage] = useState(1);
    const ITEMS_PER_PAGE = 10;

    useEffect(() => {
        setCurrentPage(1);
    }, [activeTab, searchTerm]);

    const currentChats = activeTab === "users" ? userChats : kitchenChats;

    const filteredChats = currentChats.filter(c => {
        const searchLower = searchTerm.toLowerCase();
        if (c.user) {
            return c.user?.name?.toLowerCase().includes(searchLower) ||
                c.lastMessage?.toLowerCase().includes(searchLower);
        } else if (c.kitchen) {
            return c.kitchen?.kitchenName?.toLowerCase().includes(searchLower) ||
                c.lastMessage?.toLowerCase().includes(searchLower);
        }
        return false;
    });

    const totalPages = Math.ceil(filteredChats.length / ITEMS_PER_PAGE);
    const paginatedChats = filteredChats.slice(
        (currentPage - 1) * ITEMS_PER_PAGE,
        currentPage * ITEMS_PER_PAGE
    );

    const columns: TableColumn<SupportChatUI>[] = [
        {
            key: "entity",
            label: activeTab === "users" ? "User" : "Kitchen",
            render: (_, record) => {
                if (record.user) {
                    return (
                        <div className="flex items-center gap-3">
                            <Avatar className="h-9 w-9 border border-border">
                                <AvatarImage src={record.user.profilePicture || undefined} />
                                <AvatarFallback>{record.user.name?.substring(0, 2).toUpperCase() || "?"}</AvatarFallback>
                            </Avatar>
                            <div>
                                <p className="font-medium text-sm text-foreground truncate max-w-[150px]" title={record.user.name || "Unknown"}>{record.user.name || "Unknown"}</p>
                                <p className="text-xs text-muted-foreground truncate max-w-[200px]" title={record.lastMessage || "No messages"}>{record.lastMessage || "No messages"}</p>
                            </div>
                        </div>
                    );
                }

                if (record.kitchen) {
                    return (
                        <div className="flex items-center gap-3">
                            <Avatar className="h-9 w-9 border border-border">
                                <AvatarImage src={record.kitchen.kitchenProfilePhoto || undefined} />
                                <AvatarFallback>{record.kitchen.kitchenName?.substring(0, 2).toUpperCase() || "?"}</AvatarFallback>
                            </Avatar>
                            <div>
                                <p className="font-medium text-sm text-foreground truncate max-w-[150px]" title={record.kitchen.kitchenName || "Unknown Kitchen"}>{record.kitchen.kitchenName || "Unknown Kitchen"}</p>
                                <p className="text-xs text-muted-foreground truncate max-w-[200px]" title={record.lastMessage || "No messages"}>{record.lastMessage || "No messages"}</p>
                            </div>
                        </div>
                    );
                }
                return <div className="text-muted-foreground">Unknown Entity</div>;
            },
            width: "30%",
        },
        {
            key: "status",
            label: "Status",
            render: (_, record) => (
                <Badge
                    variant="outline"
                    className={cn(
                        "capitalize",
                        record.status === "OPEN" && "bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-900/20 dark:text-blue-300 dark:border-blue-800",
                        record.status === "PENDING" && "bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-300 dark:border-yellow-800",
                        record.status === "CLOSED" && "bg-green-50 text-green-700 border-green-200 dark:bg-green-900/20 dark:text-green-300 dark:border-green-800",
                    )}
                >
                    {record.status?.toLowerCase() || "unknown"}
                </Badge>
            ),
            width: "15%",
        },
        {
            key: "times",
            label: "Last Activity",
            render: (_, record) => {
                try {
                    return (
                        <div className="text-sm text-muted-foreground">
                            {record.lastMessageAt ? format(new Date(record.lastMessageAt), "MMM dd, yyyy hh:mm a") : "N/A"}
                        </div>
                    );
                } catch (error) {
                    return <div className="text-sm text-muted-foreground">Invalid date</div>;
                }
            }
        },
        {
            key: "actions",
            label: "Actions",
            align: "right",
            render: (_, record) => (
                <Button
                    onClick={() => onChatSelect(record)}
                    size="sm"
                    className={cn(
                        "gap-2 transition-all",
                        record.unreadCount > 0 ? "bg-primary text-primary-foreground shadow-sm hover:bg-primary/90" : "bg-secondary text-secondary-foreground hover:bg-secondary/80"
                    )}
                >
                    <MessageSquare className="h-4 w-4" />
                    {record.unreadCount > 0 ? `Reply (${record.unreadCount})` : "View Chat"}
                </Button>
            ),
        },
    ];

    const renderPagination = () => {
        if (loading || filteredChats.length === 0) return null;

        return (
            <div className="p-4 border-t border-border/50">
                <Pagination
                    Pagination={{
                        page: currentPage,
                        totalCount: filteredChats.length,
                        totalPages: totalPages,
                        size: ITEMS_PER_PAGE,
                    }}
                    onPageChange={setCurrentPage}
                />
            </div>
        );
    };

    const loading = isLoading;

    return (
        <Card className="border-border/50 shadow-sm">
            <CardHeader className="pb-4 border-b border-border/40 bg-muted/20">
                <div className="flex flex-col gap-4">
                    <div className="flex justify-between items-center">
                        <div className="space-y-1">
                            <CardTitle className="text-lg">Support Requests</CardTitle>
                            <CardDescription>Manage user and kitchen support conversations</CardDescription>
                        </div>
                        <div className="relative w-full max-w-sm">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder="Search requests..."
                                className="pl-8 bg-background"
                                value={searchTerm}
                                onChange={(e) => onSearchChange(e.target.value)}
                            />
                        </div>
                    </div>

                    <Tabs value={activeTab} onValueChange={(value) => onTabChange(value as "users" | "kitchens")} className="w-full">
                        <TabsList className="grid w-full max-w-[400px] grid-cols-2 h-10">
                            <TabsTrigger value="users" className="gap-2 data-[state=active]:bg-background">
                                <MessageSquare className="h-4 w-4" />
                                <span>Users</span>
                                {userChats.filter((c) => c.status === "OPEN").length > 0 && (
                                    <Badge variant="secondary" className="ml-1 h-5 min-w-5 px-1.5 text-xs font-semibold">
                                        {userChats.filter((c) => c.status === "OPEN").length}
                                    </Badge>
                                )}
                            </TabsTrigger>
                            <TabsTrigger value="kitchens" className="gap-2 data-[state=active]:bg-background">
                                <MessageSquare className="h-4 w-4" />
                                <span>Kitchens</span>
                                {kitchenChats.filter((c) => c.status === "OPEN").length > 0 && (
                                    <Badge variant="secondary" className="ml-1 h-5 min-w-5 px-1.5 text-xs font-semibold">
                                        {kitchenChats.filter((c) => c.status === "OPEN").length}
                                    </Badge>
                                )}
                            </TabsTrigger>
                        </TabsList>
                    </Tabs>
                </div>
            </CardHeader>

            <CardContent className="p-0">
                <Tabs value={activeTab} className="w-full">
                    <TabsContent value="users" className="m-0">
                        {loading ? (
                            <div className="flex items-center justify-center py-12">
                                <div className="flex flex-col items-center gap-2">
                                    <div className="w-8 h-8 border-4 border-primary/30 border-t-primary rounded-full animate-spin" />
                                    <p className="text-sm text-muted-foreground">Loading support chats...</p>
                                </div>
                            </div>
                        ) : (
                            <>
                                <DynamicTable
                                    columns={columns}
                                    data={paginatedChats}
                                    emptyMessage="No user support requests found."
                                    rowKey="roomId"
                                    className="border-0 rounded-none"
                                    onRowClick={(record) => onChatSelect(record)}
                                />
                                {renderPagination()}
                            </>
                        )}
                    </TabsContent>

                    <TabsContent value="kitchens" className="m-0">
                        {loading ? (
                            <div className="flex items-center justify-center py-12">
                                <div className="flex flex-col items-center gap-2">
                                    <div className="w-8 h-8 border-4 border-primary/30 border-t-primary rounded-full animate-spin" />
                                    <p className="text-sm text-muted-foreground">Loading support chats...</p>
                                </div>
                            </div>
                        ) : (
                            <>
                                <DynamicTable
                                    columns={columns}
                                    data={paginatedChats}
                                    emptyMessage="No kitchen support requests found."
                                    rowKey="roomId"
                                    className="border-0 rounded-none"
                                    onRowClick={(record) => onChatSelect(record)}
                                />
                                {renderPagination()}
                            </>
                        )}
                    </TabsContent>
                </Tabs>
            </CardContent>
        </Card>
    );
};
