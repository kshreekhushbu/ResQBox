import ApiService from "@/services/config";
import { AxiosError } from "axios";
import { AddBanner, Banner } from "./types";

export interface UpdateBannerDTO extends Partial<AddBanner> {}

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

const Banner_API = "/getBanners";

const handleApiError = (error: unknown): never => {
  if (error instanceof AxiosError) {
    throw new ApiError(
      error.response?.status ?? 500,
      error.response?.data?.message ?? "Something went wrong"
    );
  }

  throw new ApiError(500, "Unexpected error");
};

export const AllBanners = async (): Promise<Banner[]> => {
  try {
    const response = await ApiService.get(Banner_API);
    return response?.data?.banners;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const BannerDetails = async (id: string): Promise<Banner> => {
  try {
    const response = await ApiService.get(`/getBannerById/${id}`);
    return response?.data?.banner;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const BannerCreate = async (
  stroyData: AddBanner
): Promise<{ message: string }> => {
  try {
    const response = await ApiService.post("/addBanner", stroyData);
    return response?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const updateBanner = async (
  id: string,
  stroyData: UpdateBannerDTO
): Promise<{ message: string }> => {
  try {
    const response = await ApiService.put(`/updateBanner/${id}`, stroyData);
    return response.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const deleteBanner = async (
  id: string
): Promise<{ message: string }> => {
  try {
    const res = await ApiService.delete(`/deleteBanner/${id}`);
    return res?.data;
  } catch (error) {
    throw handleApiError(error);
  }
};
