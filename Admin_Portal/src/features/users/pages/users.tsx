import { useEffect, useCallback, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate, useSearchParams } from "react-router-dom";
import { AppDispatch, RootState } from "@/store/store";
import { fetchUsers, setSearch, setPage, updateUserStatus, setFilter, clearSuccessMessage, clearError, markDeletionsSeenThunk, checkDeletionRequests, resetPagination } from "../usersSlice";
import { Input } from "@/components/ui/input";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Search } from "lucide-react";
import Pagination from "@/components/Pagination/Pagination";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { DynamicTable, TableColumn } from "@/components/table/DynamicTable";
import { User, DeactivationReasonType, UserFilterStatus } from "../types";
import { usePermissions } from "@/hooks/usePermissions";
import debounce from "lodash/debounce";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import { toast } from "sonner";
import { AlertTriangle, CheckCircle2, Mail, Phone, Calendar, User as UserIcon, ShieldCheck, History, Clock, Key, Users as UsersGroup, UserCheck, UserMinus, UserX } from "lucide-react";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";


export default function Users() {
    const dispatch = useDispatch<AppDispatch>();
    const navigate = useNavigate();
    const [searchParams, setSearchParams] = useSearchParams();
    const permissions = usePermissions("users");
    const { users, pagination, loading, filters, successMessage, error, hasDeletionRequests } = useSelector(
        (state: RootState) => state.users
    );
    const urlSearch = searchParams.get("search") || "";
    const [actionModalOpen, setActionModalOpen] = useState(false);
    const [selectedUser, setSelectedUser] = useState<User | null>(null);
    const [actionType, setActionType] = useState<"activate" | "inactivate">("inactivate");
    const [deactivationReason, setDeactivationReason] = useState("");
    const [deactivationReasonType, setDeactivationReasonType] = useState<DeactivationReasonType | "">("");
    const [viewModalOpen, setViewModalOpen] = useState(false);
    const [viewUser, setViewUser] = useState<User | null>(null);


    useEffect(() => {
        if (!permissions.hasRead) {
            navigate("/403", { replace: true });
        }
    }, [permissions.hasRead, navigate]);

    useEffect(() => {
        dispatch(resetPagination());
    }, [dispatch]);

    useEffect(() => {
        if (urlSearch !== filters.search) {
            dispatch(setSearch(urlSearch));
        }
        const urlFilter = searchParams.get("filter") as UserFilterStatus || "";
        if (urlFilter !== filters.filter) {
            dispatch(setFilter(urlFilter));
        }
    }, []);

    const debouncedFetchUsers = useCallback(
        debounce((search: string, page: number, limit: number, filter: UserFilterStatus) => {
            const trimmedSearch = search.trim();
            if (trimmedSearch.length >= 3 || trimmedSearch.length === 0) {
                dispatch(fetchUsers({ page, limit, search: trimmedSearch.length >= 3 ? trimmedSearch : "", filter }));
            }
        }, 500),
        [dispatch]
    );

    useEffect(() => {
        debouncedFetchUsers(filters.search, filters.page, filters.limit, filters.filter);
        return () => debouncedFetchUsers.cancel();
    }, [filters.page, filters.limit, filters.search, filters.filter, debouncedFetchUsers]);

    useEffect(() => {
        if (successMessage) {
            toast.success(successMessage);
            dispatch(fetchUsers({
                page: filters.page,
                limit: filters.limit,
                search: filters.search,
                filter: filters.filter
            }));
            dispatch(clearSuccessMessage());
        }
    }, [successMessage, dispatch]);

    useEffect(() => {
        if (error) {
            toast.error(error);
            dispatch(clearError());
        }
    }, [error, dispatch]);

    useEffect(() => {
        const currentUrlSearch = searchParams.get("search") || "";
        const trimmedSearch = filters.search.trim();
        if (trimmedSearch.length >= 3) {
            if (trimmedSearch !== currentUrlSearch) {
                searchParams.set("search", trimmedSearch);
                setSearchParams(searchParams);
            }
        } else if (trimmedSearch.length === 0 && currentUrlSearch) {
            searchParams.delete("search");
            setSearchParams(searchParams);
        }

        const currentUrlFilter = searchParams.get("filter") || "";

        if (filters.filter !== currentUrlFilter) {
            if (filters.filter) {
                searchParams.set("filter", filters.filter);
            } else {
                searchParams.delete("filter");
            }
            setSearchParams(searchParams);
        }
    }, [filters.search, filters.filter, searchParams, setSearchParams]);

    const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        dispatch(setSearch(e.target.value));
    };

    const getUserInitials = (name: string) => {
        return name
            ?.split(" ")
            .map((n) => n[0])
            .join("")
            .toUpperCase()
            .slice(0, 2) || "U";
    };

    const columns: TableColumn<User>[] = [
        {
            key: "userId",
            label: "ID",
            width: "80px",
            render: (_, record) => (
                <span className="font-mono text-sm text-muted-foreground">
                    #{record.userId}
                </span>
            ),
        },
        {
            key: "name",
            label: "User Profile",
            render: (_, record) => (
                <div className="flex items-center gap-3 max-w-[250px]">
                    <Avatar className="h-10 w-10 border-2 border-background shadow-sm flex-shrink-0">
                        {record.profilePicture ? (
                            <AvatarImage src={record.profilePicture} alt={record.name} />
                        ) : null}
                        <AvatarFallback className="bg-primary/10 text-primary font-medium">
                            {getUserInitials(record.name)}
                        </AvatarFallback>
                    </Avatar>
                    <div className="min-w-0">
                        <p className="font-medium leading-snug truncate" title={record.name}>{record.name}</p>
                    </div>
                </div>
            ),
        },
        {
            key: "phoneNumber",
            label: "Contact Info",
            render: (val) => <div className="text-sm">{val || '--'}</div>,
        },
        {
            key: "email",
            label: "Email Address",
            render: (val) => (
                <div className="text-sm text-muted-foreground max-w-[200px] truncate whitespace-nowrap" title={val}>{val}</div>
            ),
        },
        {
            key: "status",
            label: "Status",
            render: (val, record) => {
                const status = record.status || "INACTIVE";
                let variant: "default" | "secondary" | "destructive" | "outline" = "default";
                let className = "";
                let label: string = status;

                switch (status) {
                    case "ACTIVE":
                        variant = "secondary";
                        className = "bg-green-100 text-green-700 hover:bg-green-100/80 border-green-200";
                        label = "Active";
                        break;
                    case "INACTIVE":
                        variant = "secondary";
                        className = "bg-yellow-100 text-yellow-700 hover:bg-yellow-100/80 border-yellow-200";
                        label = "Inactive";
                        break;
                    case "DELETING_SOON":
                        variant = "destructive";
                        label = "Deleting Soon";
                        break;
                    default:
                        variant = "secondary";
                        break;
                }

                return (
                    <Badge variant={variant} className={`capitalize ${className} whitespace-nowrap`}>
                        {label}
                    </Badge>
                );
            },
        },

        {
            key: "reasonType",
            label: "Report Info",
            render: (_, record) => {
                const userStatus = record.status || 'INACTIVE';
                if (userStatus === "ACTIVE") return null;
                if (userStatus !== "INACTIVE" && userStatus !== "DELETING_SOON") return <span className="text-muted-foreground">--</span>;

                return (
                    <div className="flex flex-col gap-2 text-[10px] min-w-[200px] bg-zinc-50 dark:bg-zinc-900/40 p-2 rounded-xl border border-zinc-100 dark:border-zinc-800/60 shadow-sm">
                        <div className="flex justify-between items-center gap-2">
                            <div className="flex items-center gap-1.5 min-w-0 max-w-[140px]">
                                <AlertTriangle className="h-3 w-3 text-red-400 shrink-0" />
                                <span className="font-bold text-zinc-900 dark:text-zinc-200 truncate" title={record.reasonType || '--'}>{record.reasonType || '--'}</span>
                            </div>
                            {record.scheduledDeletionAt && (
                                <Badge variant="outline" className="h-4.5 px-1.5 text-[9px] font-black bg-red-500/10 text-red-600 border-red-200 dark:border-red-900/30 shrink-0">
                                    {(() => {
                                        const diff = new Date(record.scheduledDeletionAt).getTime() - new Date().getTime();
                                        const days = Math.ceil(diff / (1000 * 60 * 60 * 24));
                                        return days > 0 ? `${days}d Left` : "Expired";
                                    })()}
                                </Badge>
                            )}
                        </div>
                        {record.reasonText && (
                            <div className="px-1.5 py-1 rounded-md bg-white/50 dark:bg-zinc-950/30 border border-zinc-100 dark:border-zinc-800/50 max-w-[200px] overflow-hidden">
                                <p className="text-zinc-500 dark:text-zinc-400 leading-tight italic truncate text-[10px]" title={record.reasonText}>
                                    "{record.reasonText}"
                                </p>
                            </div>
                        )}
                    </div>
                );
            },
        },
        {
            key: "actionsKey",
            label: "Actions",
            render: (_, record) => {
                const userStatus = record.status || 'INACTIVE';

                return (
                    <div className="flex justify-start items-center gap-2">
                        {userStatus === "ACTIVE" ? (
                            <Button
                                variant="outline"
                                size="sm"
                                className="bg-white hover:bg-red-50 text-red-600 border-red-200 hover:border-red-300 hover:text-red-700 shadow-sm transition-all whitespace-nowrap"
                                onClick={(e) => {
                                    e.stopPropagation();
                                    setSelectedUser(record);
                                    setActionType("inactivate");
                                    setDeactivationReason("");
                                    setActionModalOpen(true);
                                }}
                            >
                                Inactivate
                            </Button>
                        ) : userStatus === "INACTIVE" ? (
                            <Button
                                variant="outline"
                                size="sm"
                                className="bg-white hover:bg-green-50 text-green-600 border-green-200 hover:border-green-300 hover:text-green-700 shadow-sm transition-all whitespace-nowrap"
                                onClick={(e) => {
                                    e.stopPropagation();
                                    setSelectedUser(record);
                                    setActionType("activate");
                                    setDeactivationReason("");
                                    setDeactivationReasonType("");
                                    setActionModalOpen(true);
                                }}
                            >
                                Activate
                            </Button>
                        ) : (
                            <></>
                        )}
                    </div>
                );
            },
        },
    ].filter(col => {
        if (filters.filter === 'DELETING_SOON' && col.key === 'actionsKey') {
            return false;
        }
        return true;
    });

    const handleActionConfirm = async () => {
        if (actionType === 'inactivate') {
            if (!deactivationReasonType) {
                toast.error("Please select a reason type for inactivation");
                return;
            }
            if (!deactivationReason.trim()) {
                toast.error("Please provide a reason text for inactivation");
                return;
            }
        };

        if (selectedUser) {
            const payload = {
                userId: selectedUser.userId,
                data: {
                    status: actionType === 'activate' ? 'ACTIVE' as const : 'INACTIVE' as const,
                    ...(actionType === 'inactivate' && {
                        reasonType: deactivationReasonType as DeactivationReasonType,
                        reasonText: deactivationReason
                    })
                }
            };
            await dispatch(updateUserStatus(payload));
        }
        setActionModalOpen(false);
        setSelectedUser(null);
        setDeactivationReason("");
        setDeactivationReasonType("");
    };

    return (
        <>

            <div className="flex flex-col lg:flex-row gap-6 justify-between items-start lg:items-center mb-8 bg-zinc-50/50 dark:bg-zinc-900/50 p-6 rounded-[2rem] border border-zinc-200/50 dark:border-zinc-800/50 backdrop-blur-xl shadow-sm">
                <div className="relative w-full lg:w-96 order-2 lg:order-1">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4.5 w-4.5 text-zinc-400 z-10 pointer-events-none" />
                    <Input
                        placeholder="Search users..."
                        value={filters.search}
                        onChange={handleSearchChange}
                        className="pl-12 h-12 bg-white/70 dark:bg-zinc-950/70 border-zinc-200/40 dark:border-zinc-800/40 rounded-2xl transition-all focus:ring-2 focus:ring-primary/10 focus:border-primary shadow-sm text-sm"
                    />
                </div>
                <div className="w-full lg:w-auto order-1 lg:order-2 overflow-x-auto no-scrollbar py-1">
                    <Tabs
                        value={filters.filter || "ALL"}
                        onValueChange={(value) => {
                            const filterValue = value === "ALL" ? "" : value as UserFilterStatus;
                            dispatch(setFilter(filterValue));
                            if (value === "DELETING_SOON") {
                                dispatch(markDeletionsSeenThunk()).then(() => {
                                    dispatch(checkDeletionRequests());
                                });
                            }
                        }}
                    >
                        <TabsList className="h-12 p-1.5 bg-zinc-200/40 dark:bg-zinc-800/40 rounded-2xl border border-zinc-200/10 dark:border-zinc-700/10 backdrop-blur-sm">
                            <TabsTrigger
                                value="ALL"
                                className="px-5 py-2 rounded-xl text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-zinc-950 data-[state=active]:text-primary data-[state=active]:shadow-lg flex items-center gap-2.5"
                            >
                                <UsersGroup className="h-4 w-4" />
                                <span className="hidden sm:inline">All Users</span>
                                <span className="sm:hidden">All</span>
                            </TabsTrigger>
                            <TabsTrigger
                                value="ACTIVE"
                                className="px-5 py-2 rounded-xl text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-zinc-950 data-[state=active]:text-green-600 data-[state=active]:shadow-lg flex items-center gap-2.5"
                            >
                                <UserCheck className="h-4 w-4" />
                                <span className="hidden sm:inline">Active</span>
                                <span className="sm:hidden">Active</span>
                            </TabsTrigger>
                            <TabsTrigger
                                value="INACTIVE"
                                className="px-5 py-2 rounded-xl text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-zinc-950 data-[state=active]:text-yellow-600 data-[state=active]:shadow-lg flex items-center gap-2.5"
                            >
                                <UserMinus className="h-4 w-4" />
                                <span className="hidden sm:inline">Inactive</span>
                                <span className="sm:hidden">Inactive</span>
                            </TabsTrigger>
                            <TabsTrigger
                                value="DELETING_SOON"
                                className="px-5 py-2 rounded-xl text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-zinc-950 data-[state=active]:text-red-600 data-[state=active]:shadow-lg flex items-center gap-2.5 relative"
                            >
                                <UserX className="h-4 w-4" />
                                <span className="hidden sm:inline">Deleting Soon</span>
                                <span className="sm:hidden">Deleting</span>
                                {hasDeletionRequests && (
                                    <span className="absolute -top-1 -right-1 inline-flex h-2.5 w-2.5 rounded-full bg-red-500 ring-2 ring-white dark:ring-zinc-950" />
                                )}
                            </TabsTrigger>
                        </TabsList>
                    </Tabs>
                </div>
            </div>

            <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
                <CardHeader>
                    <CardTitle>Registered Users</CardTitle>
                    <CardDescription>
                        View and manage user details across the platform
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    <DynamicTable
                        columns={columns.filter(col => {
                            if (filters.filter === "ACTIVE" || filters.filter === "INACTIVE") {
                                return col.key !== "status";
                            }
                            return true;
                        })}
                        data={users}
                        loading={loading}
                        emptyMessage="No users found matching your criteria."
                        skeletonRows={5}
                        rowKey="userId"
                        onRowClick={(record) => {
                            setViewUser(record);
                            setViewModalOpen(true);
                        }}
                    />

                    {pagination && (
                        <div className="mt-4">
                            <Pagination
                                Pagination={{
                                    page: pagination.currentPage,
                                    totalCount: pagination.totalUsers,
                                    totalPages: pagination.totalPages,
                                    size: filters.limit,
                                }}
                                onPageChange={(page) => dispatch(setPage(page))}
                            />
                        </div>
                    )}
                </CardContent>
            </Card>

            <Dialog open={actionModalOpen} onOpenChange={setActionModalOpen}>
                <DialogContent className="sm:max-w-[450px] p-0 overflow-hidden bg-white/95 dark:bg-zinc-950/95 backdrop-blur-xl border border-zinc-200 dark:border-zinc-800 shadow-2xl rounded-3xl">
                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-primary to-transparent opacity-50" />
                    <DialogHeader className="p-8 pb-4 space-y-4">
                        <div className="flex items-center gap-4">
                            <div className={`p-3 rounded-2xl ${actionType === 'activate'
                                ? 'bg-green-50 dark:bg-green-950/30 text-green-600'
                                : 'bg-red-50 dark:bg-red-950/30 text-red-600'
                                }`}>
                                {actionType === 'activate' ? (
                                    <CheckCircle2 className="h-6 w-6" />
                                ) : (
                                    <AlertTriangle className="h-6 w-6" />
                                )}
                            </div>
                            <div className="space-y-1 text-left min-w-0 flex-1">
                                <DialogTitle className="text-xl font-bold tracking-tight text-zinc-900 dark:text-zinc-50 truncate">
                                    {actionType === 'activate' ? 'Activate User' : 'Inactivate User'}
                                </DialogTitle>
                                <DialogDescription className="text-sm font-medium text-zinc-500 dark:text-zinc-400 break-words">
                                    {actionType === 'activate'
                                        ? `Are you sure you want to activate`
                                        : `Are you sure you want to inactivate`
                                    } <span className="text-zinc-900 dark:text-zinc-100 font-semibold break-all">
                                        "{selectedUser?.name && selectedUser.name.length > 30
                                            ? selectedUser.name.slice(0, 30) + "..."
                                            : selectedUser?.name}"
                                    </span>?
                                </DialogDescription>
                            </div>
                        </div>
                    </DialogHeader>

                    <div className="px-8 pb-6">
                        {actionType === 'inactivate' && (
                            <div className="space-y-5">
                                <div className="space-y-2">
                                    <Label className="text-xs font-semibold text-zinc-500 dark:text-zinc-400 ml-1">
                                        Reason Type
                                    </Label>
                                    <Select
                                        value={deactivationReasonType}
                                        onValueChange={(val) => setDeactivationReasonType(val as DeactivationReasonType)}
                                    >
                                        <SelectTrigger className="h-11 bg-zinc-50 dark:bg-zinc-900 border-zinc-200 dark:border-zinc-800 focus:ring-primary/20 rounded-xl transition-all">
                                            <SelectValue placeholder="Select a reason type" />
                                        </SelectTrigger>
                                        <SelectContent className="rounded-xl">
                                            <SelectItem value="Fraud">Fraud</SelectItem>
                                            <SelectItem value="Policy Violation">Policy Violation</SelectItem>
                                            <SelectItem value="Payment Issues">Payment Issues</SelectItem>
                                            <SelectItem value="Suspicious Activity">Suspicious Activity</SelectItem>
                                            <SelectItem value="Terms of Service Breach">Terms of Service Breach</SelectItem>
                                            <SelectItem value="Spam/Abuse">Spam/Abuse</SelectItem>
                                            <SelectItem value="Others">Others</SelectItem>
                                        </SelectContent>
                                    </Select>
                                </div>
                                <div className="space-y-2">
                                    <div className="flex justify-between items-center ml-1">
                                        <Label htmlFor="reason" className="text-xs font-semibold text-zinc-500 dark:text-zinc-400">
                                            Reason Details
                                        </Label>
                                        <span className={`text-[10px] font-bold ${deactivationReason.length >= 280 ? 'text-red-500' : 'text-zinc-400'}`}>
                                            {deactivationReason.length}/300
                                        </span>
                                    </div>
                                    <div className="space-y-1">
                                        <Textarea
                                            id="reason"
                                            placeholder="Please provide a detailed reason for inactivation..."
                                            value={deactivationReason}
                                            onChange={(e) => setDeactivationReason(e.target.value)}
                                            maxLength={300}
                                            className="min-h-[120px] bg-zinc-50 dark:bg-zinc-900 border-zinc-200 dark:border-zinc-800 focus:border-primary focus:ring-primary/10 resize-none rounded-xl text-sm transition-all shadow-sm"
                                        />
                                        <div className="flex justify-end px-1">
                                            <span className={`text-[10px] font-bold ${deactivationReason.length >= 280 ? 'text-red-500' : 'text-zinc-400'}`}>
                                                {deactivationReason.length}/300
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>

                    <DialogFooter className="p-6 bg-zinc-50 dark:bg-zinc-900/50 border-t border-zinc-100 dark:border-zinc-800 flex flex-row gap-3">
                        <Button
                            variant="ghost"
                            onClick={() => setActionModalOpen(false)}
                            className="flex-1 h-11 font-semibold rounded-xl hover:bg-zinc-200 dark:hover:bg-zinc-800 transition-colors"
                        >
                            Cancel
                        </Button>
                        <Button
                            onClick={handleActionConfirm}
                            className={`flex-1 h-11 font-semibold rounded-xl text-white shadow-md transition-all active:scale-95 ${actionType === 'activate'
                                ? 'bg-green-600 hover:bg-green-700 shadow-green-500/20'
                                : 'bg-red-600 hover:bg-red-700 shadow-red-500/20'
                                }`}
                        >
                            {actionType === 'activate' ? 'Confirm Activation' : 'Confirm Inactivation'}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            <Dialog open={viewModalOpen} onOpenChange={setViewModalOpen}>
                <DialogContent className="sm:max-w-[480px] p-0 overflow-hidden bg-white dark:bg-zinc-950 border border-zinc-200 dark:border-zinc-800 shadow-2xl rounded-[1.25rem] transition-all duration-300">
                    <div className="bg-gradient-to-br from-zinc-100 to-zinc-200 dark:from-zinc-900 dark:to-zinc-950 p-6 border-b border-zinc-200 dark:border-zinc-800 relative">
                        <div className="flex flex-col items-center gap-3 mt-1">
                            <Avatar className="h-16 w-16 border-2 border-white dark:border-zinc-800 shadow-lg ring-1 ring-primary/20">
                                {viewUser?.profilePicture ? (
                                    <AvatarImage src={viewUser.profilePicture} alt={viewUser.name} />
                                ) : null}
                                <AvatarFallback className="bg-primary/10 text-primary text-2xl font-bold">
                                    {getUserInitials(viewUser?.name || "")}
                                </AvatarFallback>
                            </Avatar>

                            <div className="text-center space-y-1 max-w-full px-4">
                                <h3 className="text-2xl font-black tracking-tight text-zinc-900 dark:text-zinc-50 break-all leading-tight" title={viewUser?.name}>
                                    {viewUser?.name && viewUser.name.length > 30 ? viewUser.name.slice(0, 30) + "..." : viewUser?.name}
                                </h3>
                                <div className="flex items-center justify-center gap-2 py-1 px-3 rounded-full bg-white/50 dark:bg-zinc-800/50 border border-zinc-200/50 dark:border-zinc-700/50 w-fit mx-auto shadow-sm">
                                    <Key className="h-3 w-3 text-zinc-400" />
                                    <span className="text-[10px] font-bold text-zinc-500 dark:text-zinc-400 uppercase tracking-widest">User ID: #{viewUser?.userId}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div className="p-6 space-y-5 max-h-[60vh] overflow-y-auto custom-scrollbar">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-4 min-w-0">
                                <h4 className="text-[9px] font-black uppercase tracking-[0.2em] text-zinc-400 dark:text-zinc-500 border-b border-zinc-100 dark:border-zinc-800 pb-1.5">
                                    Contact Details
                                </h4>
                                <div className="space-y-3">
                                    <div className="flex items-center gap-3">
                                        <div className="p-2.5 rounded-xl bg-zinc-50 dark:bg-zinc-900 text-zinc-500 dark:text-zinc-400 border border-zinc-100 dark:border-zinc-800 shrink-0">
                                            <Mail className="h-4 w-4" />
                                        </div>
                                        <div className="space-y-0.5 min-w-0">
                                            <p className="text-[10px] font-bold text-zinc-400 dark:text-zinc-600 uppercase tracking-wider">Email</p>
                                            <p className="text-sm font-semibold truncate text-zinc-700 dark:text-zinc-300" title={viewUser?.email}>{viewUser?.email}</p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-3">
                                        <div className="p-2.5 rounded-xl bg-zinc-50 dark:bg-zinc-900 text-zinc-500 dark:text-zinc-400 border border-zinc-100 dark:border-zinc-800 shrink-0">
                                            <Phone className="h-4 w-4" />
                                        </div>
                                        <div className="space-y-0.5 min-w-0">
                                            <p className="text-[10px] font-bold text-zinc-400 dark:text-zinc-600 uppercase tracking-wider">Phone</p>
                                            <p className="text-sm font-semibold text-zinc-700 dark:text-zinc-300 truncate">{viewUser?.phoneNumber || '--'}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="space-y-4 min-w-0">
                                <h4 className="text-[9px] font-black uppercase tracking-[0.2em] text-zinc-400 dark:text-zinc-500 border-b border-zinc-100 dark:border-zinc-800 pb-1.5">
                                    Platform Info
                                </h4>
                                <div className="space-y-3">
                                    <div className="flex items-center gap-3">
                                        <div className="p-2.5 rounded-xl bg-zinc-50 dark:bg-zinc-900 text-zinc-500 dark:text-zinc-400 border border-zinc-100 dark:border-zinc-800 shrink-0">
                                            <Calendar className="h-4 w-4" />
                                        </div>
                                        <div className="space-y-0.5 min-w-0">
                                            <p className="text-[10px] font-bold text-zinc-400 dark:text-zinc-600 uppercase tracking-wider">Requested At</p>
                                            <p className="text-sm font-semibold text-zinc-700 dark:text-zinc-300 truncate">
                                                {viewUser?.requestedAt ? new Date(viewUser.requestedAt).toLocaleDateString(undefined, { dateStyle: 'medium' }) : '--'}
                                            </p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-3">
                                        <div className="p-2.5 rounded-xl bg-zinc-50 dark:bg-zinc-900 text-zinc-500 dark:text-zinc-400 border border-zinc-100 dark:border-zinc-800 shrink-0">
                                            <ShieldCheck className="h-4 w-4" />
                                        </div>
                                        <div className="space-y-0.5 min-w-0">
                                            <p className="text-[10px] font-bold text-zinc-400 dark:text-zinc-600 uppercase tracking-wider">Account Status</p>
                                            <p className="text-sm font-semibold text-zinc-700 dark:text-zinc-300 capitalize truncate">{viewUser?.status.toLowerCase().replace(/_/g, ' ')}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {(viewUser?.status === 'INACTIVE' || viewUser?.status === 'DELETING_SOON') && (
                            <div className="space-y-3 animate-in fade-in slide-in-from-top-2 duration-500">
                                <h4 className="text-[9px] font-black uppercase tracking-[0.2em] text-red-500 dark:text-red-400 border-b border-red-100 dark:border-red-900/20 pb-1.5">
                                    Report Info
                                </h4>
                                <div className="p-4 rounded-xl bg-red-50/50 dark:bg-red-950/20 border border-red-100 dark:border-red-900/30 space-y-3">
                                    <div className="flex justify-between gap-8">
                                        <div className="space-y-1">
                                            <p className="text-[10px] font-bold text-red-400 uppercase tracking-widest flex items-center gap-2">
                                                <History className="h-3 w-3" />
                                                Reason Category
                                            </p>
                                            <p className="text-sm font-bold text-zinc-800 dark:text-red-200">
                                                {viewUser.reasonType || '--'}
                                            </p>
                                        </div>
                                        <div className="space-y-1 text-right shrink-0">
                                            <p className="text-[10px] font-bold text-red-400 uppercase tracking-widest flex items-center gap-2 justify-end">
                                                <Clock className="h-3 w-3" />
                                                Scheduled Deletion
                                            </p>
                                            <p className="text-sm font-bold text-red-600 dark:text-red-400">
                                                {viewUser.scheduledDeletionAt ? new Date(viewUser.scheduledDeletionAt).toLocaleDateString(undefined, { dateStyle: 'medium' }) : 'Not Scheduled'}
                                            </p>
                                        </div>
                                    </div>

                                    <div className="space-y-2 mt-2 pt-4 border-t border-red-100 dark:border-red-900/30">
                                        <p className="text-[10px] font-bold text-red-400 uppercase tracking-widest">Detailed Explanation</p>
                                        <div className="bg-white/50 dark:bg-zinc-950/50 p-4 rounded-xl shadow-inner-sm border border-red-200/20">
                                            <p className="text-sm italic leading-relaxed text-zinc-700 dark:text-zinc-300 break-words">
                                                "{viewUser.reasonText || 'No detailed reason provided.'}"
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                </DialogContent>
            </Dialog>
        </>
    );
}
