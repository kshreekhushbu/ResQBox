import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "@/store/store";
import { getKitchenOrders, clearKitchenOrders } from "../payoutsSlice";
import { Order } from "../types";
import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Clock, ShoppingBag, DollarSign, Calendar } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { DynamicTable, TableColumn } from "@/components/table/DynamicTable";
import { Skeleton } from "@/components/ui/skeleton";
import {
    Breadcrumb,
    BreadcrumbItem,
    BreadcrumbLink,
    BreadcrumbList,
    BreadcrumbPage,
    BreadcrumbSeparator,
} from "@/components/ui/breadcrumb";
import Pagination from "@/components/Pagination/Pagination";

export default function PayoutDetails() {
    const { kitchenId } = useParams<{ kitchenId: string }>();
    const navigate = useNavigate();
    const dispatch = useDispatch<AppDispatch>();
    const { kitchenOrders, pagination, loading, error } = useSelector(
        (state: RootState) => state.payouts
    );
    const [currentPage, setCurrentPage] = useState(1);
    const ITEMS_PER_PAGE = 10;

    useEffect(() => {
        if (kitchenId) {
            dispatch(getKitchenOrders({ kitchenId, page: currentPage, limit: ITEMS_PER_PAGE }));
        }
        return () => {

        };
    }, [kitchenId, currentPage, dispatch]);
    useEffect(() => {
        return () => {
            dispatch(clearKitchenOrders());
        };
    }, [dispatch]);


    const columns: TableColumn<Order>[] = [
        {
            key: "orderDisplayId",
            label: "Order ID",
            className: "font-mono font-medium",
        },
        {
            key: "orderedAt",
            label: "Date",
            render: (_, record) => (
                <div className="flex items-center gap-2 text-muted-foreground">
                    <Calendar className="h-3 w-3" />
                    <span>{new Date(record.orderedAt).toLocaleDateString()}</span>
                </div>
            )
        },
        {
            key: "numberOfItems",
            label: "Items",
            className: "text-center",
            render: (_, record) => (
                <Badge variant="secondary" className="font-normal text-xs">
                    {record.numberOfItems} items
                </Badge>
            )
        },
        {
            key: "status",
            label: "Status",
            className: "text-center",
            render: (_, record) => {
                let variant: "default" | "secondary" | "destructive" | "outline" = "outline";
                let className = "";

                switch (record.status.toLowerCase()) {
                    case 'delivered':
                    case 'completed':
                    case 'picked':
                    case 'accepted':
                        variant = "default";
                        className = "bg-emerald-500/15 text-emerald-700 hover:bg-emerald-500/25 border-emerald-500/20";
                        break;
                    case 'cancelled':
                        variant = "destructive";
                        break;
                    case 'preparing':
                    case 'cooking':
                        variant = "secondary";
                        className = "bg-amber-500/15 text-amber-700 hover:bg-amber-500/25 border-amber-500/20";
                        break;
                    default:
                        className = "bg-blue-500/15 text-blue-700 hover:bg-blue-500/25 border-blue-500/20";
                }

                return (
                    <Badge variant={variant} className={`capitalize ${className}`}>
                        {record.status.toLowerCase()}
                    </Badge>
                );
            },
        },
        {
            key: "totalAmount",
            label: "Amount",
            className: "text-right font-medium",
            render: (_, record) => `$${record.totalAmount.toFixed(2)}`,
        },
    ];

    if (error) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[50vh] space-y-4">
                <p className="text-destructive font-medium">Error: {error}</p>
                <Button onClick={() => navigate("/payouts")}>Back to Payouts</Button>
            </div>
        );
    }

    const LoadingSkeleton = () => (
        <div className="space-y-6 animate-pulse">
            <div className="flex items-center gap-4">
                <Skeleton className="h-10 w-10 rounded-md" />
                <div className="space-y-2">
                    <Skeleton className="h-8 w-64" />
                    <Skeleton className="h-4 w-48" />
                </div>
            </div>
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                <Skeleton className="h-32 rounded-xl" />
                <Skeleton className="h-32 rounded-xl" />
                <Skeleton className="h-32 rounded-xl" />
            </div>
            <Skeleton className="h-[400px] rounded-xl" />
        </div>
    )

    if (loading && !kitchenOrders.length) {
        return <LoadingSkeleton />
    }

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500 pb-10">
            <div className="flex flex-col gap-4">
                <Breadcrumb>
                    <BreadcrumbList>
                        <BreadcrumbItem>
                            <BreadcrumbLink onClick={() => navigate("/payouts")} className="cursor-pointer">
                                Payouts
                            </BreadcrumbLink>
                        </BreadcrumbItem>
                        <BreadcrumbSeparator />
                        <BreadcrumbItem>
                            <BreadcrumbPage className="text-primary font-semibold">Kitchen Orders #{kitchenId}</BreadcrumbPage>
                        </BreadcrumbItem>
                    </BreadcrumbList>
                </Breadcrumb>
            </div>

            <Card className="border-border/60 shadow-md bg-card/50 backdrop-blur-sm overflow-hidden">
                <CardHeader className="px-6 py-4 border-b border-border/50">
                    <CardTitle className="text-lg">Order History</CardTitle>
                    <CardDescription>
                        Detailed list of orders included in this payout period.
                    </CardDescription>
                </CardHeader>
                <CardContent className="p-0">
                    <DynamicTable
                        columns={columns}
                        data={kitchenOrders}
                        loading={loading}
                        emptyMessage="No orders found for this kitchen."
                        onRowClick={() => { }}
                    />
                    {pagination && (
                        <div className="p-4 border-t border-border/50">
                            <Pagination
                                Pagination={{
                                    page: pagination.currentPage,
                                    totalCount: pagination.totalOrders,
                                    totalPages: pagination.totalPages,
                                    size: ITEMS_PER_PAGE
                                }}
                                onPageChange={setCurrentPage}
                            />
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    );
}
