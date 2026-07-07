import { useState, useEffect } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "@/store/store";
import { fetchAllInvoices, fetchMonthlyInvoices, clearError } from "../invoicesSlice";
import { Invoice } from "../types";

import { DynamicTable, TableColumn } from "@/components/table/DynamicTable";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Search, Download } from "lucide-react";
import moment from "moment";
import { usePermissions } from "@/hooks/usePermissions";
import { ErrorDisplay } from "@/components/ErrorDisplay/ErrorDisplay";

const Invoices: React.FC = () => {
    const navigate = useNavigate();
    const [searchParams, setSearchParams] = useSearchParams();
    const dispatch = useDispatch<AppDispatch>();
    const permissions = usePermissions("invoices");
    const { invoices, loading, error } = useSelector((state: RootState) => state.invoices);

    const [searchQuery, setSearchQuery] = useState("");

    const periodParam = searchParams.get("period") as "weekly" | "monthly";
    const [period, setPeriod] = useState<"weekly" | "monthly">(
        (periodParam === "weekly" || periodParam === "monthly") ? periodParam : "weekly"
    );

    useEffect(() => {
        setSearchParams({ period }, { replace: true });
    }, [period, setSearchParams]);

    useEffect(() => {
        if (periodParam && (periodParam === "weekly" || periodParam === "monthly") && periodParam !== period) {
            setPeriod(periodParam);
        }
    }, [periodParam]);
    useEffect(() => {
        if (periodParam && (periodParam === "weekly" || periodParam === "monthly") && periodParam !== period) {
            setPeriod(periodParam);
        }
    }, [periodParam]);

    useEffect(() => {
        if (!permissions.hasRead) {
            navigate("/403", { replace: true });
        }
    }, [permissions.hasRead, navigate]);

    useEffect(() => {
        if (period === "weekly") {
            dispatch(fetchAllInvoices());
        } else {
            dispatch(fetchMonthlyInvoices());
        }
        return () => {
            dispatch(clearError());
        };
    }, [dispatch, period]);

    const filteredInvoices = invoices.filter((inv) => {
        const matchesSearch =
            inv.invoiceNumber?.toLowerCase().includes(searchQuery.toLowerCase()) ||
            inv.restaurantName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
            String(inv.kitchenId).includes(searchQuery) ||
            String(inv.restaurantCode).includes(searchQuery);

        return matchesSearch;
    });

    const columns: TableColumn<Invoice>[] = [
        {
            key: "invoiceNumber",
            label: "Invoice ID",
            className: "font-medium font-mono",
        },
        {
            key: "restaurantName",
            label: "Restaurant Name",
            className: "max-w-[180px]",
            render: (_, record) => (
                <div className="truncate font-medium text-foreground" title={record.restaurantName}>
                    {record.restaurantName}
                </div>
            ),
        },
        {
            key: "restaurantCode",
            label: "Kitchen ID",
            render: (_, record) => `${record.restaurantCode || "N/A"}`,
        },
        {
            key: "period",
            label: "Period",
            render: (_, record) => {
                if (record.month && record.year) {
                    return `${moment().month(record.month - 1).format("MMMM")} ${record.year}`;
                }
                return `${moment(record.periodStart).format("MMM DD")} - ${moment(record.periodEnd).format("MMM DD, YYYY")}`;
            }
        },
        {
            key: "createdAt",
            label: "Generated Date",
            render: (_, record) => moment(record.date || record.createdAt).format("MMM DD, YYYY"),
        },
        {
            key: "invoicedAmount",
            label: "Amount",
            render: (_, record) => {
                const amount = record.invoicedAmount ?? record.netAmount ?? 0;
                return `$${Number(amount).toFixed(2)}`;
            },
        },
        {
            key: "invoiceId",
            label: "Download",
            align: "right",
            render: (_, record) => {
                const pdfLink = record.invoice || record.pdfUrl;
                return (
                    <Button
                        variant="ghost"
                        size="sm"
                        className="h-8 w-8 p-0"
                        onClick={() => {
                            if (pdfLink) window.open(pdfLink, '_blank');
                        }}
                        disabled={!pdfLink}
                    >
                        <Download className="h-4 w-4 text-primary" />
                    </Button>
                );
            },
        },
    ];

    if (error) {
        return <ErrorDisplay message={error} getdata={() => period === "weekly" ? dispatch(fetchAllInvoices()) : dispatch(fetchMonthlyInvoices())} />;
    }

    return (
        <div className="space-y-6">
            <div className="flex flex-col xl:flex-row gap-4 justify-between items-start xl:items-center bg-card p-4 rounded-lg border shadow-sm">
                <div className="flex flex-1 flex-col sm:flex-row gap-4 w-full items-center">
                    <Tabs
                        value={period}
                        onValueChange={(val: any) => setPeriod(val)}
                        className="w-full sm:w-auto"
                    >
                        <TabsList className="grid w-full grid-cols-2 sm:w-[300px]">
                            <TabsTrigger value="weekly">Weekly</TabsTrigger>
                            <TabsTrigger value="monthly">Monthly</TabsTrigger>
                        </TabsList>
                    </Tabs>

                    <div className="relative flex-1 min-w-[280px] w-full">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <Input
                            placeholder="Search by ID, Name, Code..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="pl-9 bg-background"
                        />
                    </div>
                </div>
            </div>

            <div className="bg-card rounded-lg border shadow-sm overflow-hidden">
                <DynamicTable
                    columns={columns}
                    data={filteredInvoices}
                    loading={loading}
                    emptyMessage={`No ${period} invoices found matching your criteria.`}
                    className="border-0 shadow-none"
                    onRowClick={() => { }}
                />
            </div>
        </div>
    );
}

export default Invoices;
