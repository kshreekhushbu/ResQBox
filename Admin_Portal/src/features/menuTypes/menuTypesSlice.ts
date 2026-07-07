import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import { AddMenuType, MenuType } from "./types";
import { Pagination } from "../categories/types";
import {
  getAllMenuTypes,
  getMenuTypeById,
  createMenuType,
  updateMenuType,
  deleteMenuType,
  ApiError,
} from "./menuTypesService";

interface MenuTypesState {
  menuTypes: MenuType[];
  loading: boolean;
  error: string | null;
  pagination: Pagination | null;
}

const initialState: MenuTypesState = {
  menuTypes: [],
  loading: false,
  error: null,
  pagination: null,
};

const handleReject = (error: unknown) => {
  if (error instanceof ApiError) {
    return error.message;
  }
  return "An unexpected error occurred";
};

export const getAllMenuTypesThunk = createAsyncThunk(
  "menuTypes/getAll",
  async (
    {
      page,
      limit,
      search,
    }: { page: number; limit: number; search?: string } = {
      page: 1,
      limit: 10,
    },
    { rejectWithValue },
  ) => {
    try {
      return await getAllMenuTypes(page, limit, search);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  },
);

export const getMenuTypeByIdThunk = createAsyncThunk(
  "menuTypes/getById",
  async (id: string, { rejectWithValue }) => {
    try {
      return await getMenuTypeById(id);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  },
);

export const createMenuTypeThunk = createAsyncThunk(
  "menuTypes/create",
  async (data: AddMenuType, { rejectWithValue }) => {
    try {
      return await createMenuType(data);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  },
);

export const updateMenuTypeThunk = createAsyncThunk(
  "menuTypes/update",
  async ({ id, data }: { id: string; data: any }, { rejectWithValue }) => {
    try {
      return await updateMenuType(id, data);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  },
);

export const deleteMenuTypeThunk = createAsyncThunk(
  "menuTypes/delete",
  async (id: string, { rejectWithValue }) => {
    try {
      return await deleteMenuType(id);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  },
);

const menuTypesSlice = createSlice({
  name: "menuTypes",
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Get All
      .addCase(getAllMenuTypesThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getAllMenuTypesThunk.fulfilled, (state, action) => {
        state.loading = false;
        state.menuTypes = action.payload.menuTypes;
        state.pagination = action.payload.pagination;
      })
      .addCase(getAllMenuTypesThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // Create
      .addCase(createMenuTypeThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(createMenuTypeThunk.fulfilled, (state) => {
        state.loading = false;
      })
      .addCase(createMenuTypeThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // Update
      .addCase(updateMenuTypeThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(updateMenuTypeThunk.fulfilled, (state) => {
        state.loading = false;
      })
      .addCase(updateMenuTypeThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // Delete
      .addCase(deleteMenuTypeThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(deleteMenuTypeThunk.fulfilled, (state) => {
        state.loading = false;
      })
      .addCase(deleteMenuTypeThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      });
  },
});

export const { clearError } = menuTypesSlice.actions;
export default menuTypesSlice.reducer;
