import { useEffect, useState, useMemo } from "react";
import { useDispatch, useSelector } from "react-redux";
import { useParams, useNavigate, useLocation, useSearchParams } from "react-router-dom";
import moment from "moment";
import { cn } from "@/lib/utils";
import { AppDispatch, RootState } from "@/store/store";
import { fetchKitchenById, changeKitchenStatus, changeComplianceStatus, fetchKitchenAuditLogs } from "../kitchensSlice";
import { updateKitchenStripeAccountId } from "../kitchenService";
import {
  KitchenDetails as KitchenDetailsType,
  UpdateKitchenStatusPayload,
  UpdateComplianceStatusPayload,
  KitchenAuditLog,
} from "../types";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { DynamicTable, TableColumn } from "@/components/table/DynamicTable";
import Pagination from "@/components/Pagination/Pagination";
import { Badge } from "@/components/ui/badge";
import {
  Card, CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  Mail,
  Phone,
  Clock,
  MapPin,
  User,
  FileText,
  Star,
  CheckCircle2,
  Calendar as CalendarIcon,
  CreditCard,
  ChevronRight,
  ShieldCheck,
  PlusCircle,
  AlertCircle,
  Settings2,
  Store,
  Info,
  ExternalLink,
} from "lucide-react";

import { toast } from "sonner";
import { Textarea } from "@/components/ui/textarea";
import { usePermissions } from "@/hooks/usePermissions";
import { Calendar } from "@/components/ui/calendar";

import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogDescription,
} from "@/components/ui/dialog";

interface KitchenDetailsProps {
  id?: string;
  onBack?: () => void;
}

const InfoRow = ({
  label,
  value,
  icon: Icon,
}: {
  label: string;
  value: React.ReactNode;
  icon?: React.ElementType;
}) => (
  <div className="group flex items-center justify-between py-3.5 border-b border-primary/5 last:border-b-0 hover:bg-primary/[0.02] transition-colors px-1 -mx-1 rounded-lg">
    <div className="flex items-center gap-3">
      <div className="p-1.5 rounded-md bg-primary/5 text-primary group-hover:bg-primary group-hover:text-primary-foreground transition-all duration-300">
        {Icon && <Icon className="h-3.5 w-3.5" />}
      </div>
      <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground/80">{label}</span>
    </div>
    <span className="font-bold text-sm text-foreground text-right truncate max-w-[50%]">{value}</span>
  </div>
);

const BentoCard = ({
  title,
  children,
  icon: Icon,
  className = "",
  badge,
}: {
  title: string;
  children: React.ReactNode;
  icon?: React.ElementType;
  className?: string;
  badge?: string;
}) => (
  <Card className={`group relative overflow-hidden bg-white/50 dark:bg-zinc-900/50 backdrop-blur-xl border-zinc-200/50 dark:border-zinc-800/50 hover:border-primary/30 transition-all duration-500 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_20px_40px_rgba(0,0,0,0.08)] ${className}`}>
    <div className="absolute inset-0 bg-gradient-to-br from-primary/[0.02] via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
    <CardHeader className="pb-4 pt-6 px-6">
      <div className="flex items-center justify-between">
        <CardTitle className="text-sm font-black uppercase tracking-[0.2em] flex items-center gap-2.5 text-zinc-500 group-hover:text-primary transition-colors">
          {Icon && <Icon className="h-4 w-4" />}
          {title}
        </CardTitle>
        {badge && (
          <Badge variant="outline" className="text-[10px] font-black uppercase tracking-widest border-primary/20 bg-primary/5">
            {badge}
          </Badge>
        )}
      </div>
    </CardHeader>
    <CardContent className="px-6 pb-6 relative">
      {children}
    </CardContent>
  </Card>
);

