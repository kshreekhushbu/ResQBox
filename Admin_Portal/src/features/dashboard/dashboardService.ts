import ApiService from "@/services/config";
import { AxiosError } from "axios";
import { DashboardResponse } from "./types";

export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
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

export const fetchDashboardData = async (): Promise<DashboardResponse> => {
  try {
    const response = await ApiService.get("/getDashboard");
    return response.data;
  } catch (error) {
    throw handleApiError(error);
  }
};
