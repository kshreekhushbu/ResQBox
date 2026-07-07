import { useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "@/store/store";
import { fetchOrderDetails, clearSelectedOrder } from "../ordersSlice";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ArrowLeft, MapPin, Phone, User, Store, Calendar, CreditCard, Receipt, Clock, ChevronRight } from "lucide-react";
import { format } from "date-fns";
import { OrderStatus } from "../types";
import { Separator } from "@/components/ui/separator";

const InfoRow = ({
    label,
    value,
    icon: Icon,
}: {
    label: string;
    value: React.ReactNode;
    icon?: React.ElementType;
}) => (

    <div className="group flex items-center justify-between py-3 border-b border-primary/5 last:border-b-0 hover:bg-primary/[0.02] transition-colors px-1 -mx-1 rounded-lg">
        <div className="flex items-center gap-3">
            <div className="p-1.5 rounded-md bg-primary/5 text-primary group-hover:bg-primary group-hover:text-primary-foreground transition-all duration-300">
                {Icon && <Icon className="h-3.5 w-3.5" />}
            </div>
            <span className="text-xs font-semibold text-muted-foreground/80">{label}</span>
        </div>
        <span className="font-bold text-sm text-foreground text-right truncate max-w-[60%]">{value}</span>
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
                <CardTitle className="text-xs font-bold flex items-center gap-2.5 text-zinc-500 group-hover:text-primary transition-colors">
                    {Icon && <Icon className="h-3.5 w-3.5" />}
                    {title}
                </CardTitle>
                {badge && (
                    <Badge variant="outline" className="text-[10px] font-semibold tracking-wide border-primary/20 bg-primary/5">
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

export default function OrderDetails() {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const dispatch = useDispatch<AppDispatch>();
    const { selectedOrder, loading, error } = useSelector(
        (state: RootState) => state.orders
    );

    useEffect(() => {
        if (id) {
            dispatch(fetchOrderDetails(id));
        }
        return () => {
            dispatch(clearSelectedOrder());
        };
    }, [dispatch, id]);

    if (loading && !selectedOrder) {
        return (
            <div className="space-y-8 p-1 animate-pulse max-w-[1400px] mx-auto pt-10 px-4">
                <div className="h-48 bg-zinc-100 dark:bg-zinc-800 rounded-[2rem]" />
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div className="h-64 bg-zinc-100 dark:bg-zinc-800 rounded-[2rem]" />
                    <div className="h-64 bg-zinc-100 dark:bg-zinc-800 rounded-[2rem]" />
                    <div className="h-64 bg-zinc-100 dark:bg-zinc-800 rounded-[2rem]" />
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="min-h-screen bg-background flex items-center justify-center p-6">
                <div className="max-w-md w-full text-center space-y-6 bg-white/50 dark:bg-zinc-900/50 backdrop-blur-3xl border border-zinc-200/50 dark:border-zinc-800/50 p-12 rounded-[2.5rem] shadow-2xl">
                    <div className="w-20 h-20 bg-red-50 dark:bg-red-900/10 rounded-full flex items-center justify-center mx-auto">
                        <ArrowLeft className="h-10 w-10 text-red-500" />
                    </div>
                    <div className="space-y-2">
                        <h2 className="text-2xl font-black tracking-tighter text-zinc-900 dark:text-white">Execution Error</h2>
                        <p className="text-zinc-500 dark:text-zinc-400 font-medium">{error}</p>
                    </div>
                    <Button
                        onClick={() => navigate(-1)}
                        className="w-full bg-zinc-900 dark:bg-white text-white dark:text-black font-black uppercase tracking-widest py-6 rounded-2xl transition-all hover:scale-[1.02]"
                    >
                        Return to List
                    </Button>
                </div>
            </div>
        );
    }

    if (!selectedOrder) return null;
    const getStatusVariant = (status: OrderStatus) => {
        switch (status) {
            case OrderStatus.PENDING: return "secondary";
            case OrderStatus.ACCEPTED: return "default";
            case OrderStatus.PREPARING: return "default";
            case OrderStatus.READY: return "default";
            case OrderStatus.PICKED: return "default";
            case OrderStatus.CANCELLED:
            case OrderStatus.REJECTED: return "destructive";
            default: return "outline";
        }
    };

    return (
        <div className="p-1 space-y-10 max-w-[1400px] mx-auto animate-in fade-in slide-in-from-bottom-6 duration-1000 ease-out">
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-4 text-xs font-semibold text-zinc-400">
                    <button onClick={() => navigate(-1)} className="hover:text-primary transition-colors cursor-pointer">Orders</button>
                    <ChevronRight className="h-3 w-3" />
                    <span className="text-primary">#{selectedOrder?.orderDisplayId}</span>
                </div>
            </div>

            <div className="relative group perspective">
                <div className="absolute -inset-1 bg-gradient-to-r from-primary/30 via-indigo-500/10 to-primary/30 rounded-[2.5rem] blur-2xl opacity-20 group-hover:opacity-40 transition duration-1000" />
                <div className="relative overflow-hidden bg-white/70 dark:bg-zinc-900/80 backdrop-blur-3xl rounded-[2rem] border border-white/20 dark:border-zinc-800/50 shadow-2xl p-8 md:p-12">
                    <div className="flex flex-col lg:flex-row lg:items-center gap-10">
                        <div className="relative flex-shrink-0">
                            <div className="absolute -inset-4 bg-gradient-to-tr from-primary to-indigo-500 rounded-full blur-3xl opacity-20 group-hover:opacity-40 transition-opacity duration-1000" />
                            <div className="relative h-32 w-32 md:h-40 md:w-40 flex items-center justify-center rounded-full border-2 border-primary/20 bg-background/50 backdrop-blur-md">
                                <div className="text-center">
                                    <span className="block text-[10px] font-black uppercase tracking-widest text-zinc-400 mb-1">TOTAL</span>
                                    <span className="text-2xl md:text-3xl font-black tracking-tighter text-primary">${selectedOrder.totalAmount.toFixed(0)}</span>
                                </div>
                                <div className="absolute -bottom-2 -right-2 p-3 bg-primary rounded-full shadow-2xl border-4 border-background text-white">
                                    <Receipt className="h-5 w-5" />
                                </div>
                            </div>
                        </div>

                        <div className="flex-1 space-y-6">
                            <div className="space-y-2">
                                <Badge variant={getStatusVariant(selectedOrder?.status)} className="font-bold tracking-wide text-[10px] px-4 py-1">
                                    {selectedOrder?.status}
                                </Badge>
                                <h1 className="text-1xl md:text-2xl font-black tracking-tighter text-zinc-900 dark:text-white leading-none">
                                    #{selectedOrder?.orderDisplayId}
                                </h1>
                                <p className="max-w-2xl text-zinc-500 dark:text-zinc-400 flex items-center gap-2 font-medium">
                                    <Calendar className="h-4 w-4 text-primary" />
                                    {format(new Date(selectedOrder?.orderedAt), "MMMM dd, yyyy 'at' hh:mm a")}
                                </p>
                            </div>

                            <div className="flex flex-wrap items-center gap-8 text-sm pt-4 border-t border-zinc-100 dark:border-zinc-800/50">
                                {selectedOrder?.user && (
                                    <div className="flex items-center gap-3">
                                        <div className="p-3 bg-zinc-100 dark:bg-zinc-800 rounded-2xl">
                                            <User className="h-5 w-5 text-primary" />
                                        </div>
                                        <div>
                                            <span className="block text-[10px] font-bold text-zinc-400">Customer</span>
                                            <span className="font-bold text-base">{selectedOrder?.user?.name}</span>
                                        </div>
                                    </div>
                                )}
                                <div className="flex items-center gap-3">
                                    <div className="p-3 bg-zinc-100 dark:bg-zinc-800 rounded-2xl">
                                        <CreditCard className="h-5 w-5 text-primary" />
                                    </div>
                                    <div>
                                        <span className="block text-[10px] font-bold text-zinc-400">Payment</span>
                                        <span className="font-bold text-base">{selectedOrder?.paymentMethod}</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="lg:w-64 bg-primary/5 rounded-[2rem] p-6 border border-primary/10 flex flex-col justify-center gap-4">
                            <div className="text-center">
                                <span className="block text-[10px] font-bold tracking-wide text-primary/60 mb-1">Pickup Identity</span>
                                <span className="text-1xl font-black tracking-[0.2em] text-zinc-900 dark:text-white">{selectedOrder.pickupId}</span>
                            </div>
                            <Separator className="bg-primary/10" />
                            <div className="text-center">
                                <span className="block text-[10px] font-bold tracking-wide text-primary/60 mb-1">Items</span>
                                <span className="text-small font-medium">{selectedOrder?.items?.length} Units</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-12 auto-rows-min gap-6 px-4 md:px-0">
                <BentoCard title={selectedOrder.user ? "Client Node" : "Order Identifier"} icon={User} className="md:col-span-4">
                    <div className="space-y-1">
                        {!selectedOrder.user && (
                            <InfoRow label="Order ID" value={selectedOrder?.orderDisplayId} icon={Receipt} />
                        )}
                        {selectedOrder.user?.name && (
                            <InfoRow label="Name" value={selectedOrder.user?.name} icon={User} />
                        )}
                        {selectedOrder.user?.phoneNumber && (
                            <InfoRow label="Phone" value={selectedOrder.user.phoneNumber} icon={Phone} />
                        )}
                        <InfoRow label="Status" value={selectedOrder.paymentStatus} icon={CreditCard} />
                        <InfoRow label="Order Time" value={format(new Date(selectedOrder.orderedAt), "hh:mm a")} icon={Receipt} />
                    </div>
                </BentoCard>

                <BentoCard title="Kitchen Source" icon={Store} className="md:col-span-4">
                    <div className="space-y-4">
                        <div className="flex items-center gap-4">
                            <div className="h-16 w-16 rounded-2xl overflow-hidden border-2 border-primary/10 flex-shrink-0">
                                <img src={selectedOrder.kitchen?.kitchenImage || "/placeholder.png"} className="h-full w-full object-cover" alt="" />
                            </div>
                            <div className="min-w-0">
                                <h4 className="font-bold text-sm tracking-tight line-clamp-2 break-words leading-tight">{selectedOrder.kitchen?.kitchenName}</h4>
                                <p className="text-xs text-zinc-500 font-medium mt-0.5">Verified Kitchen Hub</p>
                            </div>
                        </div>
                        <div className="space-y-1 pt-2 border-t border-zinc-50 dark:border-zinc-800/50">
                            <div className="space-y-3">
                                <div className="flex items-start justify-between gap-2">
                                    <span className="text-xs font-semibold text-muted-foreground/80 shrink-0 mt-0.5">Location</span>
                                    <div className="text-right space-y-1">
                                        <p className="text-sm font-bold text-foreground leading-snug">
                                            {[
                                                selectedOrder.kitchen?.address?.houseNo,
                                                selectedOrder.kitchen?.address?.street,
                                                selectedOrder.kitchen?.address?.landmark,
                                            ].filter(Boolean).join(", ")}
                                        </p>
                                        <p className="text-xs text-muted-foreground">
                                            {[
                                                selectedOrder.kitchen?.address?.city,
                                                selectedOrder.kitchen?.address?.state,
                                                selectedOrder.kitchen?.address?.country,
                                                selectedOrder.kitchen?.address?.pincode
                                            ].filter(Boolean).join(", ")}
                                        </p>
                                    </div>
                                </div>

                                {selectedOrder.kitchen?.address?.latitude && selectedOrder.kitchen?.address?.longitude && (
                                    <a
                                        href={`https://www.google.com/maps/search/?api=1&query=${selectedOrder.kitchen.address.latitude},${selectedOrder.kitchen.address.longitude}`}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="flex items-center justify-center gap-2 w-full py-2 bg-primary/5 hover:bg-primary/10 text-primary rounded-lg transition-colors text-xs font-bold"
                                    >
                                        <MapPin className="h-3.5 w-3.5" />
                                        View on Map
                                    </a>
                                )}
                            </div>
                        </div>
                    </div>
                </BentoCard>

                <BentoCard title="Invoice Analytics" icon={Receipt} className="md:col-span-4">
                    <div className="space-y-1">
                        <InfoRow label="Net Value (inc. of GST)" value={`$${selectedOrder.itemTotal.toFixed(2)}`} />
                        <InfoRow label="Platform Fee" value={`$${selectedOrder.platformFee.toFixed(2)}`} />
                        <div className="flex justify-between items-center py-3 mt-2 border-t-2 border-primary/20 bg-primary/5 -mx-4 px-4 rounded-xl">
                            <span className="text-xs font-bold text-primary">Total</span>
                            <span className="text-xl font-black text-primary">${selectedOrder.totalAmount.toFixed(2)}</span>
                        </div>
                    </div>
                </BentoCard>

                <div className="md:col-span-12 space-y-6 pt-6">
                    <div className="flex items-center gap-4">
                        <h2 className="text-xs font-bold text-zinc-400">Items</h2>
                        <div className="h-[1px] flex-1 bg-zinc-100 dark:bg-zinc-800" />
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                        {selectedOrder.items.map((item) => (
                            <div
                                key={item.menuItemId}
                                className="group/item relative bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-3xl overflow-hidden shadow-sm hover:shadow-2xl hover:border-primary/20 transition-all duration-500 transform hover:-translate-y-2"
                            >
                                <div className="relative aspect-video overflow-hidden bg-zinc-50 dark:bg-zinc-950">
                                    <img src={item.image || "/placeholder.png"} alt={item.name} className="h-full w-full object-cover group-hover/item:scale-110 transition-transform duration-1000 ease-out" />
                                    <div className="absolute bottom-4 left-4">
                                        <Badge className="bg-primary text-white border-none font-bold text-[10px]">Qty: {item.quantity}</Badge>
                                    </div>
                                </div>
                                <div className="p-5 space-y-2 flex-grow">
                                    <h3 className="text-base font-bold tracking-tight line-clamp-2 break-words leading-snug h-[2.8rem]">{item.name}</h3>
                                    <div className="flex items-center gap-2 text-[11px] text-zinc-400 font-medium">
                                        <Clock className="h-3 w-3" />
                                        <span className="truncate">Period: {item.startTime} - {item.endTime}</span>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}
