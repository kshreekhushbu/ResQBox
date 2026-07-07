import { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate, useSearchParams } from "react-router-dom";
import { AppDispatch, RootState } from "@/store/store";
import { fetchOrders, clearError } from "../ordersSlice";
import { Order, OrderStatus } from "../types";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import Pagination from "@/components/Pagination/Pagination";
import { DynamicTable, TableColumn } from "@/components/table/DynamicTable";
import { format } from "date-fns";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { usePermissions } from "@/hooks/usePermissions";
import { useToast } from "@/hooks/use-toast";
import { Search, X } from "lucide-react";

export default function Orders() {
    const dispatch = useDispatch<AppDispatch>();
    const navigate = useNavigate();
    const { toast } = useToast();
    const [searchParams, setSearchParams] = useSearchParams();
    const permissions = usePermissions("orders");
    const { orders, pagination, loading, error } = useSelector(
        (state: RootState) => state.orders
    );

    const pageParam = searchParams.get("page");
    const page = pageParam ? parseInt(pageParam, 10) : 1;
    const limit = 10;

    const statusParam = searchParams.get("status");
    const status = (statusParam === "ALL" || !statusParam) ? null : statusParam as OrderStatus;

    const searchParam = searchParams.get("search");
    const search = searchParam || null;

    const [searchInput, setSearchInput] = useState(search || "");

    useEffect(() => {
        if (!permissions.hasRead) {
            navigate("/403", { replace: true });
        }
    }, [permissions.hasRead, navigate]);

    useEffect(() => {
        setSearchInput(search || "");
    }, [search]);

    useEffect(() => {
        dispatch(fetchOrders({
            page,
            limit,
            status,
            search
        }));
    }, [dispatch, page, limit, status, search]);

    useEffect(() => {
        if (error) {
            toast({
                title: "Error",
                description: error,
                variant: "destructive",
            });
            dispatch(clearError());
        }
    }, [error, toast, dispatch]);

    // Refactored to avoid useCallback/useMemo as per user request
    const updateSearchParams = (searchTerm: string) => {
        const newParams = new URLSearchParams(searchParams);
        newParams.set("page", "1"); // Reset to page 1

        if (searchTerm) {
            newParams.set("search", searchTerm);
        } else {
            newParams.delete("search");
        }
        setSearchParams(newParams);
    };

    useEffect(() => {
        const timer = setTimeout(() => {
            const trimmedValue = searchInput.trim();
            const currentSearchParam = searchParams.get("search") || "";

            if ((trimmedValue === "" || trimmedValue.length >= 3) && trimmedValue !== currentSearchParam) {
                updateSearchParams(trimmedValue);
            }
        }, 500);

        return () => clearTimeout(timer);
    }, [searchInput, searchParams, setSearchParams]);

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setSearchInput(e.target.value);
    };

    const handleClearSearch = () => {
        setSearchInput("");
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case "PENDING":
                return "bg-yellow-100 text-yellow-800";
            case "PAYMENT_PENDING":
                return "bg-amber-100 text-amber-700";
            case "ACCEPTED":
                return "bg-blue-100 text-blue-800";
            case "PREPARING":
                return "bg-purple-100 text-purple-800";
            case "READY":
                return "bg-indigo-100 text-indigo-800";
            case "PICKED":
                return "bg-green-100 text-green-800";
            case "NO_SHOW":
            case "CANCELLED":
            case "REJECTED":
                return "bg-red-100 text-red-800";
            default:
                return "bg-gray-100 text-gray-800";
        }
    };

    const columns: TableColumn<Order>[] = [
        {
            key: "orderId",
            label: "Order ID",
            width: "100px",
            render: (_, record) => (
                <span className="font-mono text-sm font-medium">#{record.orderNumber}</span>
            ),
        },
        {
            key: "customer",
            label: "Customer",
            render: (_, record) => (
                <div className="flex flex-col max-w-[150px]">
                    <span className="font-medium truncate" title={record.user.name}>{record.user.name}</span>
                    <span className="text-xs text-muted-foreground truncate" title={record.user.phoneNumber}>{record.user.phoneNumber}</span>
                </div>
            ),
        },
        {
            key: "kitchen",
            label: "Kitchen",
            render: (_, record) => (
                <div className="flex flex-col max-w-[150px]">
                    <span className="font-medium truncate" title={record.kitchen.kitchenName}>{record.kitchen.kitchenName}</span>
                    <span className="text-xs text-muted-foreground">ID: {record.kitchen.kitchenId}</span>
                </div>
            ),
        },
        {
            key: "amount",
            label: "Amount",
            render: (_, record) => (
                <div className="font-medium flex gap-0">
                    ${record.totalAmount.toFixed(2)}
                </div>
            ),
        },
        {
            key: "status",
            label: "Status",
            render: (_, record) => (
                <Badge className={`px-2 py-1 rounded-full font-medium border-none shadow-none pointer-events-none whitespace-nowrap ${getStatusColor(record.status)}`}>
                    {record.status.replace(/_/g, " ")}
                </Badge>
            ),
        },
        {
            key: "date",
            label: "Ordered At",
            render: (_, record) => (
                <span className="text-sm text-muted-foreground">
                    {format(new Date(record.orderedAt), "MMM dd, yyyy HH:mm")}
                </span>
            ),
        },
        {
            key: "type",
            label: "Type",
            render: (_, record) => (
                <Badge variant="outline" className="text-xs">
                    {record.deliveryType}
                </Badge>
            ),
        },
    ];

    const handleRowClick = (record: Order) => {
        navigate(`/orders/${record.orderUid}`);
    };

    return (
        <>
            <div className="flex flex-col md:flex-row gap-4 justify-between items-center bg-card p-4 rounded-lg border shadow-sm">
                <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4 w-full md:w-auto">

                    <div className="relative w-full sm:w-auto">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <Input
                            placeholder="Search by Order ID or Customer (min 3 chars)..."
                            value={searchInput}
                            onChange={handleInputChange}
                            className="pl-9 pr-9 w-full sm:w-[280px]"
                        />
                        {searchInput && (
                            <button
                                type="button"
                                onClick={handleClearSearch}
                                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                            >
                                <X className="h-4 w-4" />
                            </button>
                        )}
                    </div>


                    <div className="flex items-center gap-2">
                        <span className="text-sm font-medium text-muted-foreground">Status:</span>
                        <Select
                            value={status || "ALL"}
                            onValueChange={(val) => {
                                const newParams = new URLSearchParams(searchParams);
                                if (val === "ALL") {
                                    newParams.delete("status");
                                } else {
                                    newParams.set("status", val);
                                }
                                newParams.set("page", "1");
                                setSearchParams(newParams);
                            }}
                        >
                            <SelectTrigger className="w-[150px]">
                                <SelectValue placeholder="All Orders" />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem value="ALL">All Orders</SelectItem>
                                {Object.values(OrderStatus).map((status) => (
                                    <SelectItem key={status} value={status}>
                                        {status}
                                    </SelectItem>
                                ))}
                            </SelectContent>
                        </Select>
                    </div>
                </div>
                {(status || search) && (
                    <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                            const newParams = new URLSearchParams(searchParams);
                            newParams.delete("status");
                            newParams.delete("search");
                            newParams.set("page", "1");
                            setSearchParams(newParams);
                            setSearchInput("");
                        }}
                        className="text-muted-foreground hover:text-foreground"
                    >
                        Clear All Filters
                    </Button>
                )}
            </div>

            <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
                <CardHeader>
                    <CardTitle>Orders List</CardTitle>
                    <CardDescription>
                        Manage and track all customer orders
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    <DynamicTable
                        columns={columns}
                        data={orders}
                        loading={loading}
                        emptyMessage="No orders found."
                        skeletonRows={8}
                        rowKey="orderId"
                        onRowClick={handleRowClick}
                    />

                    {pagination && (
                        <div className="mt-4">
                            <Pagination
                                Pagination={{
                                    page: pagination.currentPage,
                                    totalCount: pagination.totalOrders,
                                    totalPages: pagination.totalPages,
                                    size: limit,
                                }}
                                onPageChange={(newPage) => {
                                    const newParams = new URLSearchParams(searchParams);
                                    newParams.set("page", newPage.toString());
                                    setSearchParams(newParams);
                                }}
                            />
                        </div>
                    )}
                </CardContent>
            </Card>
        </>
    );
}