import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { cn } from "@/lib/utils";
import React from "react";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

// Ant Design-like Column interface
export interface TableColumn<T = any> {
  key: string;
  label: string | React.ReactNode;
  dataIndex?: string;
  width?: string | number;
  align?: "left" | "center" | "right";
  className?: string;
  render?: (value: any, record: T, index: number) => React.ReactNode;
  fixed?: "left" | "right";
  ellipsis?: boolean;
}

interface DynamicTableProps<T = any> {
  columns: TableColumn<T>[];
  data: T[];
  loading?: boolean;
  rowKey?: string | ((record: T) => string | number);
  emptyMessage?: string | React.ReactNode;
  className?: string;
  onRowClick?: (record: T, index: number) => void;
  skeletonRows?: number;
  minWidth?: string | number;
}

export const DynamicTable = <T extends Record<string, any> = any>({
  columns,
  data,
  loading,
  rowKey = "id",
  emptyMessage = "No data available",
  className,
  onRowClick,
  skeletonRows = 5,
  minWidth,
}: DynamicTableProps<T>) => {
  const getRowKey = (record: T, index: number): string | number => {
    if (typeof rowKey === "function") {
      return rowKey(record);
    }
    return record[rowKey] ?? index;
  };

  const getCellValue = (column: TableColumn<T>, record: T, index: number) => {
    const dataIndex = column.dataIndex || column.key;
    const value = record[dataIndex];

    if (column.render) {
      return column.render(value, record, index);
    }

    return value ?? "-";
  };

  const getAlignmentClass = (align?: "left" | "center" | "right") => {
    switch (align) {
      case "center":
        return "text-center";
      case "right":
        return "text-right";
      default:
        return "text-left";
    }
  };

  const equalWidth = `${100 / columns.length}%`;

  return (
    <div
      className={cn(
        "w-full border border-border bg-card overflow-hidden rounded-md",
        className
      )}
    >
      <div className="overflow-x-auto">
        <Table
          className="w-full"
          style={{ minWidth: minWidth }}
        >
          <TableHeader>
            <TableRow className="border-b-0 hover:bg-transparent">
              {columns.map((column) => (
                <TableHead
                  key={column.key}
                  className={cn(
                    "bg-primary text-primary-foreground font-semibold text-sm uppercase tracking-wider h-14 px-6 whitespace-nowrap align-middle",
                    getAlignmentClass(column.align),
                    column.className
                  )}
                  style={{
                    width: column.width || equalWidth,
                  }}
                >
                  {typeof column.label === "string"
                    ? column.label.toUpperCase()
                    : column.label}
                </TableHead>
              ))}
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              Array.from({ length: skeletonRows }).map((_, index) => (
                <TableRow
                  key={`skeleton-${index}`}
                  className="border-b border-border"
                >
                  {columns.map((column, colIndex) => (
                    <TableCell
                      key={`skeleton-cell-${colIndex}`}
                      className={cn(
                        "px-6 py-4 align-middle",
                        getAlignmentClass(column.align),
                        column.className
                      )}
                      style={{
                        width: column.width || equalWidth,
                      }}
                    >
                      <Skeleton />
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : data && data.length > 0 ? (
              data.map((row, index) => (
                <TableRow
                  key={getRowKey(row, index)}
                  className={cn(
                    "border-b border-border transition-colors hover:bg-muted/30",
                    index === data.length - 1 && "border-b-0",
                    onRowClick && "cursor-pointer"
                  )}
                  onClick={() => onRowClick?.(row, index)}
                >
                  {columns.map((column) => (
                    <TableCell
                      key={column.key}
                      className={cn(
                        "px-6 py-4 text-sm text-foreground align-middle",
                        getAlignmentClass(column.align),
                        column.className
                      )}
                      style={{
                        width: column.width || equalWidth,
                      }}
                    >
                      {column.ellipsis ? (
                        <div className="truncate">
                          {getCellValue(column, row, index)}
                        </div>
                      ) : (
                        getCellValue(column, row, index)
                      )}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={columns.length}
                  className="h-24 text-center text-muted-foreground"
                >
                  {emptyMessage}
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
};
