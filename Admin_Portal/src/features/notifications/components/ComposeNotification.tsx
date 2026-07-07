import { useForm, Controller } from "react-hook-form";
import { yupResolver } from "@hookform/resolvers/yup";
import * as yup from "yup";
import { useDispatch } from "react-redux";
import { Send, Users, User, Type, MessageSquare, Image as ImageIcon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { AppDispatch } from "@/store/store";
import { sendNotification } from "../notificationsSlice";
import { SendNotification } from "../types";
import { toast } from "sonner";

const notificationSchema = yup.object().shape({
    title: yup
        .string()
        .required("Title is required")
        .min(3, "Title must be at least 3 characters")
        .max(100, "Title must not exceed 100 characters"),
    message: yup
        .string()
        .required("Message is required")
        .min(10, "Message must be at least 10 characters")
        .max(500, "Message must not exceed 500 characters"),
    type: yup
        .string()
        .required("Please select a target audience")
        .oneOf(["USER", "KITCHEN"], "Invalid audience selection"),


});

type NotificationFormData = yup.InferType<typeof notificationSchema>;

export default function ComposeNotification() {
    const {
        register,
        handleSubmit,
        control,
        watch,
        reset,
        formState: { errors, isSubmitting },
    } = useForm<NotificationFormData>({
        resolver: yupResolver(notificationSchema),
        defaultValues: {
            title: "",
            message: "",
            type: ""
        }
    });

    const dispatch = useDispatch<AppDispatch>();

    const watchTitle = watch("title");
    const watchMessage = watch("message");

    const onSubmit = async (data: SendNotification) => {
        try {
            const res = await dispatch(sendNotification(data)).unwrap();
            if (res.status === 1) {
                toast.success(res?.message);
                reset();
            } else {
                const errorMessage = typeof res?.message === 'string'
                    ? res?.message
                    : "Failed to send notification";

                toast.error(errorMessage);
            }
        } catch (error: any) {
            toast.error(error?.message);
        }
    };

    return (
        <div className="w-full max-w-5xl mx-auto">
            <form onSubmit={handleSubmit(onSubmit)}>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                    <div className="md:col-span-2 space-y-6">
                        <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
                            <div className="h-1 w-full bg-primary/20"></div>
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2">
                                    <Send className="w-5 h-5 text-primary" />
                                    Compose Message
                                </CardTitle>
                                <CardDescription>
                                    Send a push notification to your users.
                                </CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-6">
                                <div className="space-y-2">
                                    <Label className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Target Audience</Label>
                                    <Controller
                                        name="type"
                                        control={control}
                                        render={({ field }) => (
                                            <Select onValueChange={field.onChange} value={field.value || ""}>
                                                <SelectTrigger className={`h-11 ${errors.type ? 'border-destructive' : ''}`}>
                                                    <SelectValue placeholder="Select Audience" />
                                                </SelectTrigger>
                                                <SelectContent>
                                                    <SelectItem value="USER">
                                                        <div className="flex items-center gap-2">
                                                            <Users className="w-4 h-4 text-primary" />
                                                            <span>Users</span>
                                                        </div>
                                                    </SelectItem>
                                                    <SelectItem value="KITCHEN">
                                                        <div className="flex items-center gap-2">
                                                            <User className="w-4 h-4 text-primary" />
                                                            <span>Restaurants</span>
                                                        </div>
                                                    </SelectItem>
                                                </SelectContent>
                                            </Select>
                                        )}
                                    />
                                    {errors.type && (
                                        <p className="text-xs text-destructive mt-1">{errors.type.message}</p>
                                    )}
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="title" className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Title</Label>
                                    <div className="relative">
                                        <Type className="absolute left-3 top-3.5 w-4 h-4 text-muted-foreground" />
                                        <Input
                                            id="title"
                                            placeholder="e.g., Weekend Sale Alert!"
                                            {...register("title")}
                                            className={`pl-10 h-11 ${errors.title ? 'border-destructive' : ''}`}
                                        />
                                    </div>
                                    {errors.title && (
                                        <p className="text-xs text-destructive mt-1">{errors.title.message}</p>
                                    )}
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="message" className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Message Body</Label>
                                    <div className="relative">
                                        <Textarea
                                            id="message"
                                            placeholder="Type your message here..."
                                            {...register("message")}
                                            className={`min-h-[140px] resize-none p-4 leading-relaxed ${errors.message ? 'border-destructive' : ''}`}
                                        />
                                        <MessageSquare className="absolute right-3 top-3 w-4 h-4 text-muted-foreground" />
                                    </div>
                                    {errors.message && (
                                        <p className="text-xs text-destructive mt-1">{errors.message.message}</p>
                                    )}
                                </div>
                                <div className="flex items-center justify-end pt-4">
                                    <Button
                                        type="submit"
                                        disabled={isSubmitting}
                                        className="min-w-[140px] h-11"
                                    >
                                        {isSubmitting ? (
                                            <span className="flex items-center gap-2">
                                                <div className="w-4 h-4 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                                                Sending...
                                            </span>
                                        ) : (
                                            <span className="flex items-center gap-2">
                                                Send Notification
                                                <Send className="w-4 h-4" />
                                            </span>
                                        )}
                                    </Button>
                                </div>
                            </CardContent>
                        </Card>
                    </div>

                    <div className="md:col-span-1 hidden md:block">
                        <div className="sticky top-6 space-y-4">
                            <Label className="text-xs font-semibold uppercase tracking-wider text-muted-foreground block text-center">Live Preview</Label>

                            <div className="border-[8px] border-gray-900 rounded-[2rem] overflow-hidden shadow-xl bg-white aspect-[9/19.5] relative max-w-[280px] mx-auto ring-1 ring-gray-900/5">

                                <div className="bg-gray-100 h-6 flex items-center justify-between px-4 text-[10px] font-medium text-gray-500">
                                    <span>9:41</span>
                                    <div className="flex gap-1">
                                        <div className="w-3 h-3 bg-gray-300 rounded-full" />
                                        <div className="w-3 h-3 bg-gray-300 rounded-full" />
                                    </div>
                                </div>

                                <div className="bg-gray-50/50 w-full h-full relative p-4 space-y-4">
                                    <div className="w-full h-32 bg-gray-100 rounded-xl animate-pulse" />
                                    <div className="space-y-2">
                                        <div className="w-3/4 h-4 bg-gray-100 rounded animate-pulse" />
                                        <div className="w-1/2 h-4 bg-gray-100 rounded animate-pulse" />
                                    </div>

                                    <div className="absolute top-4 left-4 right-4 bg-white/90 backdrop-blur-md rounded-2xl p-4 shadow-xl border border-white/50 animate-in slide-in-from-top-4 duration-700 z-10 transition-all">
                                        <div className="flex gap-3">
                                            <div className="w-10 h-10 rounded-full bg-primary flex items-center justify-center shrink-0 shadow-lg">
                                                <ImageIcon className="w-5 h-5 text-primary-foreground" />
                                            </div>
                                            <div className="flex-1 min-w-0">
                                                <div className="flex items-center justify-between mb-0.5">
                                                    <h4 className="text-sm font-bold text-gray-900">ResQBox</h4>
                                                    <span className="text-[10px] text-gray-400">now</span>
                                                </div>
                                                <p className="text-sm font-medium text-gray-800 truncate">
                                                    {watchTitle || "Notification Title"}
                                                </p>
                                                <p className="text-xs text-gray-500 leading-snug line-clamp-2 mt-0.5 break-words">
                                                    {watchMessage || "Your notification message will appear here..."}
                                                </p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <p className="text-center text-xs text-muted-foreground">Preview of how it appears on user's device</p>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    );
}
