import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import {
  OrdersState,
  OrderStatus,
  OrdersResponse,
  OrderDetailsResponse,
} from "./types";
import { getAllOrders, getOrderDetails } from "./ordersService";

const initialState: OrdersState = {
  orders: [],
  selectedOrder: null,
  pagination: null,
  loading: false,
  error: null,
  filters: {
    page: 1,
    limit: 10,
    status: null,
    search: null,
  },
};

export const fetchOrders = createAsyncThunk(
  "orders/fetchOrders",
  async (
    params: {
      page?: number;
      limit?: number;
      status?: OrderStatus | null;
      search?: string | null;
    },
    { rejectWithValue },
  ) => {
    try {
      const { page = 1, limit = 10, status = null, search = null } = params;
      const response = await getAllOrders(page, limit, status, search);
      if (response.status === 0) {
        return rejectWithValue(response.message || "Something went wrong.");
      }

      return response;
    } catch (error: any) {
      return rejectWithValue(
        error.response?.data?.message || "Failed to fetch orders",
      );
    }
  },
);

export const fetchOrderDetails = createAsyncThunk(
  "orders/fetchOrderDetails",
  async (orderUid: string, { rejectWithValue }) => {
    try {
      const response = await getOrderDetails(orderUid);
      return response;
    } catch (error: any) {
      return rejectWithValue(
        error.response?.data?.message || "Failed to fetch order details",
      );
    }
  },
);

const ordersSlice = createSlice({
  name: "orders",
  initialState,
  reducers: {
    setPage: (state, action: PayloadAction<number>) => {
      state.filters.page = action.payload;
    },
    setLimit: (state, action: PayloadAction<number>) => {
      state.filters.limit = action.payload;
    },
    setStatusFilter: (state, action: PayloadAction<OrderStatus | null>) => {
      state.filters.status = action.payload;
      state.filters.page = 1;
    },
    setSearchFilter: (state, action: PayloadAction<string | null>) => {
      state.filters.search = action.payload;
      state.filters.page = 1;
    },
    clearSelectedOrder: (state) => {
      state.selectedOrder = null;
    },
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Fetch Orders
      .addCase(fetchOrders.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(
        fetchOrders.fulfilled,
        (state, action: PayloadAction<OrdersResponse>) => {
          state.loading = false;
          state.orders = action.payload.orders;
          state.pagination = action.payload.pagination;
        },
      )
      .addCase(fetchOrders.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
        state.orders = [];
        state.pagination = null;
      })
      .addCase(fetchOrderDetails.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(
        fetchOrderDetails.fulfilled,
        (state, action: PayloadAction<OrderDetailsResponse>) => {
          state.loading = false;
          state.selectedOrder = action.payload.order;
        },
      )
      .addCase(fetchOrderDetails.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      });
  },
});

export const {
  setPage,
  setLimit,
  setStatusFilter,
  setSearchFilter,
  clearSelectedOrder,
  clearError,
} = ordersSlice.actions;

export default ordersSlice.reducer;
