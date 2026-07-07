export type KitchenStatus = "PENDING" | "APPROVED" | "REJECTED" | "EXPIRING";

export interface KitchenAddress {
  addressId: number;
  kitchenId: number;
  houseNo: string;
  street: string;
  pincode: string;
  state: string;
  city: string;
  country: string;
  landmark: string;
  latitude: number;
  longitude: number;
}

export interface FoodCertificate {
  image: string;
  expireDate: string;
  addedAt: string;
}

export interface KitchenKyc {
  abnNumber?: string;
  acn?: string;
  foodCertificateNumber?: string;
  foodCertificateImage?: string;
  foodCertificateImages?: FoodCertificate[];
  expireDate?: string;
  fssaiNumber?: string;
}

export interface KitchenPhotos {
  kitchenImages: string[];
  kitchenProfilePhoto: string;
}

export interface KitchenCuisine {
  id: number;
  name: string;
  isActive: number;
  image: string;
  createdAt: string;
  updatedAt: string;
  isPopular?: number;
}

export interface MenuItem {
  id: number;
  name: string;
  quantity: number;
  price: number;
  description: string;
  isVegetarian: boolean;
  isSpicy: "MILD" | "NORMAL" | "HOT";
  rating: string;
  ratingCount: number;
  isActive: number;
  image: string | null;
}

export interface KitchenSummary {
  kitchenId: number;
  kitchenName: string;
  email: string;
  ownerName: string;
  contactNumber: string;
  openingTime: string;
  closingTime: string;
  description: string;
  status: KitchenStatus;
  isActive: number;
  rating: string;
  ratingCount: number;
  createdAt: string;
  deviceToken?: string;
  address: KitchenAddress;
  photos: KitchenPhotos;
  cuisines: KitchenCuisine[];
  stripeAccountId?: string;
  stripeAccountConnected?: boolean;
  stripeOnboardingCompleted?: boolean;
  stripeConnectedAt?: string;
  complianceStatus?: string;
}

export interface KitchenDetails extends KitchenSummary {
  kyc?: KitchenKyc;
  items: MenuItem[];
}

export interface UpdateKitchenStatusPayload {
  status: KitchenStatus;
  reason?: string;
}

export interface UpdateComplianceStatusPayload {
  status: "APPROVED" | "REJECTED";
  expireDate?: string;
  reason?: string;
}

export interface UpdateKitchenStripeAccountIdPayload {
  stripeAccountId: string;
}

export interface Pagination {
  totalRecords: number;
  currentPage: number;
  totalPages: number;
}

export interface AdminAlertMetadata {
  addedAt?: string;
  expireDate?: string;
  certificateImage?: string;
  [key: string]: any;
}

export interface AdminAlertKitchen {
  kitchenId: number;
  kitchenName: string;
}

export interface AdminAlert {
  id: number;
  kitchenId: number | null;
  userId: number | null;
  alertType: string;
  title: string;
  message: string;
  isViewed: boolean;
  viewedAt: string | null;
  viewedBy: number | null;
  createdAt: string;
  metadata: AdminAlertMetadata;
  kitchen?: AdminAlertKitchen;
}

export interface AdminAlertsPagination {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface AdminAlertsResponse {
  status: number;
  message: string;
  data: AdminAlert[];
  pagination: AdminAlertsPagination;
  unviewedCount: number;
}

export interface KitchenAuditLog {
  id: number;
  kitchenId: number;
  actorType: string;
  actorId: number;
  actorName: string;
  actorRole: string;
  actionType: string;
  actionDescription: string;
  oldData: string | number | object | null;
  newData: string | number | object | null;
  reason: string | null;
  notes: string | null;
  resourceType: string | null;
  resourceId: number | null;
  metadata: Record<string, any> | null;
  ipAddress: string | null;
  userAgent: string | null;
  createdAt: string;
}

export interface KitchenAuditLogsResponse {
  status: number;
  message: string;
  kitchen: {
    kitchenId: number;
    kitchenName: string;
    status: string;
  };
  logs: KitchenAuditLog[];
  pagination: Pagination;
}
