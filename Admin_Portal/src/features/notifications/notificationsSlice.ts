import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import { Notification, SendNotification } from "./types";
import {
  getAllNotifications,
  sendNotification as sendNotificationApi,
  ApiError,
} from "./notifivationsService";

const handleReject = (error: unknown) => {
  if (error instanceof ApiError) {
    return error.message;
  }
  return "An unexpected error occurred";
};

export const fetchAllNotifications = createAsyncThunk(
  "notifications/fetchAll",
  async (
    { page, limit }: { page: number; limit: number },
    { rejectWithValue }
  ) => {
    try {
      return await getAllNotifications(page, limit);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const sendNotification = createAsyncThunk(
  "notifications/send",
  async (data: SendNotification, { rejectWithValue }) => {
    try {
      return await sendNotificationApi(data);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

const notificationsSlice = createSlice({
  name: "notifications",
  initialState: {
    notifications: [],
    loading: false,
    error: null,
    pagination: {
      page: 1,
      limit: 10,
      total: 0,
      totalPages: 0,
    },
  },
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.loading = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchAllNotifications.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchAllNotifications.fulfilled, (state, action) => {
        state.loading = false;
        state.notifications = action.payload.data;
        state.pagination = action.payload.pagination;
      })
      .addCase(fetchAllNotifications.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      .addCase(sendNotification.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(sendNotification.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(sendNotification.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      });
  },
});

export const { clearError, setLoading } = notificationsSlice.actions;
export default notificationsSlice.reducer;
