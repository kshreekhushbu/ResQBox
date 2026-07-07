import React from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface PaginationProps {
  Pagination: {
    page: number;
    totalCount: number;
    totalPages: number;
    size: number;
  };
  onPageChange: (newPage: number) => void;
}

const Pagination: React.FC<PaginationProps> = ({
  Pagination,
  onPageChange,
}) => {
  const { page, totalCount, totalPages, size } = Pagination;

  const handlePageClick = (newPage: number) => {
    if (newPage >= 1 && newPage <= totalPages) {
      onPageChange(newPage);
    }
  };

  const renderPageNumbers = () => {
    const pages = [];
    const maxVisiblePages = 5;
    let startPage = Math.max(1, page - Math.floor(maxVisiblePages / 2));
    let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);

    if (endPage - startPage + 1 < maxVisiblePages) {
      startPage = Math.max(1, endPage - maxVisiblePages + 1);
    }

    const renderButton = (pageNum: number) => (
      <Button
        key={pageNum}
        variant={page === pageNum ? "default" : "outline"}
        size="icon"
        className={cn(
          "w-9 h-9 transition-all duration-200",
          page === pageNum
            ? "bg-primary text-primary-foreground hover:bg-primary/90 shadow-md transform scale-105"
            : "text-foreground bg-transparent border-input hover:bg-accent hover:text-accent-foreground"
        )}
        onClick={() => onPageChange(pageNum)}
      >
        {pageNum}
      </Button>
    );

    if (startPage > 1) {
      pages.push(renderButton(1));
      if (startPage > 2) {
        pages.push(
          <span
            key="ellipsis-start"
            className="flex items-center justify-center w-9 h-9 text-sm font-medium text-muted-foreground"
          >
            ⋯
          </span>
        );
      }
    }

    for (let i = startPage; i <= endPage; i++) {
      pages.push(renderButton(i));
    }

    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pages.push(
          <span
            key="ellipsis-end"
            className="flex items-center justify-center w-9 h-9 text-sm font-medium text-muted-foreground"
          >
            ⋯
          </span>
        );
      }
      pages.push(renderButton(totalPages));
    }

    return pages;
  };
  if (totalCount === 0) return null;

  return (
    <div className="flex flex-col sm:flex-row items-center justify-between gap-4 px-2 py-4">
      <div className="flex items-center text-sm text-muted-foreground bg-accent/30 px-3 py-1.5 rounded-full border border-border/50">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-primary animate-pulse"></div>
          <span>
            Showing{" "}
            <span className="font-semibold text-foreground">
              {(page - 1) * size + 1}
            </span>{" "}
            -{" "}
            <span className="font-semibold text-foreground">
              {Math.min(page * size, totalCount)}
            </span>{" "}
            of{" "}
            <span className="font-semibold text-foreground">{totalCount}</span>
          </span>
        </div>
      </div>

      <div className="flex items-center gap-1.5">
        <Button
          variant="outline"
          size="icon"
          className="w-9 h-9 text-foreground bg-transparent border-input hover:bg-accent hover:text-accent-foreground disabled:opacity-50"
          onClick={() => handlePageClick(page - 1)}
          disabled={page === 1}
        >
          <ChevronLeft className="w-4 h-4" />
        </Button>

        <div className="flex items-center gap-1.5">{renderPageNumbers()}</div>

        <Button
          variant="outline"
          size="icon"
          className="w-9 h-9 text-foreground bg-transparent border-input hover:bg-accent hover:text-accent-foreground disabled:opacity-50"
          onClick={() => handlePageClick(page + 1)}
          disabled={page >= totalPages}
        >
          <ChevronRight className="w-4 h-4" />
        </Button>
      </div>
    </div>
  );
};

export default Pagination;
