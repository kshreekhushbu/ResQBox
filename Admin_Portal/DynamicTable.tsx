import React from "react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { cn } from "@/lib/utils";

export interface TableColumn<T = any> {
  key: string;
  label: string;
  dataIndex?: keyof T;
  render?: (value: any, record: T, index: number) => React.ReactNode;
  width?: string;
  align?: "left" | "center" | "right";
  className?: string;
}

interface DynamicTableProps<T> {
  columns: TableColumn<T>[];
  data: T[];
  loading?: boolean;
  emptyMessage?: string | React.ReactNode;
  skeletonRows?: number;
  rowKey?: keyof T | ((record: T) => string);
  onRowClick?: (record: T) => void;
  className?: string;
}

export function DynamicTable<T>({
  columns,
  data,
  loading = false,
  emptyMessage = "No data available",
  skeletonRows = 5,
  rowKey,
  onRowClick,
  className,
}: DynamicTableProps<T>) {
  const getRowKey = (record: T, index: number): string => {
    if (typeof rowKey === "function") {
      return rowKey(record);
    }
    if (rowKey && Object.prototype.hasOwnProperty.call(record, rowKey)) {
      return String(record[rowKey]);
    }
    return String(index);
  };

  const getValue = (record: T, column: TableColumn<T>) => {
    if (column.dataIndex) {
      return record[column.dataIndex];
    }
    return null;
  };

  return (
    <div className={cn("w-full", className)}>
      {/* Responsive table wrapper with auto horizontal scroll */}
      <div className="relative w-full overflow-x-auto rounded-md border shadow-sm">
        {/* Scroll indicator shadow */}
        <div className="absolute inset-y-0 left-0 w-4 bg-gradient-to-r from-background to-transparent pointer-events-none z-10 opacity-0 transition-opacity" />
        <div className="absolute inset-y-0 right-0 w-4 bg-gradient-to-l from-background to-transparent pointer-events-none z-10 opacity-0 transition-opacity" />

        <Table className="w-full min-w-full sm:min-w-[640px] md:min-w-[768px] lg:min-w-[1024px]">
          <TableHeader>
            <TableRow>
              {columns.map((column) => (
                <TableHead
                  key={column.key}
                  className={cn(
                    "px-4 py-3",
                    column.align === "center" && "text-center",
                    column.align === "right" && "text-right",
                    column.className
                  )}
                  style={{ width: column.width }}
                >
                  {column.label}
                </TableHead>
              ))}
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              Array.from({ length: skeletonRows }).map((_, index) => (
                <TableRow key={`skeleton-${index}`}>
                  {columns.map((column) => (
                    <TableCell
                      key={`skeleton-${index}-${column.key}`}
                      className="whitespace-nowrap"
                      style={{ width: column.width }}
                    >
                      <Skeleton className="h-4 w-full" />
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : data.length > 0 ? (
              data.map((record, index) => (
                <TableRow
                  key={getRowKey(record, index)}
                  onClick={() => onRowClick?.(record)}
                  className={cn(
                    onRowClick && "cursor-pointer hover:bg-muted/50"
                  )}
                >
                  {columns.map((column) => (
                    <TableCell
                      key={`${getRowKey(record, index)}-${column.key}`}
                      className={cn(
                        "px-4 py-3",
                        column.align === "center" && "text-center",
                        column.align === "right" && "text-right",
                        column.className
                      )}
                      style={{ width: column.width }}
                    >
                      {column.render
                        ? column.render(getValue(record, column), record, index)
                        : (getValue(record, column) as React.ReactNode)}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={columns.length}
                  className="h-24 text-center"
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
}
