import ApiService from "@/services/config";
import { AxiosError } from "axios";
import { AddFoodType, FoodType, EditFoodType } from "./types";
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
      error.response?.data?.message ?? "Something went wrong"
    );
  }

  throw new ApiError(500, "Unexpected error");
};

export const getAllFoodTypes = async (
  page: number = 1,
  limit: number = 10,
  search?: string
): Promise<{ foodTypes: FoodType[]; pagination: Pagination }> => {
  try {
    const params = new URLSearchParams();
    params.append("page", page.toString());
    params.append("limit", limit.toString());
    if (search && search.trim()) {
      params.append("search", search.trim());
    }
    const response = await ApiService.get(`/getFoodTypes?${params.toString()}`);
    return {
      foodTypes: response?.data?.foodTypes || [],
      pagination: response?.data?.pagination,
    };
  } catch (error) {
    throw handleApiError(error);
  }
};

export const getFoodTypeById = async (id: string): Promise<FoodType> => {
  try {
    const response = await ApiService.get(`/getFoodTypeById/${id}`);
    return response?.data?.foodType;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const createFoodType = async (
  data: AddFoodType
): Promise<{ message: string }> => {
  try {
    const response = await ApiService.post("/addFoodType", data);
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const updateFoodType = async (
  id: string,
  data: EditFoodType
): Promise<{ message: string }> => {
  try {
    const response = await ApiService.put(`/updateFoodType/${id}`, data);
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const deleteFoodType = async (
  id: string
): Promise<{ message: string }> => {
  try {
    const response = await ApiService.delete(`/deleteFoodType/${id}`);
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};
