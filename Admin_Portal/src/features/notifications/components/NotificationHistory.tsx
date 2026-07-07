import { useState, useEffect } from "react";
import Pagination from "@/components/Pagination/Pagination";
import { Bell, Filter, Calendar } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { DynamicTable, TableColumn } from "@/components/table/DynamicTable";
import { AppDispatch, RootState } from "@/store/store";
import { useDispatch, useSelector } from "react-redux";
import { fetchAllNotifications } from "../notificationsSlice";
import { Notification } from "../types";
import moment from "moment";

const NotificationHistory: React.FC = () => {
    const dispatch = useDispatch<AppDispatch>();
    const { notifications, loading, error, pagination } = useSelector((state: RootState) => state.notifications);
    const [page, setPage] = useState(1);
    const limit = 10;

    useEffect(() => {
        getNotifications();
    }, [page]);

    const getNotifications = async () => {
        try {
            await dispatch(fetchAllNotifications({ page, limit })).unwrap();
        } catch (err: any) {
            console.log(err);
        }
    }

    const handlePageChange = (newPage: number) => {
        setPage(newPage);
    };

    const columns: TableColumn<Notification>[] = [
        {
            key: "title",
            label: "Notification",
            render: (_, record) => (
                <div>
                    <div className="font-medium text-foreground">{record.title}</div>
                    <div className="text-sm text-muted-foreground line-clamp-1 max-w-[200px]">{record.message}</div>
                </div>
            )
        },
        {
            key: "ownerType",
            label: "Audience",
            render: (value) => (
                <Badge variant="outline" className="font-normal text-muted-foreground">
                    {value}
                </Badge>
            )
        },
        {
            key: "createdAt",
            label: "Sent Date",
            render: (val, record) => <span className="text-sm text-muted-foreground">{moment(record.createdAt).format("MMM DD, YYYY hh:mm A")}</span>
        },
    ];

    return (
        <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
            <CardHeader>
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <CardTitle>Sent History</CardTitle>
                        <CardDescription>View all notifications sent to users.</CardDescription>
                    </div>
                </div>
            </CardHeader>
            <CardContent>

                <DynamicTable
                    columns={columns}
                    data={notifications}
                    loading={loading}
                    emptyMessage={
                        <div className="flex flex-col items-center justify-center p-8 text-center">
                            <Bell className="w-12 h-12 text-muted-foreground mb-4 opacity-50" />
                            <h3 className="text-lg font-medium">No notifications sent yet</h3>
                            <p className="text-muted-foreground max-w-sm mt-2">Your notification history will appear here once you start sending messages.</p>
                        </div>
                    }
                />
                {pagination && (
                    <div className="mt-4">
                        <Pagination
                            Pagination={{
                                page: pagination.page,
                                totalCount: pagination.total,
                                totalPages: pagination.totalPages,
                                size: pagination.limit
                            }}
                            onPageChange={handlePageChange}
                        />
                    </div>
                )}
            </CardContent>
        </Card>
    );
}
export default NotificationHistory;
