export interface Notification {
  id: number;
  title: string;
  message: string;
  ownerType: string;
  type: number;
  createdAt: string;
}

export interface SendNotification {
  title: string;
  message: string;
  type: string;
}

export interface Pagination {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface NotificationsResponse {
  data: Notification[];
  pagination: Pagination;
}
