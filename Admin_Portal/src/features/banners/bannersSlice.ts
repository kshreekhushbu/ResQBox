import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";

import { Banner, AddBanner } from "./types";
import {
  AllBanners,
  ApiError,
  BannerCreate,
  BannerDetails,
  deleteBanner,
  updateBanner,
  UpdateBannerDTO,
} from "./bannersservice";

interface BannersState {
  banners: Banner[];
  Banner: Banner | null;
  loading: boolean;
  error: string | null;
}

const initialState: BannersState = {
  banners: [],
  Banner: null,
  loading: false,
  error: null,
};

const handleReject = (error: unknown) => {
  if (error instanceof ApiError) {
    return error.message;
  }
  return "An unexpected error occurred";
};

export const getAllBanners = createAsyncThunk(
  "banners/fetchAll",
  async (_, { rejectWithValue }) => {
    try {
      return await AllBanners();
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const getBannerbyId = createAsyncThunk(
  "banners/fetchById",
  async (id: string, { rejectWithValue }) => {
    try {
      return await BannerDetails(id);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const bannerAdd = createAsyncThunk(
  "banners/create",
  async (bannerData: AddBanner, { rejectWithValue }) => {
    try {
      return await BannerCreate(bannerData);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const editBanner = createAsyncThunk(
  "countries/update",
  async (
    { id, data }: { id: string; data: UpdateBannerDTO },
    { rejectWithValue }
  ) => {
    try {
      return await updateBanner(id, data);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const removeBanner = createAsyncThunk(
  "banners/delete",
  async (id: string, { rejectWithValue }) => {
    try {
      return await deleteBanner(id);
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

const bannersSlice = createSlice({
  name: "banners",
  initialState,
  reducers: {
    clearCurrentBanner: (state) => {
      state.Banner = null;
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
      .addCase(getAllBanners.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getAllBanners.fulfilled, (state, action) => {
        state.loading = false;
        state.banners = action.payload;
      })
      .addCase(getAllBanners.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(getBannerbyId.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getBannerbyId.fulfilled, (state, action) => {
        state.loading = false;
        state.Banner = action.payload;
      })
      .addCase(getBannerbyId.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(bannerAdd.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(bannerAdd.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(bannerAdd.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(editBanner.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(editBanner.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(editBanner.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })

      .addCase(removeBanner.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(removeBanner.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(removeBanner.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      });
  },
});

export const { clearCurrentBanner, clearError, setLoading } =
  bannersSlice.actions;
export default bannersSlice.reducer;
