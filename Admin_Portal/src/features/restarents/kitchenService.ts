import ApiService from "@/services/config";
import { AxiosError } from "axios";
import {
  KitchenDetails,
  KitchenSummary,
  UpdateKitchenStatusPayload,
  UpdateComplianceStatusPayload,
  UpdateKitchenStripeAccountIdPayload,
  Pagination,
} from "./types";

export class ApiError extends Error {
  status: number;
  details?: any;

  constructor(Status: number, Message: string, Details?: any) {
    super(Message);
    this.status = Status;
    this.details = Details;
    this.name = "Kitchen API Error";
  }
}

const handleApiError = (error: any): never => {
  if (error?.response) {
    const status = error.response.status ?? 500;
    const data = error.response.data;
    const message = data?.message || "Something went wrong";
    const details = data?.details;

    throw new ApiError(status, message, details);
  }
  throw new ApiError(500, "Unexpected error");
};

export const getAllKitchens = async (
  status?: "APPROVED" | "REJECTED" | "PENDING" | "EXPIRING",
  page: number = 1,
  limit: number = 10,
  search?: string,
): Promise<{ kitchens: KitchenSummary[]; pagination: Pagination }> => {
  try {
    const params = new URLSearchParams();
    if (status) params.append("status", status);
    params.append("page", page.toString());
    params.append("limit", limit.toString());
    if (search && search.trim()) {
      params.append("search", search.trim());
    }

    const res = await ApiService.get(`/getAllKitchens?${params.toString()}`);
    return {
      kitchens: res?.data?.kitchens ?? [],
      pagination: res?.data?.pagination,
    };
  } catch (error) {
    throw handleApiError(error);
  }
};

export const getKitchenDetailsById = async (
  id: string,
): Promise<KitchenDetails> => {
  try {
    const res = await ApiService.get(`/getKitchenDetailsById/${id}`);
    return res?.data?.kitchen;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const updateKitchenStatus = async (
  id: string,
  payload: UpdateKitchenStatusPayload,
): Promise<{ message: string }> => {
  try {
    const res = await ApiService.put(`/updateKitchenStatus/${id}`, payload);
    return res?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const updateComplianceStatus = async (
  id: string,
  payload: UpdateComplianceStatusPayload,
): Promise<{ message: string }> => {
  try {
    const res = await ApiService.put(`/updateComplianceStatus/${id}`, payload);
    return res?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const updateKitchenStripeAccountId = async (
  kitchenId: string,
  payload: UpdateKitchenStripeAccountIdPayload,
): Promise<{ message: string }> => {
  try {
    const res = await ApiService.put(
      `/updateKitchenStripeAccountId/${kitchenId}`,
      payload,
    );
    return res?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const getAdminAlerts = async (
  page: number = 1,
  limit: number = 20,
): Promise<import("./types").AdminAlertsResponse> => {
  try {
    const params = new URLSearchParams();
    params.append("page", page.toString());
    params.append("limit", limit.toString());

    const res = await ApiService.get(`/getAdminAlerts?${params.toString()}`);
    return res?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const markAlertAsViewed = async (
  alertId: number,
): Promise<{ message: string }> => {
  try {
    const res = await ApiService.put(`/markAlertAsViewed/${alertId}`);
    return res?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const getKitchenAuditLogs = async (
  kitchenId: string,
  page: number = 1,
  limit: number = 10,
): Promise<import("./types").KitchenAuditLogsResponse> => {
  try {
    const res = await ApiService.get(
      `/audit-logs/kitchen/${kitchenId}?page=${page}&limit=${limit}`,
    );
    return res?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};
