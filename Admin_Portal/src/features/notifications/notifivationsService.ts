import ApiService from "@/services/config";
import { AxiosError } from "axios";
import { Notification, SendNotification } from "./types";

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

const NOTIFICATIONs_API = "/getAdminNotifications";

const handleApiError = (error: unknown): never => {
  if (error instanceof AxiosError) {
    throw new ApiError(
      error.response?.status ?? 500,
      error.response?.data?.message ?? "Something went wrong"
    );
  }
  throw new ApiError(500, "Unexpected error");
};

export const getAllNotifications = async (
  page: number = 1,
  limit: number = 10
): Promise<{ data: Notification[]; pagination: any }> => {
  try {
    const response = await ApiService.get(
      `${NOTIFICATIONs_API}?page=${page}&limit=${limit}`
    );
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const sendNotification = async (
  Notification: SendNotification
): Promise<{ status: number; message: string }> => {
  try {
    const response = await ApiService.post(
      "/sendAdminNotification",
      Notification
    );
    const rawData = response?.data;
    return rawData;
  } catch (error) {
    throw handleApiError(error);
  }
};
