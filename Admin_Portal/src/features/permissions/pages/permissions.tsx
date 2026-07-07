import { useEffect, useState } from "react";

import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Plus, Save, Loader2, ShieldCheck } from "lucide-react";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "@/store/store";
import { fetchRoles, fetchRoleDetails, updateExistingRole } from "../permissionsSlice";
import { useNavigate } from "react-router-dom";
import { toast } from "@/hooks/use-toast";
import { Permission } from "../types";
import { usePermissions } from "@/hooks/usePermissions";

type PermissionType = "read" | "write" | "edit" | "delete";

interface PermissionState {
  [key: string]: {
    read: boolean;
    write: boolean;
    edit: boolean;
    delete: boolean;
  };
}

const Permissions: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const navigate = useNavigate();
  const permissions = usePermissions("roles");
  const { roles, currentRole, loading } = useSelector((state: RootState) => state.permissions);

  const [selectedRoleId, setSelectedRoleId] = useState<string>("");
  const [permissionsState, setPermissionsState] = useState<PermissionState>({});
  const [originalPermissionsState, setOriginalPermissionsState] = useState<PermissionState>({});
  const [isSaving, setIsSaving] = useState(false);

  const hasChanges = (): boolean => {
    const originalKeys = Object.keys(originalPermissionsState);
    const currentKeys = Object.keys(permissionsState);

    if (originalKeys.length !== currentKeys.length) return true;

    for (const page of currentKeys) {
      const original = originalPermissionsState[page];
      const current = permissionsState[page];

      if (!original) return true;

      if (
        original.read !== current.read ||
        original.write !== current.write ||
        original.edit !== current.edit ||
        original.delete !== current.delete
      ) {
        return true;
      }
    }
    return false;
  };

  useEffect(() => {
    if (!permissions.hasRead) {
      navigate("/403", { replace: true });
    }
  }, [permissions.hasRead, navigate]);

  useEffect(() => {
    dispatch(fetchRoles());
  }, [dispatch]);

  useEffect(() => {
    if (roles.length > 0 && !selectedRoleId) {
      setSelectedRoleId(roles[0].id.toString());
    }
  }, [roles, selectedRoleId]);

  useEffect(() => {
    if (selectedRoleId) {
      dispatch(fetchRoleDetails(parseInt(selectedRoleId)));
    }
  }, [selectedRoleId, dispatch]);
  useEffect(() => {
    if (currentRole && currentRole.id.toString() === selectedRoleId) {
      const newPermissions: PermissionState = {};

      if (currentRole.permissions && currentRole.permissions.length > 0) {
        currentRole.permissions.forEach((perm) => {
          const pageName = perm.PageName;
          newPermissions[pageName] = {
            read: perm.read === 1,
            write: perm.write === 1,
            edit: perm.edit === 1,
            delete: perm.delete === 1,
          };
        });
        setPermissionsState(newPermissions);
        setOriginalPermissionsState(JSON.parse(JSON.stringify(newPermissions)));
      } else {

        setPermissionsState({});
      }
    }
  }, [currentRole, selectedRoleId]);

  const handlePermissionChange = (
    page: string,
    permType: PermissionType,
    checked: boolean
  ) => {
    setPermissionsState((prev) => ({
      ...prev,
      [page]: {
        ...prev[page],
        [permType]: checked,
      },
    }));
  };

  const handleSelectAll = (page: string, checked: boolean) => {
    setPermissionsState((prev) => ({
      ...prev,
      [page]: {
        read: checked,
        write: checked,
        edit: checked,
        delete: checked,
      },
    }));
  };

  const handleSave = async () => {
    if (!selectedRoleId || !currentRole) return;

    try {
      setIsSaving(true);
      const formattedPermissions: Permission[] = Object.entries(permissionsState).map(([page, perms]) => ({
        PageName: page,
        read: perms.read ? 1 : 0,
        write: perms.write ? 1 : 0,
        edit: perms.edit ? 1 : 0,
        delete: perms.delete ? 1 : 0,
      }));

      const rolePayload = {
        role: currentRole.role,
        permissions: formattedPermissions,
      };

      await dispatch(updateExistingRole({ id: parseInt(selectedRoleId), roleData: rolePayload })).unwrap();

      toast({
        title: "Permissions Updated",
        description: `Permissions for ${currentRole.role} have been successfully updated.`,
      });

      dispatch(fetchRoleDetails(parseInt(selectedRoleId)));

    } catch (err: any) {
      toast({
        title: "Error",
        description: "Failed to update permissions.",
        variant: "destructive",
      });
    } finally {
      setIsSaving(false);
    }
  };

  const permissionKeys = Object.keys(permissionsState);

  return (
    <div className="max-w-[1600px] mx-auto space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-card p-4 rounded-xl border shadow-sm">
        <div className="flex flex-col space-y-1.5">
          <Label className="text-muted-foreground text-xs uppercase tracking-wider font-semibold">Select Role to Manage</Label>
          <Select value={selectedRoleId} onValueChange={setSelectedRoleId}>
            <SelectTrigger className="w-[280px] bg-background">
              <SelectValue placeholder="Select a role..." />
            </SelectTrigger>
            <SelectContent>
              {roles.map((role) => (
                <SelectItem key={role.id} value={role.id.toString()}>
                  {role.role}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="flex items-center gap-3">
          {hasChanges() && (
            <Button
              onClick={handleSave}
              disabled={isSaving || !selectedRoleId}
              className="bg-primary hover:bg-primary/90"
            >
              {isSaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
              Save Changes
            </Button>
          )}
          <Button
            variant="outline"
            onClick={() => navigate("/roles/add")}
          >
            <Plus className="mr-2 h-4 w-4" />
            Create New Role
          </Button>
        </div>
      </div>

      {loading ? (
        <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
          <CardHeader className="border-b bg-muted/20 pb-4">
            <div className="flex items-center gap-3">
              <Skeleton className="h-9 w-9 rounded-lg" />
              <Skeleton className="h-6 w-48" />
            </div>
          </CardHeader>
          <CardContent className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {Array.from({ length: 8 }).map((_, index) => (
                <div key={index} className="rounded-xl bg-background border overflow-hidden">
                  <div className="px-4 py-3 border-b bg-muted/30 flex items-center gap-2">
                    <Skeleton className="h-4 w-4 rounded" />
                    <Skeleton className="h-4 w-24" />
                  </div>
                  <div className="p-4 grid grid-cols-2 gap-3">
                    {Array.from({ length: 4 }).map((_, i) => (
                      <div key={i} className="flex items-center gap-2 p-1">
                        <Skeleton className="h-4 w-4 rounded" />
                        <Skeleton className="h-3 w-12" />
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      ) : (
        <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
          <CardHeader className="border-b bg-muted/20 pb-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-primary/10 rounded-lg text-primary">
                <ShieldCheck className="h-5 w-5" />
              </div>
              <div>
                <CardTitle>Permissions: {currentRole?.role}</CardTitle>
              </div>
            </div>
          </CardHeader>
          <CardContent className="p-6">
            {permissionKeys.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                {permissionKeys.map((page) => {
                  const pagePerms = permissionsState[page];
                  const allChecked = pagePerms && Object.values(pagePerms).every(Boolean);

                  return (
                    <div key={page} className="group relative overflow-hidden rounded-xl bg-background border hover:border-primary/50 transition-all duration-300 hover:shadow-md">
                      <div className="absolute inset-0 bg-primary/0 group-hover:bg-primary/5 transition-colors pointer-events-none" />

                      <div className="px-4 py-3 border-b bg-muted/30 flex items-center justify-between">
                        <label className="flex items-center gap-2 cursor-pointer">
                          <Checkbox
                            checked={allChecked}
                            onCheckedChange={(checked) => handleSelectAll(page, checked as boolean)}
                            className="data-[state=checked]:bg-primary data-[state=checked]:border-primary"
                          />
                          <span className="font-semibold capitalize text-sm select-none">
                            {page}
                          </span>
                        </label>
                      </div>

                      <div className="p-4 grid grid-cols-2 gap-3">
                        {(["read", "write", "edit", "delete"] as const).map((type) => (
                          <label key={type} className="flex items-center gap-2 cursor-pointer hover:bg-muted/50 p-1 rounded-md transition-colors">
                            <Checkbox
                              checked={pagePerms?.[type] || false}
                              onCheckedChange={(checked) => handlePermissionChange(page, type, checked as boolean)}
                            />
                            <span className="text-xs capitalize text-muted-foreground select-none">
                              {type === "write" ? "create" : type}
                            </span>
                          </label>
                        ))}
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center py-16 text-muted-foreground gap-2">
                <ShieldCheck className="h-8 w-8 text-muted-foreground/50" />
                <p>No permissions found for this role.</p>
              </div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
};
export default Permissions;
