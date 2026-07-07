import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import { AddCuisine, Cuisine, EditCuisine } from "./types";
import { Pagination } from "../categories/types";
import {
  AllCuisines,
  ApiError,
  cuisineCreate,
  cuisineDetails,
  deleteCuisine,
  updateCuisine,
} from "./cuisineService";

interface CuisinesState {
  cuisines: Cuisine[];
  cuisine: Cuisine | null;
  loading: boolean;
  error: string | null;
  pagination: Pagination | null;
}

const initialState: CuisinesState = {
  cuisines: [],
  cuisine: null,
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

export const getAllCuisines = createAsyncThunk(
  "cuisines/fetchAll",
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
      return await AllCuisines(page, limit, search);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const fetchCuisinebyId = createAsyncThunk(
  "cuisines/fetchById",
  async (id: string, { rejectWithValue }) => {
    try {
      return await cuisineDetails(id);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const cuisineAdd = createAsyncThunk(
  "cuisines/create",
  async (cuisineData: AddCuisine, { rejectWithValue }) => {
    try {
      return await cuisineCreate(cuisineData);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const editCuisine = createAsyncThunk(
  "cuisines/update",
  async (
    { id, data }: { id: string; data: EditCuisine },
    { rejectWithValue }
  ) => {
    try {
      return await updateCuisine(id, data);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const removeCuisine = createAsyncThunk(
  "cuisines/delete",
  async (id: string, { rejectWithValue }) => {
    try {
      return await deleteCuisine(id);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

const cuisinesSlice = createSlice({
  name: "cuisines",
  initialState,
  reducers: {
    clearCurrentCuisine: (state) => {
      state.cuisine = null;
    },
    clearError: (state) => {
      state.error = null;
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.loading = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(getAllCuisines.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getAllCuisines.fulfilled, (state, action) => {
        state.loading = false;
        state.cuisines = action.payload.cuisines;
        state.pagination = action.payload.pagination;
      })
      .addCase(getAllCuisines.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(fetchCuisinebyId.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchCuisinebyId.fulfilled, (state, action) => {
        state.loading = false;
        state.cuisine = action.payload;
      })
      .addCase(fetchCuisinebyId.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(cuisineAdd.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(cuisineAdd.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(cuisineAdd.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(editCuisine.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(editCuisine.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(editCuisine.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(removeCuisine.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(removeCuisine.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(removeCuisine.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      });
  },
});

export const { clearCurrentCuisine, clearError, setLoading } =
  cuisinesSlice.actions;
export default cuisinesSlice.reducer;
