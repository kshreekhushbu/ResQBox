export interface SendPayload {
  email: string;
}

export interface VerifyPayload {
  email: string;
  otp: string;
}

export interface ResetPayload {
  email: string;
  newPassword: string;
  confirmPassword: string;
}

export interface Permission {
  PageName: string;
  edit: number;
  read: number;
  write: number;
  delete: number;
}

export interface PermissionData {
  permissions?: Permission[];
}
