import ApiService from "@/services/config";
import { AxiosError } from "axios";
import { AddCuisine, Cuisine, EditCuisine } from "./types";
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

export const AllCuisines = async (
  page: number = 1,
  limit: number = 10,
  search?: string
): Promise<{ cuisines: Cuisine[]; pagination: Pagination }> => {
  try {
    const params = new URLSearchParams();
    params.append("page", page.toString());
    params.append("limit", limit.toString());
    if (search && search.trim()) {
      params.append("search", search.trim());
    }
    const response = await ApiService.get(`/getCuisines?${params.toString()}`);
    return {
      cuisines: response?.data?.cuisines,
      pagination: response?.data?.pagination,
    };
  } catch (error) {
    throw handleApiError(error);
  }
};

export const cuisineDetails = async (id: string): Promise<Cuisine> => {
  try {
    const response = await ApiService.get(`/getCuisineById/${id}`);
    return response?.data?.cuisine;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const cuisineCreate = async (
  cuisineData: AddCuisine
): Promise<{ message: string }> => {
  try {
    const response = await ApiService.post("/addCuisine", cuisineData);
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const updateCuisine = async (
  id: string,
  cuisineData: EditCuisine
): Promise<{ message: string }> => {
  try {
    const response = await ApiService.put(`/updateCuisine/${id}`, cuisineData);
    return response.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const deleteCuisine = async (
  id: string
): Promise<{ message: string }> => {
  try {
    const res = await ApiService.delete(`/deleteCuisine/${id}`);
    return res?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};
