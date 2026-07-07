import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "@/store/store";
import {
    editConfig,
    setCurrentConfig,
    clearError,
    clearSuccessMessage,
    fetchAllConfigs,
} from "../configsSlice";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Save, Loader2, Info, Percent, DollarSign, Route, Clock } from "lucide-react";
import { toast } from "sonner";
import {
    Breadcrumb,
    BreadcrumbItem,
    BreadcrumbLink,
    BreadcrumbList,
    BreadcrumbPage,
    BreadcrumbSeparator,
} from "@/components/ui/breadcrumb";


export default function EditConfig() {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const dispatch = useDispatch<AppDispatch>();

    const { currentConfig, loading, error, successMessage, configs } = useSelector(
        (state: RootState) => state.configs
    );

    const [formData, setFormData] = useState({
        configKey: "",
        configValue: "",
    });

    useEffect(() => {
        if (configs.length === 0) {
            dispatch(fetchAllConfigs());
        } else {
            if (id) {
                dispatch(setCurrentConfig(id));
            }
        }
    }, [id, configs.length, dispatch]);

    useEffect(() => {
        if (currentConfig) {
            setFormData({
                configKey: currentConfig.configKey,
                configValue: currentConfig.configValue,
            });
        }
    }, [currentConfig]);

    useEffect(() => {
        if (successMessage) {
            toast.success(successMessage);
            dispatch(clearSuccessMessage());
            navigate("/config");
        }
        if (error) {
            toast.error(error);
            dispatch(clearError());
        }
    }, [successMessage, error, navigate, dispatch]);

    const handleChange = (field: string, value: string) => {
        setFormData((prev) => ({ ...prev, [field]: value }));
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (id) {
            dispatch(editConfig({
                configId: Number(id),
                configValue: formData.configValue
            }));
        }
    };

    return (
        <div className="max-w-5xl mx-auto space-y-6">
            <div className="flex items-center gap-2 mb-2">
                <Breadcrumb>
                    <BreadcrumbList>
                        <BreadcrumbItem>
                            <BreadcrumbLink href="/config">Configs</BreadcrumbLink>
                        </BreadcrumbItem>
                        <BreadcrumbSeparator />
                        <BreadcrumbItem>
                            <BreadcrumbPage className="text-primary font-semibold">Edit Config</BreadcrumbPage>
                        </BreadcrumbItem>
                    </BreadcrumbList>
                </Breadcrumb>
            </div>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="space-y-6">
                    <Card className="border-border/50 shadow-md bg-card">
                        <CardHeader className="pb-4 border-b border-border/40">
                            <CardTitle className="text-lg flex items-center gap-2">
                                <Info className="h-5 w-5 text-primary" />
                                Config Information
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="pt-6 space-y-4">
                            <div className="space-y-1">
                                <Label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Key Identifier</Label>
                                <div className="p-3 bg-muted/50 rounded-md border border-border/50 font-mono text-sm break-all text-primary">
                                    {formData.configKey || "Loading..."}
                                </div>
                                <p className="text-[11px] text-muted-foreground mt-1">
                                    This key is used by the application to retrieve this specific configuration value.
                                </p>
                            </div>
                            <div className="space-y-1">
                                <Label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Last Updated</Label>
                                <div className="text-sm font-medium">
                                    {currentConfig?.updatedAt ? new Date(currentConfig.updatedAt).toLocaleDateString() : "N/A"}
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>
                <div className="lg:col-span-2">
                    <form onSubmit={handleSubmit}>
                        <Card className="border-border/50 shadow-md">
                            <CardHeader className="pb-4 border-b border-border/40 bg-muted/20">
                                <CardTitle className="text-xl">Edit Value</CardTitle>
                                <CardDescription>
                                    Update the value for this configuration key.
                                </CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-6 pt-6">

                                <div className="space-y-2">
                                    <Label htmlFor="value" className="text-base font-semibold">Configuration Value</Label>
                                    <div className="flex items-center gap-3">
                                        {(() => {
                                            const key = formData.configKey.toLowerCase();
                                            const isPercentage = key.includes('percentage') || key.includes('percent') || key.includes('%');
                                            const isMoney = !isPercentage && (key.includes('fee') || key.includes('price') || key.includes('cost') || key.includes('charge'));
                                            const isDistance = !isPercentage && !isMoney && (key.includes('distance') || key.includes('limit') || key.includes('radius'));
                                            const isTime = !isPercentage && !isMoney && !isDistance && (key.includes('time'));

                                            if (isPercentage) {
                                                return (
                                                    <div className="flex items-center justify-center w-12 h-12 rounded-lg bg-blue-100 dark:bg-blue-900/20 shrink-0">
                                                        <Percent className="h-5 w-5 text-blue-600 dark:text-blue-400" />
                                                    </div>
                                                );
                                            }
                                            if (isMoney) {
                                                return (
                                                    <div className="flex items-center justify-center w-12 h-12 rounded-lg bg-green-100 dark:bg-green-900/20 shrink-0">
                                                        <DollarSign className="h-5 w-5 text-green-600 dark:text-green-400" />
                                                    </div>
                                                );
                                            }
                                            if (isDistance) {
                                                return (
                                                    <div className="flex items-center justify-center w-12 h-12 rounded-lg bg-purple-100 dark:bg-purple-900/20 shrink-0">
                                                        <Route className="h-5 w-5 text-purple-600 dark:text-purple-400" />
                                                    </div>
                                                );
                                            }
                                            if (isTime) {
                                                return (
                                                    <div className="flex items-center justify-center w-12 h-12 rounded-lg bg-orange-100 dark:bg-orange-900/20 shrink-0">
                                                        <Clock className="h-5 w-5 text-orange-600 dark:text-orange-400" />
                                                    </div>
                                                );
                                            }
                                            return null;
                                        })()}
                                        <Input
                                            id="value"
                                            placeholder="Enter configuration value..."
                                            value={formData.configValue}
                                            onChange={(e) => handleChange("configValue", e.target.value)}
                                            className="font-mono text-sm h-12 flex-1"
                                        />
                                        {(() => {
                                            const key = formData.configKey.toLowerCase();
                                            const isPercentage = key.includes('percentage') || key.includes('percent') || key.includes('%');
                                            const isMoney = !isPercentage && (key.includes('fee') || key.includes('price') || key.includes('cost') || key.includes('charge'));
                                            const isDistance = !isPercentage && !isMoney && (key.includes('distance') || key.includes('limit') || key.includes('radius'));
                                            const isTime = !isPercentage && !isMoney && !isDistance && (key.includes('time'));

                                            return isTime && <span className="text-sm font-medium text-muted-foreground whitespace-nowrap">Minutes</span>;
                                        })()}
                                    </div>
                                </div>

                            </CardContent>
                            <div className="p-6 border-t border-border/40 bg-muted/20 flex justify-end">
                                <Button
                                    type="submit"
                                    size="lg"
                                    className="bg-primary hover:bg-primary/90 min-w-[160px] shadow-lg shadow-primary/20 transition-all hover:scale-[1.02]"
                                    disabled={loading}
                                >
                                    {loading ? (
                                        <>
                                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                            Saving Changes...
                                        </>
                                    ) : (
                                        <>
                                            <Save className="mr-2 h-4 w-4" />
                                            Save Configuration
                                        </>
                                    )}
                                </Button>
                            </div>
                        </Card>
                    </form>
                </div>
            </div>
        </div>
    );
}
