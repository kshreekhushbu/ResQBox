import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import {
  KitchenDetails,
  KitchenSummary,
  UpdateKitchenStatusPayload,
  UpdateComplianceStatusPayload,
  Pagination,
} from "./types";
import {
  ApiError,
  getAllKitchens,
  getKitchenDetailsById,
  updateKitchenStatus,
  updateComplianceStatus,
  getAdminAlerts,
  getKitchenAuditLogs,
} from "./kitchenService";
import { AdminAlert, KitchenAuditLog } from "./types";

interface KitchensState {
  kitchens: KitchenSummary[];
  kitchen: KitchenDetails | null;
  loading: boolean;
  error: string | null;
  pagination: Pagination | null;
  alerts: AdminAlert[];
  unviewedCount: number;
  alertsLoading: boolean;
  moreAlertsLoading: boolean;
  alertsPagination: import("./types").AdminAlertsPagination | null;
  auditLogs: KitchenAuditLog[];
  auditLogsPagination: Pagination | null;
  auditLogsLoading: boolean;
}

const initialState: KitchensState = {
  kitchens: [],
  kitchen: null,
  loading: false,
  error: null,
  pagination: null,
  alerts: [],
  unviewedCount: 0,
  alertsLoading: false,
  moreAlertsLoading: false,
  alertsPagination: null,
  auditLogs: [],
  auditLogsPagination: null,
  auditLogsLoading: false,
};

const handleReject = (error: unknown) => {
  if (error instanceof ApiError) return error.message;
  return "An unexpected error occurred";
};

export const fetchAllKitchens = createAsyncThunk(
  "kitchens/fetchAll",
  async (
    {
      status,
      page = 1,
      limit = 10,
      search,
    }: {
      status?: "APPROVED" | "REJECTED" | "PENDING" | "EXPIRING";
      page?: number;
      limit?: number;
      search?: string;
    } = {},
    { rejectWithValue },
  ) => {
    try {
      return await getAllKitchens(status, page, limit, search);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  },
);

export const fetchKitchenById = createAsyncThunk(
  "kitchens/fetchById",
  async (id: string, { rejectWithValue }) => {
    try {
      return await getKitchenDetailsById(id);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  },
);

export const changeKitchenStatus = createAsyncThunk(
  "kitchens/updateStatus",
  async (
    { id, payload }: { id: string; payload: UpdateKitchenStatusPayload },
    { rejectWithValue },
  ) => {
    try {
      return await updateKitchenStatus(id, payload);
    } catch (error: any) {
      if (error) {
        const message =
          error.message || error.response?.data?.message || "An error occurred";
        return rejectWithValue({
          message,
          details: error.details || error.response?.data?.details,
        });
      }
      return rejectWithValue(handleReject(error));
    }
  },
);

export const changeComplianceStatus = createAsyncThunk(
  "kitchens/updateComplianceStatus",
  async (
    { id, payload }: { id: string; payload: UpdateComplianceStatusPayload },
    { rejectWithValue },
  ) => {
    try {
      return await updateComplianceStatus(id, payload);
    } catch (error: any) {
      if (error) {
        const message =
          error.message || error.response?.data?.message || "An error occurred";
        return rejectWithValue({
          message,
          details: error.details || error.response?.data?.details,
        });
      }
      return rejectWithValue(handleReject(error));
    }
  },
);

export const fetchAdminAlerts = createAsyncThunk(
  "kitchens/fetchAlerts",
  async (
    params: { page?: number; limit?: number } | void,
    { rejectWithValue },
  ) => {
    try {
      const { page = 1, limit = 20 } =
        (params as { page?: number; limit?: number }) || {};
      return await getAdminAlerts(page, limit);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  },
);

export const fetchKitchenAuditLogs = createAsyncThunk(
  "kitchens/fetchAuditLogs",
  async (
    {
      kitchenId,
      page = 1,
      limit = 10,
    }: { kitchenId: string; page?: number; limit?: number },
    { rejectWithValue },
  ) => {
    try {
      return await getKitchenAuditLogs(kitchenId, page, limit);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  },
);

const kitchensSlice = createSlice({
  name: "kitchens",
  initialState,
  reducers: {
    clearCurrentKitchen: (state) => {
      state.kitchen = null;
    },
    clearError: (state) => {
      state.error = null;
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.loading = action.payload;
    },
    markAlertLocally: (state, action: PayloadAction<number>) => {
      state.alerts = state.alerts.map((a) =>
        a.id === action.payload
          ? { ...a, isViewed: true, viewedAt: new Date().toISOString() }
          : a,
      );
      state.unviewedCount = Math.max(0, state.unviewedCount - 1);
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchAllKitchens.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchAllKitchens.fulfilled, (state, action) => {
        state.loading = false;
        state.kitchens = action.payload.kitchens;
        state.pagination = action.payload.pagination;
      })
      .addCase(fetchAllKitchens.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(fetchKitchenById.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchKitchenById.fulfilled, (state, action) => {
        state.loading = false;
        state.kitchen = action.payload;
      })
      .addCase(fetchKitchenById.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(changeKitchenStatus.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(changeKitchenStatus.fulfilled, (state) => {
        state.loading = false;
      })
      .addCase(changeKitchenStatus.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(changeComplianceStatus.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(changeComplianceStatus.fulfilled, (state) => {
        state.loading = false;
      })
      .addCase(changeComplianceStatus.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(fetchAdminAlerts.pending, (state, action) => {
        const { page = 1 } = action.meta.arg || {};
        if (page === 1) {
          state.alertsLoading = true;
        } else {
          state.moreAlertsLoading = true;
        }
      })
      .addCase(fetchAdminAlerts.fulfilled, (state, action) => {
        state.alertsLoading = false;
        state.moreAlertsLoading = false;
        const { page = 1 } = action.meta.arg || {};

        if (page === 1) {
          state.alerts = action.payload.data;
        } else {
          // Filter out existing alerts to prevent duplicates if any
          const existingIds = new Set(state.alerts.map((a) => a.id));
          const newAlerts = action.payload.data.filter(
            (a) => !existingIds.has(a.id),
          );
          state.alerts = [...state.alerts, ...newAlerts];
        }

        state.unviewedCount = action.payload.unviewedCount;
        state.alertsPagination = action.payload.pagination;
      })
      .addCase(fetchAdminAlerts.rejected, (state) => {
        state.alertsLoading = false;
        state.moreAlertsLoading = false;
      })

      .addCase(fetchKitchenAuditLogs.pending, (state) => {
        state.auditLogsLoading = true;
      })
      .addCase(fetchKitchenAuditLogs.fulfilled, (state, action) => {
        state.auditLogsLoading = false;
        state.auditLogs = action.payload.logs;
        const p = action.payload.pagination as any;
        if (p) {
          state.auditLogsPagination = {
            totalRecords: Number(p.totalRecords ?? p.total ?? 0),
            currentPage: Number(p.currentPage ?? p.page ?? 1),
            totalPages: Number(p.totalPages ?? 1),
          };
        }
      })
      .addCase(fetchKitchenAuditLogs.rejected, (state) => {
        state.auditLogsLoading = false;
      });
  },
});

export const { clearCurrentKitchen, clearError, setLoading, markAlertLocally } =
  kitchensSlice.actions;
export default kitchensSlice.reducer;
