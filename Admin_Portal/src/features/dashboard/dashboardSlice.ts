import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import { DashboardState } from "./types";
import { fetchDashboardData, ApiError } from "./dashboardService";

const initialState: DashboardState = {
  data: null,
  isLoading: false,
  error: null,
};

const handleReject = (error: unknown) => {
  if (error instanceof ApiError) {
    return error.message;
  }
  return "An unexpected error occurred";
};

export const getDashboardData = createAsyncThunk(
  "dashboard/fetchData",
  async (_, { rejectWithValue }) => {
    try {
      const response = await fetchDashboardData();
      return response.data;
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

const dashboardSlice = createSlice({
  name: "dashboard",
  initialState,
  reducers: {
    clearDashboardError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(getDashboardData.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(getDashboardData.fulfilled, (state, action) => {
        state.isLoading = false;
        state.data = action.payload;
      })
      .addCase(getDashboardData.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      });
  },
});

export const { clearDashboardError } = dashboardSlice.actions;
export default dashboardSlice.reducer;
