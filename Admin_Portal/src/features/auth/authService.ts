import ApiService from "@/services/config";
import { ResetPayload, SendPayload, VerifyPayload } from "./types";

export const loginUser = async (credentials: {
  emailId: string;
  password: string;
}): Promise<any> => {
  const response = await ApiService.post("/adminLogin", credentials);
  return {
    user: response?.data?.adminDetails,
    token: response?.data?.Token,
    permissions: response?.data?.permissions,
    roleId: response?.data?.adminDetails?.role_id,
  };
};

export const logoutUser = async () => {
  const response = await ApiService.post("/logout");
  return response.data;
};

export const sendOTP = async (
  credentials: SendPayload,
): Promise<{ status: number; message: string }> => {
  const res = await ApiService.post("/sendForgotPasswordOTP", credentials);
  return res?.data;
};

export const verifyOTP = async (
  credentials: VerifyPayload,
): Promise<{ status: number; message: string; email: string }> => {
  const res = await ApiService.post("/verifyForgotPasswordOTP", credentials);
  return res?.data;
};

export const ResetPassword = async (
  credentials: ResetPayload,
): Promise<{ Message: string }> => {
  const res = await ApiService.post("/resetPassword", credentials);
  return res?.data;
};
