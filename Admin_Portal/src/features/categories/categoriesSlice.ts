import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import { AddCategory, Category, EditCategory, Pagination } from "./types";
import {
  AllCategories,
  ApiError,
  categoryCreate,
  categoryDetails,
  deleteCategory,
  updateCategory,
} from "./categoryService";

interface CategoriesState {
  categories: Category[];
  category: Category | null;
  loading: boolean;
  error: string | null;
  pagination: Pagination | null;
}

const initialState: CategoriesState = {
  categories: [],
  category: null,
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

export const getAllCategories = createAsyncThunk(
  "categories/fetchAll",
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
      return await AllCategories(page, limit, search);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const fetchCategorybyId = createAsyncThunk(
  "banners/fetchById",
  async (id: string, { rejectWithValue }) => {
    try {
      return await categoryDetails(id);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const categoryAdd = createAsyncThunk(
  "categories/create",
  async (categoryData: AddCategory, { rejectWithValue }) => {
    try {
      return await categoryCreate(categoryData);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const editCategory = createAsyncThunk(
  "categories/update",
  async (
    { id, data }: { id: string; data: EditCategory },
    { rejectWithValue }
  ) => {
    try {
      return await updateCategory(id, data);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const removeCategory = createAsyncThunk(
  "categories/delete",
  async (id: string, { rejectWithValue }) => {
    try {
      return await deleteCategory(id);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

const categoriesSlice = createSlice({
  name: "categories",
  initialState,
  reducers: {
    clearCurrentCategory: (state) => {
      state.category = null;
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
      .addCase(getAllCategories.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getAllCategories.fulfilled, (state, action) => {
        state.loading = false;
        state.categories = action.payload.categories;
        state.pagination = action.payload.pagination;
      })
      .addCase(getAllCategories.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(fetchCategorybyId.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchCategorybyId.fulfilled, (state, action) => {
        state.loading = false;
        state.category = action.payload;
      })
      .addCase(fetchCategorybyId.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(categoryAdd.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(categoryAdd.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(categoryAdd.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(editCategory.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(editCategory.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(editCategory.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(removeCategory.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(removeCategory.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(removeCategory.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      });
  },
});

export const { clearCurrentCategory, clearError, setLoading } =
  categoriesSlice.actions;
export default categoriesSlice.reducer;
