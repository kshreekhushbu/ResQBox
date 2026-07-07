import { useEffect, useMemo, useState, useCallback } from "react";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Search, LayoutGrid, CheckCircle, Clock, XCircle, AlertTriangle } from "lucide-react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
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
import { toast } from "sonner";
import Pagination from "@/components/Pagination/Pagination";
import { DynamicTable, TableColumn } from "@/components/table/DynamicTable";
import { KitchenSummary, AdminAlert, AdminAlertsPagination } from "../types";
import { AppDispatch, RootState } from "@/store/store";
import { fetchAllKitchens, changeKitchenStatus } from "../kitchensSlice";
import { useSearchParams, useLocation } from "react-router-dom";
import { usePermissions } from "@/hooks/usePermissions";
import { getAdminAlerts } from "../kitchenService";
import { AlertsDrawer } from "../components/AlertsDrawer";
import debounce from "lodash/debounce";

export default function Restaurants() {
  const dispatch = useDispatch<AppDispatch>();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const location = useLocation();
  const permissions = usePermissions("restaurants");
  const { kitchens, loading, pagination } = useSelector((s: RootState) => s.kitchens);

  const searchQuery = searchParams.get("search") || "";
  const [searchInput, setSearchInput] = useState(searchQuery);

  const ITEMS_PER_PAGE = 10;
  const pageParam = searchParams.get("page");
  const currentPage = pageParam ? parseInt(pageParam, 10) : 1;

  const statusParam = searchParams.get("status");
  const activeTab = useMemo(() => {
    if (!statusParam) return "all";
    const s = statusParam.toLowerCase();
    if (["approved", "pending", "rejected", "expiring"].includes(s)) return s;
    return "all";
  }, [statusParam]);

  const [alerts, setAlerts] = useState<AdminAlert[]>([]);
  const [alertsLoading, setAlertsLoading] = useState(false);
  const [unviewedCount, setUnviewedCount] = useState(0);
  const [alertsPagination, setAlertsPagination] = useState<AdminAlertsPagination | null>(null);
  const [moreAlertsLoading, setMoreAlertsLoading] = useState(false);

  const [confirmOpen, setConfirmOpen] = useState(false);
  const [pendingStatus, setPendingStatus] = useState<"APPROVED" | "REJECTED" | null>(null);
  const [pendingKitchenId, setPendingKitchenId] = useState<string | null>(null);

  useEffect(() => {
    if (!permissions.hasRead) {
      navigate("/403", { replace: true });
    }
  }, [permissions.hasRead, navigate]);

  const fetchAlerts = async () => {
    try {
      setAlertsLoading(true);
      const response = await getAdminAlerts(1, 20);
      setAlerts(response.data);
      setUnviewedCount(response.unviewedCount);
      setAlertsPagination(response.pagination);
    } catch (error: any) {
      toast.error(error?.message || "Failed to fetch alerts");
    } finally {
      setAlertsLoading(false);
    }
  };

  useEffect(() => {
    fetchAlerts();
  }, []);

  const handleLoadMoreAlerts = async () => {
    if (!alertsPagination || moreAlertsLoading || alertsPagination.page >= alertsPagination.totalPages) {
      return;
    }

    try {
      setMoreAlertsLoading(true);
      const nextPage = alertsPagination.page + 1;
      const response = await getAdminAlerts(nextPage, 20);
      setAlerts(prev => [...prev, ...response.data]);
      setAlertsPagination(response.pagination);
    } catch (error: any) {
      toast.error(error?.message || "Failed to load more alerts");
    } finally {
      setMoreAlertsLoading(false);
    }
  };

  const handleAlertViewed = (alertId: number) => {
    setAlerts(prevAlerts =>
      prevAlerts.map(a =>
        a.id === alertId
          ? { ...a, isViewed: true, viewedAt: new Date().toISOString() }
          : a
      )
    );
    setUnviewedCount(prev => Math.max(0, prev - 1));
  };

  const fetchKitchens = (statusStr: string, page: number, search?: string) => {
    let status: "APPROVED" | "PENDING" | "REJECTED" | "EXPIRING" | undefined = undefined;
    if (statusStr === "approved") status = "APPROVED";
    else if (statusStr === "pending") status = "PENDING";
    else if (statusStr === "rejected") status = "REJECTED";
    else if (statusStr === "expiring") status = "EXPIRING";

    dispatch(fetchAllKitchens({ status, page, limit: ITEMS_PER_PAGE, search }));
  };

  useEffect(() => {
    fetchKitchens(activeTab, currentPage, searchQuery);
  }, [currentPage, activeTab, searchQuery, dispatch]);

  // Debounced function to update URL params (minimum 3 characters)
  const updateSearchParams = useCallback(
    debounce((value: string) => {
      const newParams = new URLSearchParams(searchParams);
      const trimmedValue = value.trim();

      newParams.set("page", "1"); // Reset to page 1 on search

      if (trimmedValue.length >= 3) {
        newParams.set("search", trimmedValue);
      } else if (trimmedValue.length === 0) {
        newParams.delete("search");
      }
      setSearchParams(newParams);
    }, 500),
    [searchParams, setSearchParams]
  );

  // Handle search input change
  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setSearchInput(value);
    updateSearchParams(value);
  };

  useEffect(() => {
    setSearchInput(searchQuery);
  }, [searchQuery]);

  useEffect(() => {
    return () => {
      updateSearchParams.cancel();
    };
  }, [updateSearchParams]);



  const getStatusVariant = (
    status: string
  ): "default" | "destructive" | "secondary" | "outline" => {
    const normalizedStatus = status.toLowerCase();
    if (normalizedStatus === "approved") return "default";
    if (normalizedStatus === "pending") return "secondary";
    if (normalizedStatus === "rejected") return "destructive";
    if (normalizedStatus === "expiring") return "destructive";
    return "outline";
  };

  const requestStatusChange = (
    kitchenId: string,
    status: "APPROVED" | "REJECTED"
  ) => {
    if (!permissions.checkEdit()) {
      return;
    }
    setPendingKitchenId(kitchenId);
    setPendingStatus(status);
    setConfirmOpen(true);
  };

  const performStatusChange = async () => {
    if (!pendingKitchenId || !pendingStatus) return;
    try {
      const res = await dispatch(
        changeKitchenStatus({
          id: pendingKitchenId,
          payload: {
            status: pendingStatus,
            expireDate: new Date().toISOString().slice(0, 10),
          },
        })
      ).unwrap();
      toast.success(res?.message ?? "Status updated");
      fetchKitchens(activeTab, currentPage);
    } catch (e: any) {
      toast.error(e || "Failed to update status");
    } finally {
      setConfirmOpen(false);
      setPendingStatus(null);
      setPendingKitchenId(null);
    }
  };

  const confirmDescription =
    pendingStatus === "APPROVED"
      ? "This will approve the kitchen and notify the owner."
      : pendingStatus === "REJECTED"
        ? "This will reject the kitchen and notify the owner."
        : "Proceed with the update?";

  const columns: TableColumn<KitchenSummary>[] = [
    { key: "kitchenId", label: "ID", width: "80px" },
    {
      key: "kitchenName",
      label: "Kitchen Name",
      className: "font-medium",
      render: (_, record) => (
        <div className="max-w-[200px] truncate" title={record.kitchenName}>
          {record.kitchenName}
        </div>
      ),
    },
    { key: "contactNumber", label: "Phone Number" },
    {
      key: "city",
      label: "City",
      render: (_, record) => record.address?.city || "N/A"
    },
    {
      key: "createdAt",
      label: "Created At",
      render: (_, record) => new Date(record.createdAt).toLocaleDateString(),
    },
  ];

  if (activeTab === "all") {
    columns.push({
      key: "status",
      label: "Status",
      render: (_, record) => (
        <Badge variant={getStatusVariant(record.status)}>
          {record.status}
        </Badge>
      )
    });
  }

  const onRowClick = (record: KitchenSummary) => {
    navigate(`/restaurants/${record.kitchenId}`, {
      state: { from: location.search },
    });
  };

  return (
    <>
      <div className="flex flex-col md:flex-row gap-4 mb-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground z-10 pointer-events-none" />
          <Input
            placeholder="Search using kitchen name"
            value={searchInput}
            onChange={handleSearchChange}
            className="pl-10 h-10 bg-background/50 backdrop-blur-sm"
          />
        </div>
        <div className="flex gap-2">
          <AlertsDrawer
            alerts={alerts}
            alertsLoading={alertsLoading}
            unviewedCount={unviewedCount}
            onRefresh={fetchAlerts}
            onAlertViewed={handleAlertViewed}
            onLoadMore={handleLoadMoreAlerts}
            hasMore={!!alertsPagination && alertsPagination.page < alertsPagination.totalPages}
            loadingMore={moreAlertsLoading}
            totalCount={alertsPagination?.total || 0}
          />
        </div>
      </div>

      <div className="bg-card/50 backdrop-blur-sm rounded-lg border shadow-sm overflow-hidden">
        <Tabs
          value={activeTab}
          onValueChange={(val) => {
            const newParams = new URLSearchParams(searchParams);
            if (val === "all") {
              newParams.delete("status");
            } else {
              newParams.set("status", val.toUpperCase());
            }
            newParams.set("page", "1");
            setSearchParams(newParams);
          }}
          className="w-full"
        >
          <div className="p-6 border-b bg-zinc-50/50 dark:bg-zinc-900/50 backdrop-blur-md">
            <TabsList className="h-12 p-1.5 bg-zinc-200/40 dark:bg-zinc-800/40 rounded-2xl border border-zinc-200/10 dark:border-zinc-700/10 overflow-x-auto no-scrollbar justify-start">
              <TabsTrigger
                value="all"
                className="px-5 py-2 rounded-xl text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-zinc-950 data-[state=active]:text-primary data-[state=active]:shadow-lg flex items-center gap-2.5"
              >
                <LayoutGrid className="h-4 w-4" />
                <span>All</span>
              </TabsTrigger>
              <TabsTrigger
                value="approved"
                className="px-5 py-2 rounded-xl text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-zinc-950 data-[state=active]:text-green-600 data-[state=active]:shadow-lg flex items-center gap-2.5"
              >
                <CheckCircle className="h-4 w-4" />
                <span>Approved</span>
              </TabsTrigger>
              <TabsTrigger
                value="pending"
                className="px-5 py-2 rounded-xl text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-zinc-950 data-[state=active]:text-yellow-600 data-[state=active]:shadow-lg flex items-center gap-2.5"
              >
                <Clock className="h-4 w-4" />
                <span>Pending</span>
              </TabsTrigger>
              <TabsTrigger
                value="rejected"
                className="px-5 py-2 rounded-xl text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-zinc-950 data-[state=active]:text-red-600 data-[state=active]:shadow-lg flex items-center gap-2.5"
              >
                <XCircle className="h-4 w-4" />
                <span>Rejected</span>
              </TabsTrigger>
              <TabsTrigger
                value="expiring"
                className="px-5 py-2 rounded-xl text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-zinc-950 data-[state=active]:text-orange-600 data-[state=active]:shadow-lg flex items-center gap-2.5"
              >
                <AlertTriangle className="h-4 w-4" />
                <span>Expiring</span>
              </TabsTrigger>
            </TabsList>
          </div>

          {["all", "approved", "pending", "rejected", "expiring"].map((tab) => (
            <TabsContent key={tab} value={tab} className="m-0 p-4">
              <DynamicTable
                columns={columns}
                data={kitchens}
                loading={loading}
                emptyMessage="No restaurants found."
                onRowClick={onRowClick}
              />
              {pagination && (
                <div className="mt-4">
                  <Pagination
                    Pagination={{
                      page: currentPage,
                      totalCount: pagination.totalRecords,
                      totalPages: pagination.totalPages,
                      size: ITEMS_PER_PAGE,
                    }}
                    onPageChange={(page) => {
                      const newParams = new URLSearchParams(searchParams);
                      newParams.set("page", page.toString());
                      setSearchParams(newParams);
                    }}
                  />
                </div>
              )}
            </TabsContent>
          ))}
        </Tabs>
      </div>

      <AlertDialog open={confirmOpen} onOpenChange={setConfirmOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Confirm update</AlertDialogTitle>
            <AlertDialogDescription>
              {confirmDescription}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={performStatusChange}>
              Confirm
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
