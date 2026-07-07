import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import { Invoice } from "./types";
import {
  getAllInvoices,
  getMonthlyInvoices,
  ApiError,
} from "./invoicesService";

interface InvoicesState {
  invoices: Invoice[];
  currentInvoice: Invoice | null;
  loading: boolean;
  error: string | null;
}

const initialState: InvoicesState = {
  invoices: [],
  currentInvoice: null,
  loading: false,
  error: null,
};

const handleReject = (error: unknown) => {
  if (error instanceof ApiError) {
    return error.message;
  }
  return "An unexpected error occurred";
};

export const fetchAllInvoices = createAsyncThunk(
  "invoices/fetchAll",
  async (_, { rejectWithValue }) => {
    try {
      return await getAllInvoices();
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const fetchMonthlyInvoices = createAsyncThunk(
  "invoices/fetchMonthly",
  async (_, { rejectWithValue }) => {
    try {
      return await getMonthlyInvoices();
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

const invoicesSlice = createSlice({
  name: "invoices",
  initialState,
  reducers: {
    clearCurrentInvoice: (state) => {
      state.currentInvoice = null;
    },
    clearError: (state) => {
      state.error = null;
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.loading = action.payload;
    },
    setInvoices: (state, action: PayloadAction<Invoice[]>) => {
      state.invoices = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchAllInvoices.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchAllInvoices.fulfilled, (state, action) => {
        state.loading = false;
        state.invoices = action.payload;
      })
      .addCase(fetchAllInvoices.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      .addCase(fetchMonthlyInvoices.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchMonthlyInvoices.fulfilled, (state, action) => {
        state.loading = false;
        state.invoices = action.payload;
      })
      .addCase(fetchMonthlyInvoices.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      });
  },
});

export const { clearCurrentInvoice, clearError, setLoading } =
  invoicesSlice.actions;
export default invoicesSlice.reducer;
