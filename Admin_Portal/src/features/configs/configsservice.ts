import ApiService from "@/services/config";
import { AxiosError } from "axios";
import { Config, UpdateConfigPayload } from "./types";

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

export const getAllConfigs = async (): Promise<Config[]> => {
  try {
    const response = await ApiService.get("/getConfig");
    return response?.data?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const updateConfig = async (
  data: UpdateConfigPayload
): Promise<{ message: string; config: Config }> => {
  try {
    const response = await ApiService.put("/updateConfig", data);
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};
