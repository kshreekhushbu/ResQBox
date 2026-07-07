import React, { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { yupResolver } from "@hookform/resolvers/yup";
import * as yup from "yup";
import {
  nameRegex,
  noLeadingSpace,
  maxTwoSpaces,
  normalizeInput,
} from "@/lib/utils";
import { useParams, useNavigate } from "react-router-dom";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { FormInput } from "@/components/forms/FormInput";
import { Checkbox } from "@/components/ui/checkbox";
import { Loader2, Save, Shield } from "lucide-react";
import { toast } from "@/hooks/use-toast";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "@/store/store";
import { fetchRoleDetails, createNewRole, updateExistingRole, fetchRoles, fetchPagePermissions } from "../permissionsSlice";
import { Permission } from "../types";
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb";

type PermissionType = "read" | "write" | "edit" | "delete";

interface PermissionState {
  [key: string]: {
    read: boolean;
    write: boolean;
    edit: boolean;
    delete: boolean;
  };
}

const roleSchema = yup.object().shape({
  role: yup
    .string()
    .required("Role name is required")
    .test("no-leading-space", "No leading spaces allowed", noLeadingSpace)
    .test(
      "max-two-spaces",
      "No more than 2 consecutive spaces allowed",
      maxTwoSpaces
    )
    .matches(/^[A-Za-z\s]+$/, "Only alphabets are allowed"),
});

type RoleFormData = yup.InferType<typeof roleSchema>;

const AddEditRole: React.FC = () => {
  const { id } = useParams<{ id?: string }>();
  const navigate = useNavigate();
  const dispatch = useDispatch<AppDispatch>();
  const isEditMode = !!id;
  const { currentRole, loading: storeLoading, defaultPermissions } = useSelector((state: RootState) => state.permissions);

  const [permissions, setPermissions] = useState<PermissionState>({});

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    setValue,
  } = useForm<RoleFormData>({
    resolver: yupResolver(roleSchema),
    defaultValues: {
      role: "",
    },
  });


  useEffect(() => {
    if (isEditMode && id) {
      dispatch(fetchRoleDetails(parseInt(id)));
    }
  }, [isEditMode, id, dispatch]);

  useEffect(() => {
    dispatch(fetchPagePermissions());
  }, [dispatch]);

  useEffect(() => {

    let newPermissions: PermissionState | null = null;

    if (isEditMode && currentRole && currentRole.id.toString() === id) {

      if (currentRole.permissions && Object.keys(permissions).length === 0) {
        newPermissions = {};
        setValue("role", currentRole.role);
        currentRole.permissions.forEach((perm) => {
          const pageName = perm.PageName;
          newPermissions![pageName] = {
            read: perm.read === 1,
            write: perm.write === 1,
            edit: perm.edit === 1,
            delete: perm.delete === 1,
          };
        });
      }
    } else if (!isEditMode && defaultPermissions.length > 0 && Object.keys(permissions).length === 0) {
      newPermissions = {};
      defaultPermissions.forEach((perm) => {
        const pageName = perm.PageName;
        newPermissions![pageName] = {
          read: perm.read === 1,
          write: perm.write === 1,
          edit: perm.edit === 1,
          delete: perm.delete === 1,
        };
      });
    }

    if (newPermissions) {
      setPermissions(newPermissions);
    }

  }, [isEditMode, currentRole, id, setValue, defaultPermissions, permissions]);


  const handlePermissionChange = (
    page: string,
    permType: PermissionType,
    checked: boolean
  ) => {
    setPermissions((prev) => ({
      ...prev,
      [page]: {
        ...prev[page],
        [permType]: checked,
      },
    }));
  };

  const handleSelectAll = (page: string, checked: boolean) => {
    setPermissions((prev) => ({
      ...prev,
      [page]: {
        read: checked,
        write: checked,
        edit: checked,
        delete: checked,
      },
    }));
  };

  const onSubmit = async (data: RoleFormData) => {
    try {
      const formattedPermissions: Permission[] = Object.entries(permissions).map(([page, perms]) => ({
        PageName: page,
        read: perms.read ? 1 : 0,
        write: perms.write ? 1 : 0,
        edit: perms.edit ? 1 : 0,
        delete: perms.delete ? 1 : 0,
      }));

      const rolePayload = {
        role: data.role,
        permissions: formattedPermissions,
      };

      if (isEditMode && id) {
        await dispatch(updateExistingRole({ id: parseInt(id), roleData: rolePayload })).unwrap();
        toast({ title: "Success", description: "Role updated successfully" });
      } else {
        await dispatch(createNewRole(rolePayload)).unwrap();
        toast({ title: "Success", description: "Role created successfully" });
      }

      dispatch(fetchRoles());
      navigate("/roles");
    } catch (error: any) {
      toast({
        title: "Error",
        description: typeof error === "string" ? error : "Failed to save role",
        variant: "destructive"
      });
    }
  };

  const permissionKeys = Object.keys(permissions);

  return (
    <div className="max-w-[1600px] mx-auto space-y-6">
      <div className="flex items-center gap-2 mb-2">
        <Breadcrumb>
          <BreadcrumbList>
            <BreadcrumbItem>
              <BreadcrumbLink href="/roles">Roles & Permissions</BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator />
            <BreadcrumbItem>
              <BreadcrumbPage className="text-primary font-semibold">{isEditMode ? "Edit Role" : "Create New Role"}</BreadcrumbPage>
            </BreadcrumbItem>
          </BreadcrumbList>
        </Breadcrumb>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
        <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
          <CardHeader>
            <div className="flex items-center gap-3">
              <div className="p-2 bg-primary/10 rounded-lg">
                <Shield className="h-6 w-6 text-primary" />
              </div>
              <div>
                <CardTitle>Role Details</CardTitle>
                <CardDescription>
                  Define the role identity and access level.
                </CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="max-w-md">
              <FormInput
                label="Role Name"
                placeholder="e.g. Content Manager"
                register={register("role")}
                error={errors.role}
                required
                className="bg-background"
              />
            </div>
          </CardContent>
        </Card>

        <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
          <CardHeader>
            <CardTitle>Permissions Matrix</CardTitle>
            <CardDescription>
              Granularly control access capabilities for this role across the application.
            </CardDescription>
          </CardHeader>
          <CardContent>
            {permissionKeys.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                {permissionKeys.map((page) => {
                  const pagePerms = permissions[page];
                  const allChecked = pagePerms && Object.values(pagePerms).every(Boolean);
                  return (
                    <div key={page} className="group relative overflow-hidden rounded-xl bg-background border hover:border-primary/50 transition-all duration-300 hover:shadow-lg">
                      <div className="absolute inset-0 bg-primary/0 group-hover:bg-primary/5 transition-colors pointer-events-none" />

                      <div className="p-4 border-b bg-muted/30 flex items-center justify-between">
                        <label className="flex items-center gap-3 cursor-pointer">
                          <Checkbox
                            checked={allChecked}
                            onCheckedChange={(checked) => handleSelectAll(page, checked as boolean)}
                            className="data-[state=checked]:bg-primary data-[state=checked]:border-primary"
                          />
                          <span className="font-semibold capitalize text-foreground select-none">
                            {page}
                          </span>
                        </label>
                      </div>

                      <div className="p-4 grid grid-cols-2 gap-4">
                        {(["read", "write", "edit", "delete"] as const).map((type) => (
                          <label key={type} className="flex items-center gap-2 cursor-pointer hover:bg-muted/50 p-1 rounded-md transition-colors">
                            <Checkbox
                              checked={pagePerms?.[type] || false}
                              onCheckedChange={(checked) => handlePermissionChange(page, type, checked as boolean)}
                            />
                            <span className="text-sm capitalize text-muted-foreground select-none">
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
              <div className="flex flex-col items-center justify-center py-10 text-muted-foreground">
                <Loader2 className="h-6 w-6 animate-spin mb-2 text-primary" />
                <p>Loading permissions...</p>
              </div>
            )}
          </CardContent>
        </Card>

        <div className="flex justify-end gap-4 sticky bottom-6 bg-background/80 backdrop-blur-md p-4 rounded-lg border shadow-lg z-10 transition-all duration-200">
          <Button
            type="button"
            variant="outline"
            onClick={() => navigate("/roles")}
            disabled={storeLoading}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            className="bg-primary hover:bg-primary/90 min-w-[120px]"
            disabled={storeLoading}
          >
            {storeLoading ? (
              <Loader2 className="h-4 w-4 animate-spin mr-2" />
            ) : (
              <Save className="h-4 w-4 mr-2" />
            )}
            {isEditMode ? "Update Role" : "Create Role"}
          </Button>
        </div>
      </form>
    </div>
  );
};
export default AddEditRole;
