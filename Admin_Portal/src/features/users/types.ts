export interface User {
  userId: number;
  name: string;
  phoneNumber: string;
  email: string;
  profilePicture: string | null;
  deviceToken: string;
  status: "ACTIVE" | "INACTIVE" | "DELETING_SOON";
  isDeletingSoon: boolean;
  reasonType: string | null;
  reasonText: string | null;
  requestedAt: string | null;
  scheduledDeletionAt: string | null;
  requestStatus: string | null;
  isSeen: boolean;
  deactivationReason?: string; // Keeping for backward compatibility if needed, but should prefer reasonText
  deactivationReasonType?: string; // Keeping for backward compatibility if needed, but should prefer reasonType
}

export type UserFilterStatus = "ACTIVE" | "INACTIVE" | "DELETING_SOON" | "";

export type UserStatusType = "ACTIVE" | "INACTIVE";

export type DeactivationReasonType =
  | "Fraud"
  | "Policy Violation"
  | "Payment Issues"
  | "Suspicious Activity"
  | "Terms of Service Breach"
  | "Spam/Abuse"
  | "Others";

export interface UpdateUserStatusPayload {
  userId: number;
  status: UserStatusType;
  reasonType?: DeactivationReasonType;
  reasonText?: string;
}

export interface Pagination {
  currentPage: number;
  totalPages: number;
  totalUsers: number;
}

export interface UsersResponse {
  status: number;
  message: string;
  users: User[];
  pagination: Pagination;
}

export interface UsersState {
  users: User[];
  pagination: Pagination | null;
  loading: boolean;
  error: string | null;
  filters: {
    search: string;
    page: number;
    limit: number;
    filter: UserFilterStatus;
  };
  successMessage: string | null;
  hasDeletionRequests: boolean;
}
