import React from "react";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { AlertTriangle, Trash2, Info, CheckCircle } from "lucide-react";

export type ConfirmationType = "danger" | "warning" | "info" | "success";

interface ConfirmationModalProps {
    isOpen: boolean;
    onClose: () => void;
    onConfirm: () => void;
    title: string;
    description: string;
    confirmText?: string;
    cancelText?: string;
    type?: ConfirmationType;
    isLoading?: boolean;
}

const iconMap = {
    danger: Trash2,
    warning: AlertTriangle,
    info: Info,
    success: CheckCircle,
};

const colorMap = {
    danger: "text-destructive",
    warning: "text-warning",
    info: "text-primary",
    success: "text-success",
};

const buttonVariantMap = {
    danger: "destructive",
    warning: "default",
    info: "default",
    success: "default",
} as const;

export const ConfirmationModal: React.FC<ConfirmationModalProps> = ({
    isOpen,
    onClose,
    onConfirm,
    title,
    description,
    confirmText = "Confirm",
    cancelText = "Cancel",
    type = "danger",
    isLoading = false,
}) => {
    const Icon = iconMap[type];

    return (
        <Dialog open={isOpen} onOpenChange={onClose}>
            <DialogContent className="sm:max-w-[425px]">
                <DialogHeader>
                    <div className="flex items-center gap-3">
                        <div
                            className={`p-2 rounded-full bg-background border-2 ${colorMap[type]}`}
                        >
                            <Icon className="h-5 w-5" />
                        </div>
                        <DialogTitle className="text-xl">{title}</DialogTitle>
                    </div>
                    <DialogDescription className="pt-4 text-base">
                        {description}
                    </DialogDescription>
                </DialogHeader>
                <DialogFooter className="gap-2 sm:gap-0">
                    <Button
                        variant="outline"
                        onClick={onClose}
                        disabled={isLoading}
                        className="min-w-[100px]"
                    >
                        {cancelText}
                    </Button>
                    <Button
                        variant={buttonVariantMap[type]}
                        onClick={onConfirm}
                        disabled={isLoading}
                        className="min-w-[100px]"
                    >
                        {isLoading ? "Processing..." : confirmText}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
};
