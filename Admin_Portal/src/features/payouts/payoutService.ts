import ApiService from "@/services/config";
import { AxiosError } from "axios";
import { Payout, Order, OrdersResponse, PayoutsResponse } from "./types";

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

const Payout_API = "/getCurrentPayouts";

const handleApiError = (error: unknown): never => {
  if (error instanceof AxiosError) {
    throw new ApiError(
      error.response?.status ?? 500,
      error.response?.data?.message ?? "Something went wrong",
    );
  }

  throw new ApiError(500, "Unexpected error");
};

export const AllPayouts = async (
  page: number = 1,
  limit: number = 10,
  search: string = "",
  status: string = "",
): Promise<PayoutsResponse> => {
  try {
    const response = await ApiService.get(
      `${Payout_API}?page=${page}&limit=${limit}&search=${search}&status=${status}`,
    );
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const getOrdersByKitchenId = async (
  kitchenId: string | number,
  page: number = 1,
  limit: number = 10,
): Promise<OrdersResponse> => {
  try {
    const response = await ApiService.get(
      `/getOrdersByKitchenId/${kitchenId}?page=${page}&limit=${limit}`,
    );
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export interface PayoutSuccessResponse {
  success: boolean;
  payoutId: number;
  amountPaid: number;
  totalCredits: number;
  platformFeesDeducted: number;
  invoice: {
    invoiceId: number;
    invoiceNumber: string;
    pdfUrl: string;
  };
  message?: string;
}

export const payKitchen = async (payload: {
  kitchenId: number;
  from: string;
  to: string;
}): Promise<PayoutSuccessResponse> => {
  try {
    const response = await ApiService.post<PayoutSuccessResponse>(
      "/payKitchen",
      payload,
    );
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};
