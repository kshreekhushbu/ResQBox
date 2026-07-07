export enum OrderStatus {
  PENDING = "PENDING",
  PAYMENT_PENDING = "PAYMENT_PENDING",
  ACCEPTED = "ACCEPTED",
  PREPARING = "PREPARING",
  READY = "READY",
  PICKED = "PICKED",
  NO_SHOW = "NO_SHOW",
  CANCELLED = "CANCELLED",
  REJECTED = "REJECTED",
}

export interface User {
  userId: number;
  name: string;
  phoneNumber: string;
}

export interface Kitchen {
  kitchenId: number;
  kitchenName: string;
  kitchenImage?: string;
  address?: {
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
  };
}

export interface Order {
  orderId: number;
  orderUid: string;
  orderNumber: number;
  userId: number;
  kitchenId: number;
  deliveryType: string;
  status: OrderStatus;
  itemTotal: number;
  gstAmount: number;
  platformFee: number;
  discount: number;
  totalAmount: number;
  pickupId: string;
  paymentMethod: string;
  paymentStatus: string;
  orderedAt: string;
  updatedAt: string;
  acceptedAt: string | null;
  preparedAt: string | null;
  cancelReason: string | null;
  cancelledAt: string | null;
  rating: string;
  user?: User;
  kitchen: Kitchen;
}

export interface Pagination {
  totalOrders: number;
  currentPage: number;
  totalPages: number;
}

export interface OrdersResponse {
  status: number;
  message: string;
  orders: Order[];
  pagination: Pagination;
}

export interface OrderItem {
  menuItemId: number;
  name: string;
  quantity: number;
  image: string;
  startTime: string;
  endTime: string;
}

export interface OrderDetails extends Order {
  orderDisplayId: string;
  items: OrderItem[];
  taxPercent: number;
}

export interface OrderDetailsResponse {
  status: number;
  message: string;
  order: OrderDetails;
}

export interface OrdersState {
  orders: Order[];
  selectedOrder: OrderDetails | null;
  pagination: Pagination | null;
  loading: boolean;
  error: string | null;
  filters: {
    page: number;
    limit: number;
    status: OrderStatus | null;
    search: string | null;
  };
}
