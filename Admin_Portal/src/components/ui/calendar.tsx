import * as React from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { DayPicker } from "react-day-picker";

import { cn } from "@/lib/utils";
import { buttonVariants } from "@/components/ui/button";

export type CalendarProps = React.ComponentProps<typeof DayPicker>;

function Calendar({ className, classNames, showOutsideDays = true, ...props }: CalendarProps) {
  return (
    <DayPicker
      showOutsideDays={showOutsideDays}
      className={cn("p-3", className)}
      classNames={{
        months: "flex flex-col sm:flex-row space-y-4 sm:space-x-4 sm:space-y-0",
        month: "space-y-4",
        caption: "flex justify-between pt-1 relative items-center px-1",
        caption_label: cn("text-xs font-bold tracking-tight text-zinc-900 dark:text-white", props.captionLayout === "dropdown" && "hidden"),
        nav: "flex items-center gap-1",
        nav_button: cn(
          buttonVariants({ variant: "ghost" }),
          "h-7 w-7 bg-zinc-50 dark:bg-zinc-800/50 p-0 opacity-70 hover:opacity-100 hover:bg-primary/10 hover:text-primary rounded-lg transition-all duration-300",
        ),
        nav_button_previous: "relative",
        nav_button_next: "relative",
        table: "w-full border-collapse",
        head_row: "flex mb-1",
        head_cell: "text-zinc-400 dark:text-zinc-500 rounded-md w-8 font-black text-[9px] uppercase tracking-widest",
        row: "flex w-full mt-0.5",
        cell: "h-8 w-8 text-center text-xs p-0 relative transition-all duration-300 [&:has([aria-selected].day-range-end)]:rounded-r-lg [&:has([aria-selected].day-outside)]:bg-accent/50 [&:has([aria-selected])]:bg-primary/5 first:[&:has([aria-selected])]:rounded-l-lg last:[&:has([aria-selected])]:rounded-r-lg focus-within:relative focus-within:z-20",
        day: cn(
          buttonVariants({ variant: "ghost" }),
          "h-8 w-8 p-0 font-bold rounded-lg hover:bg-primary/10 hover:text-primary aria-selected:opacity-100 transition-all duration-200"
        ),
        day_range_end: "day-range-end",
        day_selected:
          "bg-primary !text-white hover:bg-primary hover:text-white focus:bg-primary focus:text-white shadow-md shadow-primary/20 z-10",
        day_today: "bg-zinc-100 dark:bg-zinc-800 text-primary ring-1 ring-primary/20",
        day_outside:
          "day-outside text-zinc-300 dark:text-zinc-600 opacity-50 aria-selected:bg-accent/30 aria-selected:text-zinc-400 aria-selected:opacity-30",
        day_disabled: "text-zinc-300 dark:text-zinc-700 opacity-50",
        day_range_middle: "aria-selected:bg-primary/10 aria-selected:text-primary",
        day_hidden: "invisible",
        caption_dropdowns: "flex justify-center gap-1 items-center bg-zinc-50 dark:bg-zinc-800/80 p-1 rounded-lg border border-zinc-100 dark:border-zinc-700/50",
        dropdown: cn(
          "bg-transparent text-sm font-black tracking-tight cursor-pointer focus:outline-none px-2 py-1 hover:text-primary transition-colors appearance-none",
        ),
        dropdown_month: "flex items-center",
        dropdown_year: "flex items-center",
        ...classNames,
      }}
      components={{
        IconLeft: ({ ..._props }) => <ChevronLeft className="h-4 w-4" />,
        IconRight: ({ ..._props }) => <ChevronRight className="h-4 w-4" />,
      }}
      {...props}
    />
  );
}
Calendar.displayName = "Calendar";

export { Calendar };
