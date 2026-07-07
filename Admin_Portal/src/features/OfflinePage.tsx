import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { WifiOff, RefreshCw } from 'lucide-react';

export function OfflinePage() {
    const navigate = useNavigate();

    const handleRefresh = () => {
        window.location.reload();
    };

    const handleGoHome = () => {
        navigate('/');
    };

    return (
        <section className="fixed inset-0 z-[9999] bg-background min-h-screen flex items-center justify-center p-4">
            <div className="container mx-auto">
                <div className="flex justify-center">
                    <div className="w-full sm:w-10/12 md:w-8/12 text-center">
                        {/* Animated Offline Icon */}
                        <div className="flex justify-center mb-8">
                            <div className="relative">
                                <div className="absolute inset-0 bg-destructive/20 blur-3xl rounded-full animate-pulse" />
                                <div className="relative bg-gradient-to-br from-destructive/10 to-destructive/5 p-12 rounded-full border-2 border-destructive/20">
                                    <WifiOff className="h-32 w-32 text-destructive animate-pulse" strokeWidth={1.5} />
                                </div>
                            </div>
                        </div>

                        {/* Error Message */}
                        <div className="space-y-4">
                            <h1 className="text-6xl sm:text-7xl md:text-8xl font-bold bg-gradient-to-r from-destructive via-destructive/80 to-orange-500 bg-clip-text text-transparent">
                                Offline
                            </h1>

                            <h3 className="text-2xl sm:text-3xl font-bold text-foreground mb-4">
                                No Internet Connection
                            </h3>

                            <p className="text-lg text-muted-foreground mb-6 max-w-md mx-auto">
                                It looks like you've lost your internet connection. Please check your network and try again.
                            </p>

                            {/* Action Buttons */}
                            <div className="flex flex-col sm:flex-row gap-3 justify-center pt-4">
                                <Button
                                    variant="default"
                                    onClick={handleRefresh}
                                    className="gap-2 bg-destructive hover:bg-destructive/90"
                                    size="lg"
                                >
                                    <RefreshCw className="h-4 w-4" />
                                    Retry Connection
                                </Button>

                                <Button
                                    variant="outline"
                                    onClick={handleGoHome}
                                    className="gap-2 border-destructive/30 hover:bg-destructive/10"
                                    size="lg"
                                >
                                    Go to Home
                                </Button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    );
}

export default OfflinePage;
