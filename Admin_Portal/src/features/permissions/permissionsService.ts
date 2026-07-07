import ApiService from "@/services/config";
import { AxiosError } from "axios";
import { RolesResponse, Role, RoleDetailsResponse, Permission } from "./types";

export class ApiError extends Error {
  status: number;

  constructor(Status: number, Message: string) {
    super(Message);
    this.status = Status;
    this.name = "ApiError";
  }
}

const handleApiError = (error: unknown): never => {
  if (error instanceof AxiosError) {
    throw new ApiError(
      error.response?.status ?? 500,
      error.response?.data?.message ?? "Something went wrong"
    );
  }
  throw new ApiError(500, "An unexpected error occurred");
};

export const getAllRoles = async (): Promise<Role[]> => {
  try {
    const response = await ApiService.get<RolesResponse>("/getRoles");
    if (response.data.status === 1) {
      return response.data.roles;
    }
    throw new ApiError(response.status ?? 500, "Failed to fetch roles");
  } catch (error) {
    return handleApiError(error);
  }
};

export const getRoleById = async (id: number): Promise<Role> => {
    try {
        const response = await ApiService.get<RoleDetailsResponse>(`/getRoleById/${id}`);
        if (response.data.status === 1 && response.data.role.length > 0) {
            return response.data.role[0];
        }
        throw new ApiError(response.status ?? 500, "Failed to fetch role details");
    } catch (error) {
        return handleApiError(error);
    }
};

export const updateRole = async (id: number, roleData: { role: string; permissions: Permission[] }): Promise<void> => {
    try {
        await ApiService.put(`/updateRole/${id}`, roleData);
    } catch (error) {
        return handleApiError(error);
    }
};

export const createRole = async (roleData: { role: string; permissions: Permission[] }): Promise<void> => {
    try {
        await ApiService.post("/createRole", roleData);
    } catch (error) {
        return handleApiError(error);
    }
};

export const getPagePermissions = async (): Promise<Permission[]> => {
    try {
        const response = await ApiService.get<{ status: number; permissions: Permission[] }>("/getPagePermissions");
        if (response.data.status === 1) {
            return response.data.permissions;
        }
        throw new ApiError(response.status ?? 500, "Failed to fetch page permissions");
    } catch (error) {
        return handleApiError(error);
    }
};
