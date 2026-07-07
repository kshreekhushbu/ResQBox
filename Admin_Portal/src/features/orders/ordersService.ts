import ApiService from "@/services/config";
import { OrdersResponse, OrderDetailsResponse, OrderStatus } from "./types";

export const getAllOrders = async (
  page: number = 1,
  limit: number = 10,
  status: OrderStatus | null = null,
  search: string | null = null,
): Promise<OrdersResponse> => {
  const queryParams = new URLSearchParams({
    page: page.toString(),
    limit: limit.toString(),
  });

  if (status) {
    queryParams.append("status", status);
  }

  if (search) {
    queryParams.append("search", search);
  }

  const response = await ApiService.get<OrdersResponse>(
    `/adminGetAllOrders?${queryParams.toString()}`,
  );
  return response.data;
};

export const getOrderDetails = async (
  orderUid: string,
): Promise<OrderDetailsResponse> => {
  const response = await ApiService.get<OrderDetailsResponse>(
    `/getOrderDetails/${orderUid}`,
  );
  return response.data;
};
