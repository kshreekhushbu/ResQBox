import { toast } from "sonner";
import { Button } from "@/components/ui/button";

const SolidDestructiveSonnerDemo = () => {
  return (
    <Button
      variant="outline"
      onClick={() =>
        toast.error("Oops, there was an error processing your request.", {
          style: {
            // These CSS variables are used by Sonner richColors to override colors
            // Works with the custom theme from src/components/ui/sonner.tsx
            "--normal-bg":
              "light-dark(var(--destructive), color-mix(in oklab, var(--destructive) 60%, var(--background)))",
            "--normal-text": "var(--color-white)",
            "--normal-border": "transparent",
          } as React.CSSProperties,
        })
      }
    >
      Solid Destructive Toast
    </Button>
  );
};

export default SolidDestructiveSonnerDemo;
