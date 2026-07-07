import { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { AppDispatch, RootState } from "@/store/store";
import {
  fetchAllConfigs,
  clearError,
  clearSuccessMessage,
} from "../configsSlice";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Search, Edit, MoreVertical, Settings2, Percent, DollarSign, Route, Clock } from "lucide-react";
import { toast } from "sonner";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { DynamicTable, TableColumn } from "@/components/table/DynamicTable";
import { Config } from "../types";
import { usePermissions } from "@/hooks/usePermissions";

export default function Configs() {
  const dispatch = useDispatch<AppDispatch>();
  const navigate = useNavigate();
  const permissions = usePermissions("config");
  const { configs, loading, error, successMessage } = useSelector(
    (state: RootState) => state.configs
  );
  const [searchTerm, setSearchTerm] = useState("");

  useEffect(() => {
    if (!permissions.hasRead) {
      navigate("/403", { replace: true });
    }
  }, [permissions.hasRead, navigate]);

  useEffect(() => {
    dispatch(fetchAllConfigs());
  }, [dispatch]);

  useEffect(() => {
    if (successMessage) {
      toast.success(successMessage);
      dispatch(clearSuccessMessage());
    }
    if (error) {
      toast.error(error);
      dispatch(clearError());
    }
  }, [successMessage, error, dispatch]);

  const filteredConfigs = configs.filter((config) =>
    config.configKey.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const columns: TableColumn<Config>[] = [
    {
      key: "configKey",
      label: "Config Key",
      dataIndex: "configKey",
      render: (value) => (
        <span className="font-medium text-foreground">{value}</span>
      ),
    },
    {
      key: "configValue",
      label: "Value / Preview",
      dataIndex: "configValue",
      render: (value, record) => {
        const key = record.configKey.toLowerCase();
        const isPercentage = key.includes('percentage') || key.includes('percent') || key.includes('%');
        const isMoney = !isPercentage && (key.includes('fee') || key.includes('price') || key.includes('cost') || key.includes('charge'));
        const isDistance = !isPercentage && !isMoney && (key.includes('distance') || key.includes('limit') || key.includes('radius'));
        const isTime = !isPercentage && !isMoney && !isDistance && (key.includes('time'));

        const cleanedValue = cleanValue(value);

        return (
          <div className="flex items-center gap-2">
            {isPercentage && (
              <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-blue-100 dark:bg-blue-900/20">
                <Percent className="h-4 w-4 text-blue-600 dark:text-blue-400" />
              </div>
            )}
            {isMoney && (
              <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-green-100 dark:bg-green-900/20">
                <DollarSign className="h-4 w-4 text-green-600 dark:text-green-400" />
              </div>
            )}
            {isDistance && (
              <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-purple-100 dark:bg-purple-900/20">
                <Route className="h-4 w-4 text-purple-600 dark:text-purple-400" />
              </div>
            )}
            {isTime && (
              <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-orange-100 dark:bg-orange-900/20">
                <Clock className="h-4 w-4 text-orange-600 dark:text-orange-400" />
              </div>
            )}
            <div className="flex flex-col">
              <span className="text-foreground font-semibold">{cleanedValue}</span>
              {isPercentage && <span className="text-xs text-muted-foreground">Percentage</span>}
              {isMoney && <span className="text-xs text-muted-foreground">Currency</span>}
              {isDistance && <span className="text-xs text-muted-foreground">Kilometers</span>}
              {isTime && <span className="text-xs text-muted-foreground">Minutes</span>}
            </div>
          </div>
        );
      },
      width: "60%",
    },
    {
      key: "actions",
      label: "Actions",
      align: "right",
      width: 100,
      render: (_, record) => (
        <div className="flex justify-end">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="h-8 w-8 p-0">
                <span className="sr-only">Open menu</span>
                <MoreVertical className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem
                onClick={() => {
                  if (!permissions.checkEdit()) {
                    return;
                  }
                  navigate(`/config/edit/${record.configId}`);
                }}
              >
                <Edit className="mr-2 h-4 w-4" />
                Edit
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      ),
    },
  ];

  const cleanValue = (val: string) => {
    if (!val) return "-";
    const tmp = document.createElement("DIV");
    tmp.innerHTML = val;
    const text = tmp.textContent || tmp.innerText || "";
    return text.length > 50 ? text.substring(0, 50) + "..." : text;
  };

  return (
    <div className="space-y-6">
      <Card className="border-border/50 shadow-sm">
        <CardHeader className="pb-3">
          <div className="flex justify-between items-center">
            <div>
              <CardTitle className="text-lg flex items-center gap-2">
                <Settings2 className="h-5 w-5 text-primary" />
                Config Entries
              </CardTitle>
              <CardDescription>
                A list of all dynamic configuration values in the system.
              </CardDescription>
            </div>
            <div className="relative w-full max-w-sm">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                type="search"
                placeholder="Search configs..."
                className="pl-8"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <DynamicTable
            columns={columns}
            data={filteredConfigs}
            loading={loading}
            emptyMessage="No configurations found."
            rowKey="configId"
          />
        </CardContent>
      </Card>
    </div>
  );
}
