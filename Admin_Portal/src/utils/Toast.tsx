import { toast } from "sonner";

export const ErrorMessage = (message: string) => {
    toast.error(message);
};

export const SuccessMessage = (message: string) => {
    toast.success(message);
};
