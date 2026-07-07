import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import { AddFoodType, FoodType } from "./types";
import { Pagination } from "../categories/types";
import {
  getAllFoodTypes,
  getFoodTypeById,
  createFoodType,
  updateFoodType,
  deleteFoodType,
  ApiError,
} from "./foodTypesService";

interface FoodTypesState {
  foodTypes: FoodType[];
  loading: boolean;
  error: string | null;
  pagination: Pagination | null;
}

const initialState: FoodTypesState = {
  foodTypes: [],
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

export const getAllFoodTypesThunk = createAsyncThunk(
  "foodTypes/getAll",
  async (
    {
      page,
      limit,
      search,
    }: { page: number; limit: number; search?: string } = {
      page: 1,
      limit: 10,
    },
    { rejectWithValue }
  ) => {
    try {
      return await getAllFoodTypes(page, limit, search);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const getFoodTypeByIdThunk = createAsyncThunk(
  "foodTypes/getById",
  async (id: string, { rejectWithValue }) => {
    try {
      return await getFoodTypeById(id);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const createFoodTypeThunk = createAsyncThunk(
  "foodTypes/create",
  async (data: AddFoodType, { rejectWithValue }) => {
    try {
      return await createFoodType(data);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const updateFoodTypeThunk = createAsyncThunk(
  "foodTypes/update",
  async ({ id, data }: { id: string; data: any }, { rejectWithValue }) => {
    try {
      return await updateFoodType(id, data);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const deleteFoodTypeThunk = createAsyncThunk(
  "foodTypes/delete",
  async (id: string, { rejectWithValue }) => {
    try {
      return await deleteFoodType(id);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

const foodTypesSlice = createSlice({
  name: "foodTypes",
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Get All
      .addCase(getAllFoodTypesThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getAllFoodTypesThunk.fulfilled, (state, action) => {
        state.loading = false;
        state.foodTypes = action.payload.foodTypes;
        state.pagination = action.payload.pagination;
      })
      .addCase(getAllFoodTypesThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // Create
      .addCase(createFoodTypeThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(createFoodTypeThunk.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(createFoodTypeThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // Update
      .addCase(updateFoodTypeThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(updateFoodTypeThunk.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(updateFoodTypeThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // Delete
      .addCase(deleteFoodTypeThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(deleteFoodTypeThunk.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(deleteFoodTypeThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      });
  },
});

export const { clearError } = foodTypesSlice.actions;
export default foodTypesSlice.reducer;