export const KitchenDetails: React.FC<KitchenDetailsProps> = ({
  id: propId,
  onBack,
}) => {
  const { id: paramId } = useParams<{ id: string }>();
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();
  const location = useLocation();
  const id = propId || paramId;

  const handleBack = () => {
    if (onBack) {
      onBack();
    } else if (location.state?.from) {
      navigate(`/restaurants${location.state.from}`);
    } else {
      navigate("/restaurants");
    }
  };

  const dispatch = useDispatch<AppDispatch>();
  const { kitchen, loading, error } = useSelector((s: RootState) => s.kitchens);
  const { hasEdit, checkEdit } = usePermissions("restaurants");
  const { hasRead: canViewLogs } = usePermissions("audit logs");
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [pendingStatus, setPendingStatus] = useState<"APPROVED" | "REJECTED" | null>(null);
  const [confirmContext, setConfirmContext] = useState<"KITCHEN" | "COMPLIANCE" | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [expireDate, setExpireDate] = useState<Date | undefined>(undefined);
  const [certsOpen, setCertsOpen] = useState(false);
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [validationError, setValidationError] = useState<string | null>(null);

  const [stripeOpen, setStripeOpen] = useState(false);
  const [stripeId, setStripeId] = useState("");
  const [stripeError, setStripeError] = useState<string | null>(null);

  const { auditLogs, auditLogsLoading, auditLogsPagination } = useSelector((s: RootState) => s.kitchens);
  const [logsPage, setLogsPage] = useState(1);
  const ITEMS_PER_PAGE = 10;

  const activeTab = useMemo(() => {
    const tab = searchParams.get("tab")?.toLowerCase();
    if (tab === "logs") return "logs";
    return "details";
  }, [searchParams]);

  useEffect(() => {
    if (id) {
      dispatch(fetchKitchenAuditLogs({ kitchenId: id, page: logsPage, limit: ITEMS_PER_PAGE }));
    }
  }, [id, logsPage, dispatch]);

  const isObject = (v: any) => typeof v === 'object' && v !== null;

  const renderAuditValue = (val: any, isNew?: boolean) => {
    if (val === null || val === undefined) return <span className="text-zinc-300 italic">--</span>;

    const getStatusColor = (v: any, isCurrent: boolean) => {
      const s = String(v).toLowerCase();
      if (s === 'approved' || s === 'active') return 'text-green-600 bg-green-500/5 border-green-500/20';
      if (s === 'rejected' || s === 'expired' || s === 'inactive') return 'text-red-600 bg-red-500/5 border-red-500/20';
      if (s === 'pending') return 'text-amber-600 bg-amber-500/5 border-amber-500/20';
      return isCurrent ? "text-primary bg-primary/5 border-primary/20" : "text-zinc-600 bg-zinc-500/5 border-zinc-500/20";
    };

    if (isObject(val)) {
      return (
        <div className="space-y-2">
          {Object.entries(val).map(([k, v]) => (
            <div key={k} className="flex flex-col gap-0.5">
              <span className="text-[9px] font-black uppercase tracking-tighter text-zinc-400">
                {k.replace(/([A-Z])/g, ' $1').trim()}
              </span>
              {typeof v === 'string' && (v.startsWith('http') || k.toLowerCase().includes('image')) ? (
                <button onClick={() => setSelectedImage(v)} className="flex items-center gap-1.5 text-[10px] font-bold text-primary hover:underline group/asset w-fit">
                  View Asset
                  <ExternalLink className="h-2.5 w-2.5 transition-transform group-hover/asset:translate-x-0.5" />
                </button>
              ) : (typeof v === 'string' && (k.toLowerCase().includes('date') || k.toLowerCase().includes('at'))) ? (
                <span className={cn("text-xs font-bold whitespace-nowrap px-2 py-0.5 rounded border-l-2", getStatusColor(v, !!isNew))}>
                  {moment(v).isValid() ? moment(v).format("DD/MM/YYYY, HH:mm:ss") : String(v)}
                </span>
              ) : (
                <span className={cn("text-xs font-bold whitespace-nowrap px-2 py-0.5 rounded border-l-2", getStatusColor(v, !!isNew))}>
                  {String(v)}
                </span>
              )}
            </div>
          ))}
        </div>
      );
    }

    return (
      <span className={cn("text-xs font-bold px-2 py-1 rounded border-l-2 inline-block shadow-sm transition-all whitespace-nowrap", getStatusColor(val, !!isNew))}>
        {String(val)}
      </span>
    );
  };

  const getActionConfig = (type: string) => {
    const t = type.toLowerCase();
    if (t.includes('approve')) return { icon: ShieldCheck, color: 'text-green-600', bg: 'bg-green-500/10' };
    if (t.includes('reject') || t.includes('expired')) return { icon: AlertCircle, color: 'text-red-600', bg: 'bg-red-500/10' };
    if (t.includes('stripe')) return { icon: CreditCard, color: 'text-indigo-600', bg: 'bg-indigo-500/10' };
    if (t.includes('registered') || t.includes('added') || t.includes('create')) return { icon: PlusCircle, color: 'text-blue-600', bg: 'bg-blue-500/10' };
    if (t.includes('status') || t.includes('changed') || t.includes('update')) return { icon: Settings2, color: 'text-zinc-600', bg: 'bg-zinc-500/10' };
    return { icon: FileText, color: 'text-zinc-600', bg: 'bg-zinc-500/10' };
  };

  const auditLogsColumns: TableColumn<KitchenAuditLog>[] = [
    {
      key: "actionType",
      label: "Action",
      width: "15%",
      render: (_, row: KitchenAuditLog) => {
        const config = getActionConfig(row.actionType);
        return (
          <div className="flex items-center py-1">
            <div className={cn("flex items-center gap-2 px-3 py-1.5 rounded-full w-fit border border-transparent transition-all hover:border-current/10 whitespace-nowrap", config.bg, config.color)}>
              <config.icon className="h-3.5 w-3.5" />
              <span className="text-[10px] font-black uppercase tracking-wider whitespace-nowrap">{row.actionType?.replace(/_/g, " ").replace("STATUS", "KITCHEN")}</span>
            </div>
          </div>
        );
      }
    },
    {
      key: "actorType",
      label: "Actor Type",
      width: "12%",
      render: (_, row: KitchenAuditLog) => (
        <div className="flex flex-col min-w-0">
          <span className="text-sm font-medium text-zinc-900 dark:text-zinc-100 truncate">
            {row?.actorType?.toLowerCase().replace(/_/g, " ").replace(/\b\w/g, l => l.toUpperCase())}
          </span>
        </div>
      )
    },
    {
      key: "actorRole",
      label: "Actor Role",
      width: "12%",
      render: (_, row: KitchenAuditLog) => (
        <div className="flex flex-col min-w-0">
          <span className="text-sm font-medium text-zinc-900 dark:text-zinc-100 truncate">
            {row?.actorRole?.toLowerCase().replace(/_/g, " ").replace(/\b\w/g, l => l.toUpperCase())}
          </span>
        </div>
      )
    },
    {
      key: "actorName",
      label: "Actor Name",
      width: "12%",
      render: (_, row: KitchenAuditLog) => (
        <div className="flex flex-col min-w-0">
          <span className="text-sm font-medium text-zinc-900 dark:text-zinc-100 truncate">
            {row?.actorName?.toLowerCase().replace(/\b\w/g, l => l.toUpperCase())}
          </span>
        </div>
      )
    },



    {
      key: "oldData",
      label: "From",
      width: "22%",
      render: (_, row: KitchenAuditLog) => (
        <div className="py-2">
          {renderAuditValue(row.oldData)}
        </div>
      )
    },
    {
      key: "newData",
      label: "To",
      width: "22%",
      render: (_, row: KitchenAuditLog) => (
        <div className="py-2">
          {renderAuditValue(row.newData, true)}
        </div>
      )
    },
    {
      key: "reason",
      label: "Reject reason",
      width: "10%",
      render: (_, row: KitchenAuditLog) => (
        <div className="flex flex-col gap-1.5 py-1">
          {row.reason ? (
            <div className="text-[11px] font-bold text-zinc-600 italic bg-zinc-50 p-2 rounded-lg border border-zinc-100/50 leading-relaxed ring-1 ring-zinc-500/5">
              "{row.reason}"
            </div>
          ) : <span className="text-zinc-300 italic pl-2">--</span>}
        </div>
      )
    },
    {
      key: "createdAt",
      label: "Timestamp (UTC)",
      width: "7%",
      render: (_, row: KitchenAuditLog) => (
        <div className="flex flex-col items-end gap-1 text-right py-1">
          <span className="text-xs font-black text-zinc-900 dark:text-zinc-100 tabular-nums">
            {moment(row.createdAt).format("DD/MM/YYYY")}
          </span>
          <span className="text-[10px] font-bold text-zinc-400 uppercase tracking-widest tabular-nums italic">
            {moment(row.createdAt).format("HH:mm:ss")}
          </span>
        </div>
      )
    }
  ];

  useEffect(() => {
    dispatch(fetchKitchenById(id));
  }, [dispatch, id]);

  useEffect(() => {
    console.log('Restaurant Edit Permission Check:', { hasEdit, pageName: 'restaurants' });
  }, [hasEdit]);

  useEffect(() => {
    if (error) toast.error(error);
  }, [error]);

  const performStatusChange = async (status: "APPROVED" | "REJECTED") => {

    if (status === "REJECTED" && !rejectReason.trim()) {
      toast.error("Please provide a rejection reason");
      return;
    }

    try {
      if (confirmContext === "COMPLIANCE") {
        const payload: UpdateComplianceStatusPayload = status === "APPROVED"
          ? {
            status,
            expireDate: expireDate
              ? new Date(expireDate.getTime() - expireDate.getTimezoneOffset() * 60000)
                .toISOString()
                .slice(0, 10)
              : ""
          }
          : {
            status,
            reason: rejectReason.trim(),
          };

        const res = await dispatch(changeComplianceStatus({ id: id as string, payload })).unwrap();
        toast.success(res?.message ?? "Compliance status updated");
      } else {
        const payload: UpdateKitchenStatusPayload = {
          status,
          ...(status === "REJECTED" ? { reason: rejectReason.trim() } : {}),
        };

        const res = await dispatch(changeKitchenStatus({ id: id as string, payload })).unwrap();
        toast.success(res?.message ?? "Kitchen status updated");
      }

      dispatch(fetchKitchenById(id));
    } catch (e: any) {

      const errorMessage = e?.message || e?.response?.data?.message || (typeof e === 'string' ? e : "Failed to update status");
      toast.error(errorMessage);
      setConfirmOpen(false);
    }

  };

  const handleSaveStripeId = async () => {
    const value = stripeId.trim();

    if (!value) {
      setStripeError("Stripe Account ID is required");
      return;
    }

    const pattern = /^acct_[A-Za-z0-9]{16,}$/;
    if (!pattern.test(value)) {
      setStripeError("Invalid Stripe Account ID format");
      return;
    }

    try {
      const response = await updateKitchenStripeAccountId(id!, { stripeAccountId: value });
      toast.success(response?.message ?? "Stripe Account ID updated");
      setStripeOpen(false);
      setStripeError(null);
      dispatch(fetchKitchenById(id));
    } catch (e: any) {
      // console.error("DEBUG: updateKitchenStripeAccountId failed", e);
      const errorDetails = e?.details || e?.response?.data?.details;
      const errorMessage = e?.message || e?.response?.data?.message || (typeof e === 'string' ? e : "Failed to update Stripe ID");

      if (errorDetails) {
        toast.error("Stripe Update Error", {
          description: errorDetails.requirements || errorMessage || "Please check details.",
          action: {
            label: "Details",
            onClick: () => console.log(errorDetails)
          }
        });
      } else {
        toast.error(errorMessage);
        if (e.response?.status === 400) {
          setStripeError(errorMessage);
        }
      }
    }
  };

  const requestStatusChange = (status: "APPROVED" | "REJECTED", context: "KITCHEN" | "COMPLIANCE") => {
    if (!checkEdit(`You don't have permission to update ${context.toLowerCase()} status`)) {
      return;
    }
    setPendingStatus(status);
    setConfirmContext(context);
    if (status === "REJECTED") setRejectReason("");
    if (status === "APPROVED") {
      setExpireDate(undefined);
    }
    setConfirmOpen(true);
  };

  if ((!id && !loading) || loading || !kitchen) {
    return (
      <div className="space-y-8 p-1 animate-pulse">
        <div className="h-48 bg-zinc-100 dark:bg-zinc-800 rounded-3xl" />
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="h-64 bg-zinc-100 dark:bg-zinc-800 rounded-3xl" />
          <div className="h-64 bg-zinc-100 dark:bg-zinc-800 rounded-3xl" />
          <div className="h-64 bg-zinc-100 dark:bg-zinc-800 rounded-3xl" />
        </div>
      </div>
    );
  }

  const k: KitchenDetailsType = kitchen;
  const allImages = k.photos?.kitchenImages || [];

  return (
    <div className="p-1 space-y-10 max-w-[1400px] mx-auto animate-in fade-in slide-in-from-bottom-6 duration-1000 ease-out">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4 text-[10px] font-black uppercase tracking-[0.3em] text-zinc-400">
          <button onClick={handleBack} className="hover:text-primary transition-colors cursor-pointer capitalize">RESTAURANTS</button>
          <ChevronRight className="h-3 w-3" />
          <span className="text-primary truncate max-w-[200px] md:max-w-[300px]" title={k.kitchenName}>{k.kitchenName}</span>
        </div>
      </div>

      <div className="relative group perspective">
        <div className="absolute -inset-1 bg-gradient-to-r from-primary/30 via-indigo-500/10 to-primary/30 rounded-[2.5rem] blur-2xl opacity-20 group-hover:opacity-40 transition duration-1000" />
        <div className="relative overflow-hidden bg-white/70 dark:bg-zinc-900/80 backdrop-blur-3xl rounded-[2rem] border border-white/20 dark:border-zinc-800/50 shadow-2xl p-8 md:p-12">
          <div className="flex flex-col lg:flex-row lg:items-center gap-10">
            <div className="relative flex-shrink-0">
              <div className="absolute -inset-4 bg-gradient-to-tr from-primary to-indigo-500 rounded-full blur-3xl opacity-20 group-hover:opacity-40 transition-opacity duration-1000" />
              <div className="relative h-32 w-32 md:h-40 md:w-40 p-2 rounded-full border-2 border-primary/20 bg-background/50 backdrop-blur-md">
                <Avatar className="h-full w-full rounded-full border-4 border-background shadow-2xl">
                  <AvatarImage src={k.photos?.kitchenProfilePhoto} className="object-cover" />
                  <AvatarFallback className="text-4xl font-black bg-zinc-100 dark:bg-zinc-800">{k.kitchenName?.slice(0, 1)}</AvatarFallback>
                </Avatar>
                <div className="absolute -bottom-2 -right-2 p-3 bg-primary rounded-full shadow-2xl border-4 border-background text-white">
                  <Star className="h-5 w-5 fill-current" />
                </div>
              </div>
            </div>

            <div className="flex-1 space-y-6 min-w-0">
              <div className="space-y-2">
                <Badge
                  variant={k.status === "APPROVED" ? "default" : k.status === "REJECTED" ? "destructive" : "secondary"}
                  className={`font-black tracking-widest text-[10px] uppercase ${k.status === "APPROVED" ? "bg-green-500/10 text-green-700 border-green-500/20" :
                    k.status === "REJECTED" ? "bg-red-500/10 text-red-700 border-red-500/20" :
                      "bg-yellow-500/10 text-yellow-700 border-yellow-500/20"
                    }`}
                >
                  {k.status}
                </Badge>
                <h1 className="text-1xl md:text-2xl font-black tracking-tighter text-zinc-900 dark:text-white leading-tight line-clamp-2 break-words" title={k.kitchenName}>
                  {k.kitchenName}
                </h1>
                <a
                  href={`https://www.google.com/maps/search/?api=1&query=${k.address?.latitude},${k.address?.longitude}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="max-w-2xl text-zinc-500 dark:text-zinc-400 flex items-center gap-2 font-medium hover:text-primary transition-colors cursor-pointer w-fit"
                  title="Open in Google Maps"
                >
                  <MapPin className="h-4 w-4 text-primary" />
                  {k.address?.street}, {k.address?.city}
                </a>
              </div>

              <div className="flex flex-wrap items-center gap-8 text-sm pt-4 border-t border-zinc-100 dark:border-zinc-800/50">
                <div className="flex items-center gap-3">
                  <div className="p-3 bg-zinc-100 dark:bg-zinc-800 rounded-2xl">
                    <Clock className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <span className="block text-[10px] font-black uppercase text-zinc-400">Operating Hours</span>
                    <span className="font-bold">{k.openingTime} - {k.closingTime}</span>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <div className="p-3 bg-zinc-100 dark:bg-zinc-800 rounded-2xl">
                    <Star className="h-5 w-5 text-yellow-500 fill-yellow-500" />
                  </div>
                  <div>
                    <span className="block text-[10px] font-black uppercase text-zinc-400">Total Rating</span>
                    <span className="font-bold">{k.rating} <span className="text-zinc-400">({k.ratingCount} reviews)</span></span>
                  </div>
                </div>
              </div>
            </div>

            {hasEdit && (
              <div className="lg:w-50 flex flex-col gap-3">
                {k.status !== "APPROVED" && (

                  <Button
                    onClick={() => {
                      if (k.complianceStatus !== "APPROVED") {
                        toast.error("Please approve compliance documents first.");
                        return;
                      }
                      requestStatusChange("APPROVED", "KITCHEN");
                    }}
                    className="w-full bg-primary hover:bg-primary/90 text-white font-black uppercase tracking-widest py-6 rounded-2xl shadow-lg shadow-primary/20 transition-all hover:translate-y-[-2px]"
                  >
                    Confirm Approval
                  </Button>
                )}
                <Button
                  variant="outline"
                  onClick={() => requestStatusChange("REJECTED", "KITCHEN")}
                  className="w-full border-2 border-zinc-200 dark:border-zinc-800 hover:border-red-500/50 hover:bg-red-50 dark:hover:bg-red-900/10 hover:text-red-500 font-black uppercase tracking-widest py-6 rounded-2xl transition-all"
                >
                  Reject Entry
                </Button>

              </div>
            )}
          </div>
        </div>
      </div>

      <Tabs
        defaultValue="details"
        value={activeTab}
        onValueChange={(val) => {
          setSearchParams(prev => {
            prev.set("tab", val);
            return prev;
          }, { replace: true });
        }}
        className="w-full space-y-8"
      >
        <div className="flex items-center justify-start overflow-x-auto w-full pb-1">
          <TabsList className="bg-zinc-100 dark:bg-zinc-800/50 p-1 h-auto rounded-xl flex-shrink-0">
            <TabsTrigger
              value="details"
              className="rounded-lg px-6 py-2 text-xs font-black uppercase tracking-widest data-[state=active]:bg-white data-[state=active]:text-primary data-[state=active]:shadow-sm transition-all"
            >
              Details
            </TabsTrigger>
            {canViewLogs && (
              <TabsTrigger
                value="logs"
                className="rounded-lg px-6 py-2 text-xs font-black uppercase tracking-widest data-[state=active]:bg-white data-[state=active]:text-primary data-[state=active]:shadow-sm transition-all"
              >
                Audit Trail
              </TabsTrigger>
            )}
          </TabsList>
        </div>

        <TabsContent value="details" className="space-y-10 mt-0 animate-in fade-in slide-in-from-bottom-4 duration-500">
          <div className="grid grid-cols-1 md:grid-cols-12 auto-rows-min gap-6">
            <BentoCard title="Identity HUB" icon={Phone} className="md:col-span-4">
              <div className="space-y-1">
                <InfoRow label="Direct Mail" value={k.email} icon={Mail} />
                <InfoRow label="Proprietor" value={k.ownerName} icon={User} />
                <InfoRow label="Secure Line" value={k.contactNumber} icon={Phone} />
                <InfoRow label="Registered" value={moment(k.createdAt).format("DD/MM/YYYY")} icon={CalendarIcon} />
              </div>
            </BentoCard>

            <BentoCard title="Address" icon={MapPin} className="md:col-span-4">
              <a
                href={`https://www.google.com/maps/search/?api=1&query=${k.address?.latitude},${k.address?.longitude}`}
                target="_blank"
                rel="noopener noreferrer"
                className="space-y-1 block hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors rounded-xl p-2 -m-2 cursor-pointer group/address"
                title="Open in Google Maps"
              >
                <InfoRow label="Address Line1(Unit)" value={k.address?.houseNo} />
                <InfoRow label="Address Line2(Street)" value={k.address?.street} />
                <InfoRow label="Postcode/Pincode" value={k.address?.pincode} />
                <InfoRow label="City Hub" value={k.address?.city} />
              </a>
            </BentoCard>

            <BentoCard title="Compliance" icon={CheckCircle2} className="md:col-span-4" badge={k.complianceStatus === "APPROVED" ? "Verified" : "Pending"}>
              <div className="space-y-4">
                <div className="space-y-1">
                  <InfoRow label="ABN Number" value={k.kyc?.abnNumber || ""} />
                  <InfoRow label="ACN" value={k.kyc?.acn || ""} />
                  <InfoRow label="Certificate" value={k.kyc?.foodCertificateNumber || ""} />
                  {k.kyc?.expireDate && (
                    <InfoRow
                      label="Expire Date"
                      value={moment(k.kyc.expireDate).format("DD/MM/YYYY")}
                      icon={CalendarIcon}
                    />
                  )}
                </div>
                <Button
                  variant="outline"
                  onClick={() => setCertsOpen(true)}
                  className="w-full h-auto py-6 border-dashed border-2 border-zinc-200 dark:border-zinc-800 hover:border-primary/50 hover:bg-primary/5 transition-all group"
                >
                  <div className="flex flex-col items-center gap-2">
                    <FileText className="h-6 w-6 text-zinc-400 group-hover:text-primary transition-colors" />
                    <span className="text-[10px] font-black uppercase tracking-[0.2em] text-zinc-500 group-hover:text-primary">
                      View Certificates
                    </span>
                  </div>
                </Button>
              </div>
            </BentoCard>

            <BentoCard
              title="Payment config"
              icon={CreditCard}
              className="md:col-span-4"
            >
              <div className="space-y-4">
                <div className="space-y-1">
                  <InfoRow
                    label="Stripe ID"
                    value={k.stripeAccountId || "Not Configured"}
                    icon={CreditCard}
                  />
                  {k.stripeConnectedAt && (
                    <InfoRow
                      label="Linked At"
                      value={new Date(k.stripeConnectedAt).toLocaleDateString()}
                      icon={CalendarIcon}
                    />
                  )}
                </div>

                {hasEdit && (
                  <Button
                    variant="outline"
                    onClick={() => {
                      setStripeId(k.stripeAccountId || "");
                      setStripeError(null);
                      setStripeOpen(true);
                    }}
                    className="w-full h-auto py-6 border-dashed border-2 border-zinc-200 dark:border-zinc-800 hover:border-primary/50 hover:bg-primary/5 transition-all group"
                  >
                    <div className="flex flex-col items-center gap-2">
                      <CreditCard className="h-6 w-6 text-zinc-400 group-hover:text-primary transition-colors" />
                      <span className="text-[10px] font-black uppercase tracking-[0.2em] text-zinc-500 group-hover:text-primary">
                        {k.stripeAccountId ? "Update Configuration" : "Configure Stripe"}
                      </span>
                    </div>
                  </Button>
                )}
              </div>
            </BentoCard>

            <BentoCard title="Cuisines & Types" icon={Star} className="md:col-span-8" badge={`${k.cuisines?.length || 0} Selections`}>
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4 pt-2">
                {k.cuisines?.map((c) => (
                  <div
                    key={c.id}
                    className={`group/tag relative flex items-center justify-between gap-3 p-4 rounded-2xl border transition-all duration-300 ${c.isPopular
                      ? "bg-primary/5 border-primary/20 hover:border-primary/40"
                      : "bg-zinc-50 dark:bg-zinc-900 border-zinc-200/50 dark:border-zinc-800/50 hover:border-primary/40"
                      }`}
                  >
                    <div className="flex items-center gap-2">
                      <span className={`text-sm font-black tracking-tight ${c.isPopular ? "text-primary" : "text-zinc-700 dark:text-zinc-300"}`}>
                        {c.name}
                      </span>
                    </div>
                    {c.isPopular ? (
                      <div className="flex items-center gap-1 px-2 py-1 rounded-full bg-primary/10 text-primary border border-primary/20">
                        <Star className="h-3 w-3 fill-current" />
                        <span className="text-[9px] font-black uppercase tracking-wider">HOT</span>
                      </div>
                    ) : null}
                  </div>
                ))}
              </div>
            </BentoCard>
            <BentoCard title="Story" icon={FileText} className="md:col-span-12">
              <p className="text-zinc-500 dark:text-zinc-400 text-sm leading-relaxed font-medium">
                {k.description || "No mission description provided for this culinary hub."}
              </p>
            </BentoCard>
          </div>

          {/* <div className="space-y-6">
            <div className="flex items-center gap-4">
              <h2 className="text-sm font-black uppercase tracking-[0.4em] text-zinc-400">Premium Menu Selection</h2>
              <div className="h-[1px] flex-1 bg-zinc-100 dark:bg-zinc-800" />
            </div>

            <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
              {k.items?.map((item) => (
                <div
                  key={item.id}
                  className="group/item relative bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-2xl overflow-hidden shadow-sm hover:shadow-xl hover:border-primary/20 transition-all duration-500 transform hover:-translate-y-1"
                >
                  <div className="relative aspect-square overflow-hidden bg-zinc-50 dark:bg-zinc-950">
                    {item.image ? (
                      <img src={item.image} alt={item.name} className="h-full w-full object-cover group-hover/item:scale-110 transition-transform duration-700" />
                    ) : (
                      <div className="h-full w-full flex items-center justify-center text-zinc-200">
                        <UtensilsCrossed className="h-8 w-8" />
                      </div>
                    )}
                    <div className="absolute top-2 right-2">
                      <div className="bg-white/90 dark:bg-zinc-900/90 backdrop-blur-md px-2 py-1 rounded-lg border border-white/20 shadow-lg flex items-baseline gap-0.5">
                        <span className="text-[10px] font-black text-primary">${item.price}</span>
                      </div>
                    </div>
                    <div className="absolute bottom-2 left-2 flex gap-1">
                      {item.isVegetarian ? (
                        <div className="h-4 w-4 rounded-md bg-green-500 border border-white flex items-center justify-center shadow-lg">
                          <div className="h-1.5 w-1.5 rounded-full bg-white" />
                        </div>
                      ) : (
                        <div className="h-4 w-4 rounded-md bg-red-500 border border-white flex items-center justify-center shadow-lg">
                          <div className="h-1.5 w-1.5 rounded-full bg-white" />
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="p-3 space-y-2">
                    <div className="space-y-0.5">
                      <div className="flex items-center justify-between gap-1">
                        <h3 className="text-[11px] font-black tracking-tight line-clamp-1 break-words flex-1" title={item.name}>{item.name}</h3>
                        <div className="flex items-center gap-0.5 shrink-0">
                          <Star className="h-2 w-2 text-yellow-500 fill-current" />
                          <span className="text-[9px] font-black">{item.rating || "0.0"}</span>
                        </div>
                      </div>
                      <p className="text-[10px] text-zinc-500 dark:text-zinc-400 font-medium line-clamp-1 leading-tight break-words">{item.description}</p>
                    </div>

                    <div className="flex items-center justify-between pt-2 border-t border-zinc-100 dark:border-zinc-800/50">
                      <div className="flex flex-col">
                        <span className="text-[8px] font-black text-zinc-400 uppercase tracking-widest">Qty</span>
                        <span className="text-[9px] font-bold text-zinc-900 dark:text-zinc-100">{item.quantity}</span>
                      </div>
                      <div className="flex flex-col items-end">
                        <span className="text-[8px] font-black text-zinc-400 uppercase tracking-widest">Spice</span>
                        <span className={cn("text-[8px] font-black tracking-wider uppercase px-1 rounded",
                          item.isSpicy === 'HOT' ? "bg-red-500/10 text-red-500" :
                            item.isSpicy === 'NORMAL' ? "bg-orange-500/10 text-orange-500" : "bg-green-500/10 text-green-500")}>
                          {item.isSpicy}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}

              {(!k.items || k.items.length === 0) && (
                <div className="col-span-full py-20 flex flex-col items-center gap-4 bg-zinc-50/50 dark:bg-zinc-900/50 rounded-[3rem] border border-dashed border-zinc-200 dark:border-zinc-800">
                  <UtensilsCrossed className="h-12 w-12 text-zinc-200" />
                  <p className="text-xs font-black uppercase tracking-[0.2em] text-zinc-400">No Premium Selection Available</p>
                </div>
              )}
            </div>
          </div> */}

          <div className="space-y-6">
            <div className="flex items-center gap-4">
              <h2 className="text-sm font-black uppercase tracking-[0.4em] text-zinc-400">Kitchen Environment</h2>
              <div className="h-[1px] flex-1 bg-zinc-100 dark:bg-zinc-800" />
            </div>
            <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-4">
              {allImages.map((img, i) => (
                <button
                  key={i}
                  onClick={() => window.open(img, '_blank')}
                  className="group/img relative aspect-square overflow-hidden rounded-[1.5rem] border border-zinc-200 dark:border-zinc-800 shadow-sm hover:shadow-2xl transition-all duration-500"
                >
                  <img src={img} alt="" className="h-full w-full object-cover group-hover/img:scale-125 transition-transform duration-1000" />
                  <div className="absolute inset-0 bg-primary/20 opacity-0 group-hover/img:opacity-100 transition-opacity" />
                </button>
              ))}
            </div>
          </div>
        </TabsContent>

        {canViewLogs && (
          <TabsContent value="logs" className="mt-0 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <Card className="border-border/50 shadow-sm bg-card/50 backdrop-blur-xl">
              <CardHeader className="pb-3 px-6">
                <CardTitle className="text-lg flex items-center gap-2">
                  <FileText className="h-5 w-5 text-primary" />
                  Audit Trail History
                </CardTitle>
                <CardDescription>
                  A complete history of all status changes and updates for this culinary hub.
                </CardDescription>
              </CardHeader>
              <CardContent className="px-6 pb-6">
                <DynamicTable
                  columns={auditLogsColumns}
                  data={auditLogs || []}
                  loading={auditLogsLoading}
                  rowKey="id"
                  minWidth="1200px"
                  emptyMessage={
                    <div className="flex flex-col items-center gap-2 py-10 text-muted-foreground">
                      <Info className="h-10 w-10 opacity-20" />
                      <span className="text-xs font-bold uppercase tracking-widest">No audit logs found for this culinary hub.</span>
                    </div>
                  }
                />
                {auditLogsPagination && (
                  <div className="p-4 border-t border-zinc-100 dark:border-zinc-800/50 bg-zinc-50/30">
                    <Pagination
                      Pagination={{
                        page: logsPage,
                        totalCount: auditLogsPagination.totalRecords,
                        totalPages: auditLogsPagination.totalPages,
                        size: ITEMS_PER_PAGE,
                      }}
                      onPageChange={setLogsPage}
                    />
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>
        )}
      </Tabs>

      <Dialog open={certsOpen} onOpenChange={setCertsOpen}>
        <DialogContent className="max-w-4xl bg-zinc-50/95 dark:bg-zinc-900/95 backdrop-blur-xl border-zinc-200 dark:border-zinc-800 p-0 overflow-hidden rounded-[2rem] shadow-2xl">
          <DialogHeader className="p-6 border-b border-zinc-200/50 dark:border-zinc-800/50 bg-white/50 dark:bg-zinc-900/50">
            <DialogTitle className="text-xl font-black tracking-tighter flex items-center gap-3">
              <CheckCircle2 className="h-5 w-5 text-primary" />
              Compliance Documents
            </DialogTitle>
          </DialogHeader>
          <div className="p-6 max-h-[65vh] overflow-y-auto">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {k.kyc?.foodCertificateImage && (
                <div className="group relative break-inside-avoid">
                  <div className="relative aspect-[3/4] overflow-hidden rounded-2xl border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-950 shadow-sm hover:shadow-xl transition-all duration-500 cursor-pointer" onClick={() => setSelectedImage(k.kyc.foodCertificateImage)}>
                    <img
                      src={k.kyc.foodCertificateImage}
                      alt="Primary Decision"
                      className="h-full w-full object-cover group-hover:scale-110 transition-transform duration-700"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent opacity-80" />
                    <div className="absolute bottom-0 left-0 right-0 p-6 text-white">
                      <Badge className="bg-primary hover:bg-primary text-white border-none font-black tracking-widest mb-2">PRIMARY LICENSE</Badge>
                      <p className="text-xs font-medium text-white/80 line-clamp-2">Current Active Food License</p>
                    </div>
                  </div>
                </div>
              )}

              {k.kyc?.foodCertificateImages?.filter(cert => cert.image !== k.kyc?.foodCertificateImage).map((cert, idx) => (
                <div key={idx} className="group relative break-inside-avoid">
                  <div className="relative aspect-[3/4] overflow-hidden rounded-2xl border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-950 shadow-sm hover:shadow-xl transition-all duration-500 cursor-pointer" onClick={() => setSelectedImage(cert.image)}>
                    <img
                      src={cert.image}
                      alt={`Certificate ${idx + 1}`}
                      className="h-full w-full object-cover group-hover:scale-110 transition-transform duration-700"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent opacity-80" />
                    <div className="absolute bottom-0 left-0 right-0 p-6 text-white">
                      {moment(cert.expireDate).isBefore(moment()) ? (
                        <Badge className="bg-red-500 hover:bg-red-600 text-white border-none font-black tracking-widest mb-2 shadow-lg shadow-red-500/20">EXPIRED</Badge>
                      ) : (
                        <Badge variant="outline" className="border-white/20 text-white bg-white/10 backdrop-blur-md font-black tracking-widest mb-2">ARCHIVED</Badge>
                      )}
                      <div className="space-y-1">
                        <div className="flex justify-between text-[10px] font-bold uppercase tracking-wider text-white/60 border-b border-white/10 pb-1 mb-1">
                          <span>Expiry</span>
                          <span className="text-white">{moment(cert.expireDate).format("DD/MM/YYYY")}</span>
                        </div>
                        <div className="flex justify-between text-[10px] font-bold uppercase tracking-wider text-white/60">
                          <span>Added</span>
                          <span className="text-white">{moment(cert.addedAt).format("DD/MM/YYYY")}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              ))}

            </div>
          </div>
          {hasEdit && k.complianceStatus !== "APPROVED" && (
            <div className="p-4 sm:p-6 border-t border-zinc-200/50 dark:border-zinc-800/50 bg-white/50 dark:bg-zinc-900/50 flex flex-col sm:flex-row justify-end gap-3 rounded-b-[2rem]">
              <Button
                variant="outline"
                onClick={() => {
                  setCertsOpen(false);
                  requestStatusChange("REJECTED", "COMPLIANCE");
                }}
                className="w-full sm:w-auto min-w-[140px] border-2 border-red-200 dark:border-red-900/30 hover:border-red-500/50 hover:bg-red-50 dark:hover:bg-red-900/10 hover:text-red-500 font-bold tracking-widest uppercase transition-all"
              >
                Reject Documents
              </Button>
              <Button
                onClick={() => {
                  setCertsOpen(false);
                  requestStatusChange("APPROVED", "COMPLIANCE");
                }}
                className="w-full sm:w-auto min-w-[140px] bg-primary hover:bg-primary/90 text-white font-bold tracking-widest uppercase shadow-lg shadow-primary/20 transition-all"
              >
                Approve Application
              </Button>
            </div>
          )}
        </DialogContent>
      </Dialog>

      <Dialog open={!!selectedImage} onOpenChange={() => setSelectedImage(null)}>
        <DialogContent className="max-w-4xl bg-transparent border-none p-0 shadow-none overflow-hidden flex items-center justify-center">
          {selectedImage && (
            <img
              src={selectedImage}
              alt="Expanded Certificate"
              className="max-h-[85vh] w-auto object-contain rounded-lg shadow-2xl"
            />
          )}
        </DialogContent>
      </Dialog>

      <AlertDialog open={confirmOpen} onOpenChange={setConfirmOpen}>
        <AlertDialogContent className="max-w-md rounded-2xl p-0 overflow-hidden border-zinc-200 dark:border-zinc-800 shadow-xl">
          <div className="p-6 space-y-4">
            <div className="flex items-center gap-3">
              <div className={`p-2 rounded-lg ${pendingStatus === "APPROVED"
                ? "bg-primary/10 text-primary"
                : "bg-red-500/10 text-red-500"
                }`}>
                {pendingStatus === "APPROVED" ? (
                  <CheckCircle2 className="h-5 w-5" />
                ) : (
                  <Store className="h-5 w-5" />
                )}
              </div>
              <div className="space-y-0.5">
                <AlertDialogTitle className="text-lg font-bold tracking-tight">
                  {pendingStatus === "APPROVED"
                    ? `Approve ${confirmContext === "COMPLIANCE" ? "Compliance" : "Restaurant"}`
                    : `Reject ${confirmContext === "COMPLIANCE" ? "Compliance" : "Restaurant"}`}
                </AlertDialogTitle>
                <AlertDialogDescription className="text-xs font-medium">
                  {pendingStatus === "APPROVED"
                    ? confirmContext === "COMPLIANCE"
                      ? "Confirm the approval and set an expiration date."
                      : "Are you sure you want to approve this restaurant? It will become active immediately."
                    : "Specify the reason for rejecting this request."}
                </AlertDialogDescription>
              </div>
            </div>

            <div className="space-y-3">
              {pendingStatus === "APPROVED" && confirmContext === "COMPLIANCE" && (
                <div className="space-y-3">
                  {kitchen?.kyc?.expireDate && (
                    <div className="p-3 bg-zinc-100 dark:bg-zinc-800 rounded-lg border border-zinc-200 dark:border-zinc-700">
                      <span className="block text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-1">Current Recorded Expiry</span>
                      <span className="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                        {new Date(kitchen.kyc.expireDate).toLocaleDateString('en-US', {
                          year: 'numeric',
                          month: 'long',
                          day: 'numeric'
                        })}
                      </span>
                    </div>
                  )}

                  <div className={`p-4 border rounded-lg transition-colors ${validationError ? "bg-red-50 border-red-200" : "bg-primary/5 border-primary/20"}`}>
                    <div className="flex items-center justify-between">
                      <span className={`text-sm font-semibold ${validationError ? "text-red-600" : "text-muted-foreground"}`}>Selected Expiry:</span>
                      <span className={`text-sm font-bold ${validationError ? "text-red-700" : "text-primary"}`}>
                        {expireDate ? expireDate.toLocaleDateString('en-US', {
                          year: 'numeric',
                          month: 'long',
                          day: 'numeric'
                        }) : 'Not selected'}
                      </span>
                    </div>

                    {validationError && (
                      <p className="text-[10px] font-bold text-red-500 uppercase tracking-wider mt-2 animate-in fade-in slide-in-from-top-1">
                        {validationError}
                      </p>
                    )}
                  </div>

                  <div className="p-2 border border-zinc-100 dark:border-zinc-800 rounded-xl bg-zinc-50/30 dark:bg-zinc-900/30">
                    <Calendar
                      mode="single"
                      selected={expireDate}
                      onSelect={setExpireDate}
                      className="mx-auto"
                      captionLayout="dropdown"
                      fromYear={new Date().getFullYear()}
                      toYear={new Date().getFullYear() + 10}
                    />
                  </div>
                </div>
              )}

              {pendingStatus === "REJECTED" && (
                <Textarea
                  placeholder="Enter rejection reason..."
                  value={rejectReason}
                  onChange={(e) => setRejectReason(e.target.value)}
                  className="min-h-[100px] rounded-xl border-zinc-200 dark:border-zinc-800 focus:border-red-500/50 focus:ring-red-500/10 transition-all p-3 text-sm font-medium"
                />
              )}
            </div>

            <AlertDialogFooter className="gap-2 sm:gap-2">
              <Button
                variant="outline"
                onClick={() => setConfirmOpen(false)}
                className="flex-1 rounded-xl font-bold text-[10px] uppercase tracking-wider py-3 h-auto border-zinc-200 dark:border-zinc-800"
              >
                Cancel
              </Button>
              <Button
                onClick={async (e) => {
                  e.preventDefault();
                  if (pendingStatus === "APPROVED" && confirmContext === "COMPLIANCE" && !expireDate) {
                    setValidationError("Please select an expiry date to approve compliance");
                    return;
                  }

                  if (pendingStatus) await performStatusChange(pendingStatus);
                  setConfirmOpen(false);
                  setValidationError(null);
                }}
                disabled={loading || (pendingStatus === "REJECTED" && !rejectReason.trim())}
                className={`flex-1 rounded-xl font-bold text-[10px] uppercase tracking-wider py-3 h-auto ${pendingStatus === "APPROVED"
                  ? "bg-primary hover:bg-primary/90 text-white"
                  : "bg-red-500 hover:bg-red-600 text-white"
                  }`}
              >
                {loading ? "Processing..." : pendingStatus === "APPROVED" ? "Approve" : "Reject"}
              </Button>
            </AlertDialogFooter>
          </div>

        </AlertDialogContent>
      </AlertDialog>

      <Dialog open={stripeOpen} onOpenChange={setStripeOpen}>
        <DialogContent className="sm:max-w-[425px] rounded-2xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 shadow-2xl">
          <DialogHeader>
            <DialogTitle className="text-xl font-black tracking-tight">Update Stripe ID</DialogTitle>
            <DialogDescription className="text-zinc-500 dark:text-zinc-400">
              Enter the Stripe Connected Account ID for this kitchen to enable payouts.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="stripeId" className="text-xs font-black uppercase tracking-wider text-zinc-500">Stripe Account ID</Label>
              <Input
                id="stripeId"
                value={stripeId}
                onChange={(e) => {
                  setStripeId(e.target.value);
                  if (stripeError) setStripeError(null);
                }}
                placeholder="acct_..."
                className={`rounded-xl border-zinc-200 dark:border-zinc-800 focus:ring-primary/20 ${stripeError ? "border-red-500 focus:ring-red-500/20" : ""
                  }`}
              />
              {stripeError && (
                <p className="text-[10px] font-bold text-red-500 uppercase tracking-wider animate-in fade-in slide-in-from-top-1">
                  {stripeError}
                </p>
              )}
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setStripeOpen(false)} className="rounded-xl font-bold uppercase tracking-wider text-[10px]">Cancel</Button>
            <Button onClick={handleSaveStripeId} className="rounded-xl font-bold uppercase tracking-wider text-[10px] bg-primary text-white hover:bg-primary/90">Save Configuration</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

    </div >
  );
};

export default KitchenDetails;
