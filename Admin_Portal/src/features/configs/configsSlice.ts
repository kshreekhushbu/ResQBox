import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import { ConfigState, UpdateConfigPayload, Config } from "./types";
import {
  getAllConfigs as fetchAllConfigsApi,
  updateConfig as updateConfigApi,
  ApiError,
} from "./configsservice";
import { RootState } from "@/store/store";

const initialState: ConfigState = {
  configs: [],
  currentConfig: null,
  loading: false,
  error: null,
  successMessage: null,
};

const handleReject = (error: unknown) => {
  if (error instanceof ApiError) {
    return error.message;
  }
  return "An unexpected error occurred";
};

export const fetchAllConfigs = createAsyncThunk(
  "configs/fetchAll",
  async (_, { rejectWithValue }) => {
    try {
      return await fetchAllConfigsApi();
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const editConfig = createAsyncThunk(
  "configs/edit",
  async (
    data: UpdateConfigPayload,
    { rejectWithValue }
  ) => {
    try {
      return await updateConfigApi(data);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

const configsSlice = createSlice({
  name: "configs",
  initialState,
  reducers: {
    setCurrentConfig: (state, action) => {
      // Find config by ID (number)
      const configId = Number(action.payload);
      state.currentConfig = state.configs.find((c) => c.configId === configId) || null;
    },
    clearCurrentConfig: (state) => {
      state.currentConfig = null;
    },
    clearError: (state) => {
      state.error = null;
    },
    clearSuccessMessage: (state) => {
      state.successMessage = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Fetch All
      .addCase(fetchAllConfigs.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchAllConfigs.fulfilled, (state, action) => {
        state.loading = false;
        state.configs = action.payload;
      })
      .addCase(fetchAllConfigs.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // Edit
      .addCase(editConfig.pending, (state) => {
        state.loading = true;
        state.error = null;
        state.successMessage = null;
      })
      .addCase(editConfig.fulfilled, (state) => {
        state.loading = false;
        state.successMessage = "Config updated successfully";
      })
      .addCase(editConfig.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      });
  },
});

export const { setCurrentConfig, clearCurrentConfig, clearError, clearSuccessMessage } = configsSlice.actions;
export default configsSlice.reducer;
