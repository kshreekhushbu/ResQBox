import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { AlertTriangle, Home, RefreshCw, ChevronDown } from 'lucide-react';
import { MatrixRain } from '@/components/effects/MatrixRain';
import { FuzzyText } from '@/components/effects/FuzzyText';

const NotFound: React.FC = () => {
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
        color="#10b981"
        characters="01404NOTFOUND"
        fadeOpacity={0.08}
        speed={matrixSpeed}
      />

      <div className="relative z-10 flex min-h-screen items-center justify-center p-4">
        <Card className="w-full max-w-2xl border-primary/20 bg-background/95 backdrop-blur-sm shadow-2xl">
          <div className="p-8 space-y-8">
            <div className="flex flex-col items-center space-y-6">
              <div className="relative">
                <div className="absolute inset-0 animate-pulse bg-primary/20 blur-3xl rounded-full" />
                <AlertTriangle className="relative h-20 w-20 text-primary animate-pulse" />
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
                  404
                </FuzzyText>

                <div className="text-center space-y-2">
                  <h2 className="text-2xl font-bold text-foreground">
                    Page Not Found
                  </h2>
                  <p className="text-muted-foreground max-w-md">
                    The page you're looking for doesn't exist or has been moved. Please check the URL or navigate back to a safe location.
                  </p>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <div className="flex flex-col sm:flex-row gap-3 justify-center">
                <Button
                  onClick={handleGoBack}
                  className="gap-2 bg-primary hover:bg-primary/90 transition-all duration-300"
                  size="lg"
                >
                  <RefreshCw className="h-4 w-4" />
                  Go Back
                </Button>
                <Button
                  onClick={handleGoHome}
                  variant="outline"
                  className="gap-2 border-primary/30 hover:bg-primary/10 transition-all duration-300"
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
                  <span>Technical Details</span>
                  <ChevronDown
                    className={`h-4 w-4 transition-transform duration-300 ${showDetails ? 'rotate-180' : ''
                      }`}
                  />
                </button>

                {showDetails && (
                  <div className="mt-4 p-4 bg-muted/50 rounded-lg border border-border">
                    <div className="space-y-2">
                      <div className="flex items-start gap-2">
                        <span className="text-xs font-mono text-primary font-semibold">
                          Status Code:
                        </span>
                        <span className="text-xs font-mono text-foreground flex-1">
                          404 - Not Found
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
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20">
                <div className="h-2 w-2 rounded-full bg-primary animate-pulse" />
                <span className="text-xs font-mono text-primary">
                  System Status: Active
                </span>
              </div>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default NotFound;
