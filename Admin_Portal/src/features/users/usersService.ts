import ApiService from "@/services/config";
import { UsersResponse } from "./types";

export const getAllUsers = async (
  page: number = 1,
  limit: number = 10,
  search: string = "",
  filter: string = "",
): Promise<UsersResponse> => {
  const queryParams = new URLSearchParams({
    page: page.toString(),
    limit: limit.toString(),
  });

  if (search) {
    queryParams.append("search", search);
  }

  if (filter) {
    queryParams.append("filter", filter);
  }

  const response = await ApiService.get<UsersResponse>(
    `/getAllUserDetails?${queryParams.toString()}`,
  );
  return response.data;
};

export const updateUserStatus = async (
  userId: number,
  data: {
    status: "ACTIVE" | "INACTIVE";
    reasonType?: string;
    reasonText?: string;
  },
): Promise<any> => {
  const response = await ApiService.put(`/updateUserStatus/${userId}`, data);
  return response.data;
};

export const checkPendingDeletions = async (): Promise<boolean> => {
  const response = await ApiService.get<UsersResponse>(
    `/getAllUserDetails?page=1&limit=1&filter=DELETING_SOON`,
  );
  const users = response?.data?.users || [];
  return users.some((u) => !u.isSeen);
};

export const markDeletionsSeen = async (): Promise<UsersResponse> => {
  const response = await ApiService.get<UsersResponse>(
    `/getAllUserDetails?filter=DELETING_SOON&isSeen=1`,
  );
  return response.data;
};
