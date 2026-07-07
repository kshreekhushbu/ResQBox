import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "@/store/store";
import { getAllPayouts, processPayout } from "../payoutsSlice";
import { Payout } from "../types";
import { useDebounce } from "@/hooks/use-debounce";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from "@/components/ui/card";
import {
    Search,
    Eye,
    X,
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { Badge } from "@/components/ui/badge";
import { usePermissions } from "@/hooks/usePermissions";
import { DynamicTable, TableColumn } from "@/components/table/DynamicTable";
import Pagination from "@/components/Pagination/Pagination";
import { ErrorDisplay } from "@/components/ErrorDisplay/ErrorDisplay";
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from "@/components/ui/alert-dialog";

export default function Payouts() {
    const navigate = useNavigate();
    const permissions = usePermissions("payouts");
    const dispatch = useDispatch<AppDispatch>();

    const { payouts, loading, error, payoutsPagination } = useSelector(
        (state: RootState) => state.payouts
    );

    const [searchQuery, setSearchQuery] = useState("");
    const debouncedSearchQuery = useDebounce(searchQuery, 500);
    const { toast } = useToast();
    const [currentPage, setCurrentPage] = useState(1);
    const [statusFilter, setStatusFilter] = useState("all");
    const [selectedPayout, setSelectedPayout] = useState<Payout | null>(null);
    const ITEMS_PER_PAGE = 10;

    useEffect(() => {
        if (!permissions.hasRead) {
            navigate("/403", { replace: true });
        }
    }, [permissions.hasRead, navigate]);

    useEffect(() => {
        if (debouncedSearchQuery.length === 0 || debouncedSearchQuery.length >= 3) {
            dispatch(getAllPayouts({
                page: currentPage,
                limit: ITEMS_PER_PAGE,
                search: debouncedSearchQuery,
                status: statusFilter === "all" ? "" : statusFilter
            }));
        }
    }, [dispatch, currentPage, debouncedSearchQuery, statusFilter]);

    useEffect(() => {
        setCurrentPage(1);
    }, [debouncedSearchQuery, statusFilter]);


    const executePayout = async () => {
        if (!selectedPayout || !permissions.checkWrite()) return;

        try {
            const { kitchenId, periodStart, periodEnd, restaurantName } = selectedPayout;
            const from = periodStart || new Date().toISOString();
            const to = periodEnd || new Date().toISOString();

            const result = await dispatch(processPayout({ kitchenId, from, to })).unwrap();

            if (result.success) {
                toast({
                    title: "Payout Successful",
                    description: (
                        <div className="flex flex-col gap-1">
                            <span className="font-medium">
                                Successfully paid ${result.amountPaid.toFixed(2)} to {restaurantName}
                            </span>
                            <span className="text-xs opacity-90">
                                Invoice #{result.invoice.invoiceNumber} generated.
                            </span>
                        </div>
                    ),
                    className: "bg-green-600 text-white border-none",
                    duration: 5000,
                });
            } else {
                toast({
                    title: "Payout Failed",
                    description: result.message || "Failed to process payout.",
                    variant: "destructive",
                });
            }
        } catch (error: any) {
            const errorMessage = error?.message || (typeof error === 'string' ? error : "Payout processing failed");

            toast({
                title: "Payout Failed",
                description: errorMessage,
                variant: "destructive",
            });
        } finally {
            setSelectedPayout(null);
        }
    };

    const columns: TableColumn<Payout>[] = [
        {
            key: "restaurantCode",
            label: "Restaurant ID",
            width: "80px",
            render: (_, record) => (
                <span className="font-mono text-xs text-muted-foreground">
                    #{record.restaurantCode}
                </span>
            ),
        },
        {
            key: "restaurantName",
            label: "Restaurant",
            className: "min-w-[200px]",
            render: (_, record) => {
                const addressString = record.address
                    ? `${record.address.houseNo}, ${record.address.street}, ${record.address.city}`
                    : "N/A";
                return (
                    <div className="flex flex-col max-w-[200px]">
                        <span className="font-semibold text-foreground truncate" title={record.restaurantName}>
                            {record.restaurantName}
                        </span>
                        <span className="text-xs text-muted-foreground truncate" title={addressString}>
                            {addressString}
                        </span>
                    </div>
                );
            },
        },
        {
            key: "status",
            label: "Status",
            className: "text-center",
            render: (_, record) => {
                if (record.orders === 0) {
                    return (
                        <Badge
                            variant="outline"
                            className="justify-center min-w-[130px] h-6 text-[10px] font-bold uppercase tracking-wider rounded-md transition-all duration-300 bg-secondary/50 text-muted-foreground border-muted-foreground/20 whitespace-nowrap"
                        >
                            No Payouts Required
                        </Badge>
                    );
                }
                return (
                    <Badge
                        variant="outline"
                        className={`justify-center min-w-[85px] h-6 text-[10px] font-bold uppercase tracking-wider rounded-md transition-all duration-300 ${record.status === "Paid"
                            ? "bg-emerald-500/5 text-emerald-600 border-emerald-500/20 group-hover:bg-emerald-500/10"
                            : record.status === "Pending"
                                ? "bg-amber-500/5 text-amber-600 border-amber-500/20 group-hover:bg-amber-500/10"
                                : "bg-blue-500/5 text-blue-600 border-blue-500/20 group-hover:bg-blue-500/10"
                            }`}
                    >
                        {record.status}
                    </Badge>
                );
            },
        },
        {
            key: "orders",
            label: "Orders",
            className: "text-center",
            render: (_, record) => (
                <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-secondary/50 text-xs font-medium border border-border/50">
                    {record.orders}
                </div>
            ),
        },
        {
            key: "amount",
            label: "Amount",
            className: "text-right",
            render: (_, record) => (
                <span className="font-bold text-foreground">
                    ${record.amount.toFixed(2)}
                </span>
            ),
        },

        {
            key: "restaurantCode",
            label: "Details",
            width: "50px",
            render: (_, record) => (
                <Button
                    variant="ghost"
                    size="icon"
                    className="h-8 w-8 hover:bg-primary/10 hover:text-primary transition-colors rounded-full"
                    onClick={(e) => {
                        e.stopPropagation();
                        navigate(`/payouts/${record.kitchenId}`);
                    }}
                >
                    <Eye className="h-4 w-4" />
                </Button>
            ),
        },
    ];

    if (error) {
        return <ErrorDisplay message={error} getdata={() => dispatch(getAllPayouts({ page: 1, limit: ITEMS_PER_PAGE }))} />;
    }

    return (
        <div className="space-y-8 animate-in fade-in duration-500">
            <Card className="border-border/60 shadow-md overflow-hidden bg-card/50 backdrop-blur-sm">
                <CardHeader className="px-8 py-6 border-b border-border/40 bg-card/30">
                    <div className="flex flex-col xl:flex-row xl:items-center justify-between gap-6">
                        <div className="space-y-1">
                            <CardTitle className="text-2xl font-bold tracking-tight">This Week's Payouts</CardTitle>
                            <CardDescription className="text-muted-foreground/80">
                                Monitor and manage revenue distributions across all restaurant partners.
                            </CardDescription>
                        </div>
                        <div className="flex flex-col sm:flex-row gap-4 w-full xl:w-auto">
                            <div className="relative w-full sm:w-72 md:w-80 group">
                                <Search className="absolute left-3.5 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4 transition-colors group-focus-within:text-primary" />
                                <Input
                                    placeholder="Search restaurant name or ID..."
                                    value={searchQuery}
                                    onChange={(e) => setSearchQuery(e.target.value)}
                                    className="pl-10 pr-10 h-11 bg-background/50 border-border/40 focus:bg-background focus:ring-2 focus:ring-primary/20 transition-all rounded-xl"
                                    disabled={loading}
                                />
                                {searchQuery && (
                                    <button
                                        onClick={() => setSearchQuery("")}
                                        className="absolute right-3.5 top-1/2 transform -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
                                    >
                                        <X className="h-4 w-4" />
                                    </button>
                                )}
                            </div>
                            <div className="w-full sm:w-40">
                                <Select
                                    value={statusFilter}
                                    onValueChange={(value) => setStatusFilter(value)}
                                    disabled={loading}
                                >
                                    <SelectTrigger className="h-11 bg-background/50 border-border/40 focus:ring-2 focus:ring-primary/20 transition-all rounded-xl">
                                        <SelectValue placeholder="Status" />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="all">All Status</SelectItem>
                                        <SelectItem value="Pending">Pending</SelectItem>
                                        <SelectItem value="Paid">No Payouts</SelectItem>
                                    </SelectContent>
                                </Select>
                            </div>
                        </div>
                    </div>
                </CardHeader>
                <CardContent className="p-0">
                    <DynamicTable
                        columns={columns}
                        data={payouts}
                        loading={loading}
                        emptyMessage={
                            loading ? "Loading..." : "No payouts found matching your criteria."
                        }
                        onRowClick={(record) => navigate(`/payouts/${record.kitchenId}`)}
                    />
                    {!loading && payoutsPagination && (
                        <div className="p-4 border-t border-border/50">
                            <Pagination
                                Pagination={{
                                    page: payoutsPagination.currentPage,
                                    totalCount: payoutsPagination.totalKitchens,
                                    totalPages: payoutsPagination.totalPages,
                                    size: ITEMS_PER_PAGE,
                                }}
                                onPageChange={setCurrentPage}
                            />
                        </div>
                    )}
                </CardContent>
            </Card>

            <AlertDialog open={!!selectedPayout} onOpenChange={(open) => !open && setSelectedPayout(null)}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>Confirm Payout</AlertDialogTitle>
                        <AlertDialogDescription>
                            Are you sure you want to process a payout of <span className="font-bold text-foreground">${selectedPayout?.amount.toFixed(2)}</span> to <span className="font-bold text-foreground">{selectedPayout?.restaurantName}</span>?
                            This action cannot be undone.
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel>Cancel</AlertDialogCancel>
                        <AlertDialogAction onClick={executePayout} className="bg-primary hover:bg-primary/90">
                            Confirm Payout
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </div>
    );
}
