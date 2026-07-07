import { useState } from "react";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

interface DashboardSkeletonProps {
    showCharts?: boolean;
}

export function DashboardSkeleton({ showCharts = true }: DashboardSkeletonProps) {
    return (
        <div className="space-y-6 animate-in fade-in duration-500">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
                {[...Array(6)].map((_, i) => (
                    <Card key={i} className="border bg-gradient-to-br from-muted/50 to-transparent">
                        <CardContent className="p-6">
                            <div className="flex items-start justify-between">
                                <div className="space-y-3 flex-1">
                                    <Skeleton className="h-4 w-24" />
                                    <Skeleton className="h-8 w-20" />
                                    <Skeleton className="h-3 w-16" />
                                </div>
                                <Skeleton className="h-12 w-12 rounded-xl" />
                            </div>
                        </CardContent>
                    </Card>
                ))}
            </div>

            {showCharts && (
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    {[...Array(2)].map((_, i) => (
                        <Card key={i}>
                            <CardHeader>
                                <div className="flex items-center justify-between">
                                    <Skeleton className="h-6 w-32" />
                                    <Skeleton className="h-9 w-24" />
                                </div>
                            </CardHeader>
                            <CardContent>
                                <Skeleton className="h-[300px] w-full" />
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <Card>
                    <CardHeader>
                        <Skeleton className="h-6 w-32" />
                    </CardHeader>
                    <CardContent className="space-y-3">
                        {[...Array(4)].map((_, i) => (
                            <Skeleton key={i} className="h-12 w-full" />
                        ))}
                    </CardContent>
                </Card>

                <div className="lg:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-4">
                    {[...Array(2)].map((_, i) => (
                        <Card key={i} className="border">
                            <CardContent className="p-6 space-y-3">
                                <Skeleton className="h-5 w-32" />
                                <Skeleton className="h-10 w-24" />
                                <Skeleton className="h-4 w-28" />
                            </CardContent>
                        </Card>
                    ))}
                </div>
            </div>
        </div>
    );
}

export function WelcomeHeader({ loading = false }: { loading?: boolean }) {
    const [currentTime, setCurrentTime] = useState(new Date());

    useState(() => {
        const timer = setInterval(() => setCurrentTime(new Date()), 1000);
        return () => clearInterval(timer);
    });

    const getUserName = () => {
        try {
            const adminData = localStorage.getItem("admindata");
            if (adminData) {
                const userData = JSON.parse(adminData);
                return userData.name || userData.fullName || userData.username || "Admin";
            }
        } catch (error) {
            console.error("Error parsing admin data:", error);
        }
        return "Admin";
    };

    if (loading) {
        return (
            <div className="mb-6 space-y-2">
                <Skeleton className="h-8 w-64" />
                <Skeleton className="h-4 w-48" />
            </div>
        );
    }

    const greeting = () => {
        const hour = currentTime.getHours();
        if (hour < 12) return "Good Morning";
        if (hour < 18) return "Good Afternoon";
        return "Good Evening";
    };

    const userName = getUserName();

    return (
        <div className="mb-8 space-y-1">
            <h1 className="text-2xl font-black tracking-tight text-black flex items-center gap-3">
                {greeting()}, {userName} <span className="inline-block animate-bounce-gentle">👋</span>
            </h1>
            <p className="text-muted-foreground">
                {currentTime.toLocaleDateString('en-US', {
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                })}
            </p>
        </div>
    );
}
