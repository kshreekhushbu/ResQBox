import { useTheme } from "next-themes";
import { Toaster as Sonner, toast } from "sonner";

type ToasterProps = React.ComponentProps<typeof Sonner>;

const Toaster = ({ ...props }: ToasterProps) => {
  const { theme = "system" } = useTheme();

  return (
    <Sonner
      theme={theme as ToasterProps["theme"]}
      className="toaster group"
      toastOptions={{
        classNames: {
          toast:
            "group toast group-[.toaster]:border-border group-[.toaster]:shadow-lg",
          description: "group-[.toast]:text-white group-[.toast]:opacity-90",
          actionButton:
            "group-[.toast]:bg-primary group-[.toast]:text-primary-foreground",
          cancelButton:
            "group-[.toast]:bg-muted group-[.toast]:text-muted-foreground",
          error:
            "group-[.toaster]:bg-destructive group-[.toaster]:text-destructive-foreground group-[.toaster]:border-destructive [&_[data-description]]:text-destructive-foreground [&_[data-description]]:opacity-90",
          success:
            "group-[.toaster]:bg-green-600 group-[.toaster]:text-white group-[.toaster]:border-green-600",
          warning:
            "group-[.toaster]:bg-yellow-600 group-[.toaster]:text-white group-[.toaster]:border-yellow-600",
          info:
            "group-[.toaster]:bg-blue-600 group-[.toaster]:text-white group-[.toaster]:border-blue-600",
        },
      }}
      {...props}
    />
  );
};

export { Toaster, toast };
