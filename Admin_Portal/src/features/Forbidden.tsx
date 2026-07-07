import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { ShieldX, Home, ArrowLeft, ChevronDown, Lock } from 'lucide-react';
import { MatrixRain } from '@/components/effects/MatrixRain';
import { FuzzyText } from '@/components/effects/FuzzyText';

const Forbidden: React.FC = () => {
    const navigate = useNavigate();
    const [showDetails, setShowDetails] = useState(false);
    const [matrixSpeed, setMatrixSpeed] = useState(0.8);

    useEffect(() => {
        const interval = setInterval(() => {
            setMatrixSpeed((prev) => (prev === 0.8 ? 1.2 : 0.8));
        }, 3000);
        return () => clearInterval(interval);
    }, []);

    const handleGoHome = () => {
        navigate('/');
    };

    const handleGoBack = () => {
        navigate(-1);
    };

    return (
        <div className="relative min-h-screen w-full overflow-hidden bg-black">
            <MatrixRain
                fontSize={16}
                color="#ef4444"
                characters="01403FORBIDDEN"
                fadeOpacity={0.08}
                speed={matrixSpeed}
            />

            <div className="relative z-10 flex min-h-screen items-center justify-center p-4">
                <Card className="w-full max-w-2xl border-destructive/20 bg-background/95 backdrop-blur-sm shadow-2xl">
                    <div className="p-8 space-y-8">
                        <div className="flex flex-col items-center space-y-6">
                            <div className="relative">
                                <div className="absolute inset-0 animate-pulse bg-destructive/20 blur-3xl rounded-full" />
                                <div className="relative">
                                    <ShieldX className="h-20 w-20 text-destructive animate-pulse" />
                                    <Lock className="absolute -bottom-1 -right-1 h-8 w-8 text-destructive/80 animate-bounce" />
                                </div>
                            </div>

                            <div className="flex flex-col items-center space-y-4">
                                <FuzzyText
                                    fontSize="4rem"
                                    fontWeight={900}
                                    baseIntensity={0.15}
                                    hoverIntensity={0.4}
                                    enableHover={true}
                                    className="text-center"
                                >
                                    403
                                </FuzzyText>

                                <div className="text-center space-y-2">
                                    <h2 className="text-2xl font-bold text-foreground">
                                        Access Forbidden
                                    </h2>
                                    <p className="text-muted-foreground max-w-md">
                                        You don't have permission to access this resource. Please contact your administrator if you believe this is an error.
                                    </p>
                                </div>
                            </div>
                        </div>

                        <div className="space-y-4">
                            <div className="flex flex-col sm:flex-row gap-3 justify-center">
                                <Button
                                    onClick={handleGoBack}
                                    className="gap-2 bg-destructive hover:bg-destructive/90 transition-all duration-300"
                                    size="lg"
                                >
                                    <ArrowLeft className="h-4 w-4" />
                                    Go Back
                                </Button>
                                <Button
                                    onClick={handleGoHome}
                                    variant="outline"
                                    className="gap-2 border-destructive/30 hover:bg-destructive/10 transition-all duration-300"
                                    size="lg"
                                >
                                    <Home className="h-4 w-4" />
                                    Back to Dashboard
                                </Button>
                            </div>

                            <div className="border-t border-border pt-4">
                                <button
                                    onClick={() => setShowDetails(!showDetails)}
                                    className="flex items-center justify-center gap-2 w-full text-sm text-muted-foreground hover:text-foreground transition-colors"
                                >
                                    <span>Permission Details</span>
                                    <ChevronDown
                                        className={`h-4 w-4 transition-transform duration-300 ${showDetails ? 'rotate-180' : ''
                                            }`}
                                    />
                                </button>

                                {showDetails && (
                                    <div className="mt-4 p-4 bg-muted/50 rounded-lg border border-border">
                                        <div className="space-y-2">
                                            <div className="flex items-start gap-2">
                                                <span className="text-xs font-mono text-destructive font-semibold">
                                                    Status Code:
                                                </span>
                                                <span className="text-xs font-mono text-foreground flex-1">
                                                    403 - Forbidden
                                                </span>
                                            </div>
                                            <div className="flex items-start gap-2">
                                                <span className="text-xs font-mono text-muted-foreground font-semibold">
                                                    Reason:
                                                </span>
                                                <span className="text-xs font-mono text-foreground flex-1">
                                                    Insufficient permissions to access this resource
                                                </span>
                                            </div>
                                            <div className="flex items-start gap-2">
                                                <span className="text-xs font-mono text-muted-foreground font-semibold">
                                                    Path:
                                                </span>
                                                <span className="text-xs font-mono text-foreground flex-1">
                                                    {window.location.pathname}
                                                </span>
                                            </div>
                                            <div className="flex items-center gap-2 pt-2 border-t border-border">
                                                <span className="text-xs font-mono text-muted-foreground">
                                                    Timestamp:
                                                </span>
                                                <span className="text-xs font-mono text-foreground">
                                                    {new Date().toISOString()}
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                )}
                            </div>
                        </div>

                        <div className="flex justify-center">
                            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-destructive/10 border border-destructive/20">
                                <div className="h-2 w-2 rounded-full bg-destructive animate-pulse" />
                                <span className="text-xs font-mono text-destructive">
                                    Access Denied
                                </span>
                            </div>
                        </div>
                    </div>
                </Card>
            </div>
        </div>
    );
};

export default Forbidden;
