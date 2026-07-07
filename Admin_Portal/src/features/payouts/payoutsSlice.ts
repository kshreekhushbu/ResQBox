import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";

import { Payout, Order } from "./types";
import {
  AllPayouts,
  ApiError,
  getOrdersByKitchenId,
  payKitchen,
} from "./payoutService";

interface PayoutsState {
  payouts: Payout[];
  kitchenOrders: Order[];
  pagination: {
    totalOrders: number;
    currentPage: number;
    totalPages: number;
  } | null;
  payoutsPagination: {
    totalKitchens: number;
    currentPage: number;
    totalPages: number;
  } | null;
  loading: boolean;
  error: string | null;
}

const initialState: PayoutsState = {
  payouts: [],
  kitchenOrders: [],
  pagination: null,
  payoutsPagination: null,
  loading: false,
  error: null,
};

const handleReject = (error: unknown) => {
  if (error instanceof ApiError) {
    return error.message;
  }
  return "An unexpected error occurred";
};

export const getAllPayouts = createAsyncThunk(
  "payouts/fetchAll",
  async (
    {
      page = 1,
      limit = 10,
      search = "",
      status = "",
    }: { page?: number; limit?: number; search?: string; status?: string } = {},
    { rejectWithValue },
  ) => {
    try {
      return await AllPayouts(page, limit, search, status);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  },
);

export const getKitchenOrders = createAsyncThunk(
  "payouts/fetchKitchenOrders",
  async (
    {
      kitchenId,
      page,
      limit,
    }: {
      kitchenId: string | number;
      page?: number;
      limit?: number;
    },
    { rejectWithValue },
  ) => {
    try {
      return await getOrdersByKitchenId(kitchenId, page, limit);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  },
);

export const processPayout = createAsyncThunk(
  "payouts/processPayout",
  async (
    payload: { kitchenId: number; from: string; to: string },
    { rejectWithValue, dispatch },
  ) => {
    try {
      const response = await payKitchen(payload);
      await dispatch(getAllPayouts({}));
      return response;
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  },
);

const payoutsSlice = createSlice({
  name: "payouts",
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.loading = action.payload;
    },
    clearKitchenOrders: (state) => {
      state.kitchenOrders = [];
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(getAllPayouts.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getAllPayouts.fulfilled, (state, action) => {
        state.loading = false;
        state.payouts = action.payload.data;
        state.payoutsPagination = action.payload.pagination;
      })
      .addCase(getAllPayouts.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      .addCase(getKitchenOrders.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getKitchenOrders.fulfilled, (state, action) => {
        state.loading = false;
        state.kitchenOrders = action.payload.orders;
        state.pagination = action.payload.pagination;
      })
      .addCase(getKitchenOrders.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      .addCase(processPayout.pending, (state) => {
        state.loading = true;
      })
      .addCase(processPayout.fulfilled, (state) => {
        state.loading = false;
        state.error = null;
      })
      .addCase(processPayout.rejected, (state) => {
        state.loading = false;
        // Error handled via toast in the component
      });
  },
});

export const { clearError, setLoading, clearKitchenOrders } =
  payoutsSlice.actions;
export default payoutsSlice.reducer;
