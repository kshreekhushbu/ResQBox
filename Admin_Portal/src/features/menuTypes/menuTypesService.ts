import ApiService from "@/services/config";
import { AxiosError } from "axios";
import { AddMenuType, MenuType, EditMenuType } from "./types";
import { Pagination } from "../categories/types";

export interface ApiResponse<T> {
  data: T;
  Message?: string;
  Success: boolean;
}

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
      error.response?.data?.message ?? "Something went wrong",
    );
  }

  throw new ApiError(500, "Unexpected error");
};

export const getAllMenuTypes = async (
  page: number = 1,
  limit: number = 10,
  search?: string,
): Promise<{ menuTypes: MenuType[]; pagination: Pagination }> => {
  try {
    const params = new URLSearchParams();
    params.append("page", page.toString());
    params.append("limit", limit.toString());
    if (search && search.trim()) {
      params.append("search", search.trim());
    }
    const response = await ApiService.get(`/getMenuTypes?${params.toString()}`);
    return {
      menuTypes: response?.data?.menuTypes || [],
      pagination: response?.data?.pagination,
    };
  } catch (error) {
    throw handleApiError(error);
  }
};

export const getMenuTypeById = async (id: string): Promise<MenuType> => {
  try {
    const response = await ApiService.get(`/getMenuTypeById/${id}`);
    return response?.data?.menuType;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const createMenuType = async (
  data: AddMenuType,
): Promise<{ message: string }> => {
  try {
    const response = await ApiService.post("/addMenuType", data);
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const updateMenuType = async (
  id: string,
  data: EditMenuType,
): Promise<{ message: string }> => {
  try {
    const response = await ApiService.put(`/updateMenuType/${id}`, data);
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const deleteMenuType = async (
  id: string,
): Promise<{ message: string }> => {
  try {
    const response = await ApiService.delete(`/deleteMenuType/${id}`);
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};
