export interface Address {
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

export interface Payout {
  kitchenId: number;
  restaurantCode: string;
  restaurantName: string;
  address: Address;
  orders: number;
  amount: number;
  status: string;
  canPay: boolean;
  periodStart: string;
  periodEnd: string;
}

export interface PayoutsResponse {
  data: Payout[];
  pagination: {
    totalKitchens: number;
    currentPage: number;
    totalPages: number;
  };
}

export interface Order {
  orderId: number;
  orderDisplayId: string;
  numberOfItems: number;
  totalAmount: number;
  status: string;
  orderedAt: string;
}

export interface OrdersResponse {
  status: number;
  message: string;
  orders: Order[];
  pagination: {
    totalOrders: number;
    currentPage: number;
    totalPages: number;
  };
}
