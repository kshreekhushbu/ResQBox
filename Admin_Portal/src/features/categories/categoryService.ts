import ApiService from "@/services/config";
import { AxiosError } from "axios";
import { AddCategory, Category, EditCategory, Pagination } from "./types";

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
    this.name = "Some Thing Went Wrong?";
  }
}

const handleApiError = (error: unknown): never => {
  if (error instanceof AxiosError) {
    throw new ApiError(
      error.response?.status ?? 500,
      error.response?.data?.message ?? "Something went wrong"
    );
  }

  throw new ApiError(500, "Unexpected error");
};

export const AllCategories = async (
  page: number = 1,
  limit: number = 10,
  search?: string
): Promise<{ categories: Category[]; pagination: Pagination }> => {
  try {
    const params = new URLSearchParams();
    params.append("page", page.toString());
    params.append("limit", limit.toString());
    if (search && search.trim()) {
      params.append("search", search.trim());
    }
    const response = await ApiService.get(
      `/getCategories?${params.toString()}`
    );
    return {
      categories: response?.data?.categories,
      pagination: response?.data?.pagination,
    };
  } catch (error) {
    throw handleApiError(error);
  }
};

export const categoryDetails = async (id: string): Promise<Category> => {
  try {
    const response = await ApiService.get(`/getCategoryById/${id}`);
    return response?.data?.category;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const categoryCreate = async (
  stroyData: AddCategory
): Promise<{ message: string }> => {
  try {
    const response = await ApiService.post("/addCategory", stroyData);
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const updateCategory = async (
  id: string,
  stroyData: EditCategory
): Promise<{ message: string }> => {
  try {
    const response = await ApiService.put(`/updateCategory/${id}`, stroyData);
    return response.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const deleteCategory = async (
  id: string
): Promise<{ message: string }> => {
  try {
    const res = await ApiService.delete(`/deleteCategory/${id}`);
    return res?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};
