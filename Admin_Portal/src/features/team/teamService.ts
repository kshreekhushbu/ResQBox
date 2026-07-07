import ApiService from "@/services/config";
import { AxiosError } from "axios";
import { AdminUsersResponse, CreateAdminUser, UpdateAdminUser, AdminUser } from "./types";

export class ApiError extends Error {
    status: number;
    constructor(Status: number, Message: string) {
        super(Message);
        this.status = Status;
        this.name = "Team API Error";
    }
}

const handleApiError = (error: unknown): never => {
    if (error instanceof AxiosError) {
        throw new ApiError(
            error.response?.status ?? 500,
            (error.response?.data as any)?.message ?? "Something went wrong"
        );
    }
    throw new ApiError(500, "Unexpected error");
};

export const getAdminUsers = async (
    page: number = 1,
    limit: number = 10,
    search: string = ""
): Promise<AdminUsersResponse> => {
    try {
        const queryParams = new URLSearchParams({
            page: page.toString(),
            limit: limit.toString(),
        });

        if (search && search.length >= 3) {
            queryParams.append("search", search);
        }

        const response = await ApiService.get(`/getAdminUsers?${queryParams.toString()}`);
        return response.data;
    } catch (error) {
        throw handleApiError(error);
    }
};

export const createAdminUser = async (userData: CreateAdminUser): Promise<{ message: string }> => {
    try {
        const response = await ApiService.post("/createAdminUser", userData);
        return response.data;
    } catch (error) {
        throw handleApiError(error);
    }
};

export const getAdminUserById = async (id: number): Promise<AdminUser> => {
    try {
        const response = await ApiService.get(`/getAdminUserById/${id}`);
        return response.data.adminUser || response.data.user || response.data; 
    } catch (error) {
        throw handleApiError(error);
    }
};

export const updateAdminUser = async (id: number, userData: UpdateAdminUser): Promise<{ message: string }> => {
    try {
        const response = await ApiService.put(`/updateAdminUser/${id}`, userData);
        return response.data;
    } catch (error) {
        throw handleApiError(error);
    }
};

export const deleteAdminUser = async (id: number): Promise<{ message: string }> => {
    try {
        const response = await ApiService.delete(`/deleteAdminUser/${id}`);
        return response.data;
    } catch (error) {
        throw handleApiError(error);
    }
};
