export interface MonthlyOrderTrend {
  month: string;
  orders: number;
}

export interface FoodType {
  id: number;
  name: string;
  image: string;
}

export interface DashboardData {
  totalRestaurants: number;
  pendingApprovals: number;
  approvedRestaurants: number;
  totalOrders: number;
  totalUsers: number;
  expiringSoon: number;
  monthlyAmount: number;
  todayorders: number;
  monthlyOrderTrends: MonthlyOrderTrend[];
  foodTypes: FoodType[];
}

export interface DashboardResponse {
  status: number;
  message: string;
  data: DashboardData;
}

export interface DashboardState {
  data: DashboardData | null;
  isLoading: boolean;
  error: string | null;
}
