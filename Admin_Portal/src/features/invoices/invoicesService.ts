import ApiService from "@/services/config";
import { AxiosError } from "axios";
import { Invoice } from "./types";

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

const INVOICES_API = "/getInvoices";
const MONTHLY_INVOICES_API = "/getMonthlyInvoices";

const handleApiError = (error: unknown): never => {
  if (error instanceof AxiosError) {
    throw new ApiError(
      error.response?.status ?? 500,
      error.response?.data?.message ?? "Something went wrong"
    );
  }
  throw new ApiError(500, "Unexpected error");
};

export const getAllInvoices = async (): Promise<Invoice[]> => {
  try {
    const response = await ApiService.get(INVOICES_API);
    const rawData = response?.data?.data;
    return rawData;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const getMonthlyInvoices = async (): Promise<Invoice[]> => {
  try {
    const response = await ApiService.get(MONTHLY_INVOICES_API);
    const rawData = response?.data?.data;
    return rawData;
  } catch (error) {
    throw handleApiError(error);
  }
};
