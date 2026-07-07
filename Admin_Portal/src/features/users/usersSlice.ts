import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import {
  UsersState,
  UsersResponse,
  UpdateUserStatusPayload,
  UserFilterStatus,
} from "./types";
import {
  getAllUsers,
  updateUserStatus as updateUserStatusApi,
  checkPendingDeletions,
  markDeletionsSeen,
} from "./usersService";

const initialState: UsersState = {
  users: [],
  pagination: null,
  loading: false,
  error: null,
  filters: {
    search: "",
    page: 1,
    limit: 10,
    filter: "",
  },
  successMessage: null,
  hasDeletionRequests: false,
};

export const fetchUsers = createAsyncThunk(
  "users/fetchUsers",
  async (
    params: { page?: number; limit?: number; search?: string; filter?: string },
    { rejectWithValue },
  ) => {
    try {
      const { page = 1, limit = 10, search = "", filter = "" } = params;
      const response = await getAllUsers(page, limit, search, filter);
      return response;
    } catch (error: any) {
      return rejectWithValue(
        error.response?.data?.message || "Failed to fetch users",
      );
    }
  },
);

export const updateUserStatus = createAsyncThunk(
  "users/updateUserStatus",
  async (
    payload: {
      userId: number;
      data: {
        status: "ACTIVE" | "INACTIVE";
        reasonType?: string;
        reasonText?: string;
      };
    },
    { rejectWithValue },
  ) => {
    try {
      const response = await updateUserStatusApi(payload.userId, payload.data);
      return response;
    } catch (error: any) {
      return rejectWithValue(
        error.response?.data?.message || "Failed to update user status",
      );
    }
  },
);

export const checkDeletionRequests = createAsyncThunk(
  "users/checkDeletionRequests",
  async () => {
    try {
      return await checkPendingDeletions();
    } catch {
      return false;
    }
  },
);

export const markDeletionsSeenThunk = createAsyncThunk(
  "users/markDeletionsSeen",
  async () => {
    try {
      await markDeletionsSeen();
      return true;
    } catch {
      return false;
    }
  },
);

const usersSlice = createSlice({
  name: "users",
  initialState,
  reducers: {
    setSearch: (state, action: PayloadAction<string>) => {
      state.filters.search = action.payload;
      state.filters.page = 1; // Reset to first page
    },
    setPage: (state, action: PayloadAction<number>) => {
      state.filters.page = action.payload;
    },
    setLimit: (state, action: PayloadAction<number>) => {
      state.filters.limit = action.payload;
    },
    clearError: (state) => {
      state.error = null;
    },
    clearSuccessMessage: (state) => {
      state.successMessage = null;
    },
    setFilter: (state, action: PayloadAction<UserFilterStatus>) => {
      state.filters.filter = action.payload;
      state.filters.page = 1;
    },
    resetPagination: (state) => {
      state.filters.page = 1;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchUsers.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(
        fetchUsers.fulfilled,
        (state, action: PayloadAction<UsersResponse>) => {
          state.loading = false;
          state.users = action.payload.users;
          state.pagination = action.payload.pagination;
        },
      )
      .addCase(fetchUsers.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      .addCase(updateUserStatus.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(updateUserStatus.fulfilled, (state, action) => {
        state.loading = false;
        state.successMessage =
          action.payload.message || "User status updated successfully";
        const updatedUser = action.payload.user;
        if (updatedUser) {
          const index = state.users.findIndex(
            (user) => user.userId === updatedUser.userId,
          );
          if (index !== -1) {
            state.users[index] = {
              ...state.users[index],
              status: updatedUser.status,
              reasonText: action.meta.arg.data.reasonText,
              reasonType: action.meta.arg.data.reasonType,
            };
          }
        }
      })
      .addCase(updateUserStatus.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      .addCase(checkDeletionRequests.fulfilled, (state, action) => {
        state.hasDeletionRequests = action.payload;
      })
      .addCase(markDeletionsSeenThunk.fulfilled, (state) => {
        state.hasDeletionRequests = false;
      });
  },
});

export const {
  setSearch,
  setPage,
  setLimit,
  clearError,
  clearSuccessMessage,
  setFilter,
  resetPagination,
} = usersSlice.actions;

export default usersSlice.reducer;
