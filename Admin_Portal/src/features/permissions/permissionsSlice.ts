import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import { Role, Permission } from "./types";
import { getAllRoles, getRoleById, createRole, updateRole, getPagePermissions, ApiError } from "./permissionsService";

interface PermissionsState {
  roles: Role[];
  currentRole: Role | null;
  defaultPermissions: Permission[];
  loading: boolean;
  error: string | null;
}

const initialState: PermissionsState = {
  roles: [],
  currentRole: null,
  defaultPermissions: [],
  loading: false,
  error: null,
};

const handleReject = (error: unknown) => {
  if (error instanceof ApiError) {
    return error.message;
  }
  return "An unexpected error occurred";
};

export const fetchRoles = createAsyncThunk(
  "permissions/fetchRoles",
  async (_, { rejectWithValue }) => {
    try {
      return await getAllRoles();
    } catch (error) {
      return rejectWithValue(handleReject(error));
    }
  }
);

export const fetchRoleDetails = createAsyncThunk(
    "permissions/fetchRoleDetails",
    async (id: number, { rejectWithValue }) => {
        try {
            return await getRoleById(id);
        } catch (error) {
            return rejectWithValue(handleReject(error));
        }
    }
);

export const createNewRole = createAsyncThunk(
    "permissions/createRole",
    async (roleData: { role: string; permissions: Permission[] }, { rejectWithValue }) => {
        try {
            await createRole(roleData);
        } catch (error) {
            return rejectWithValue(handleReject(error));
        }
    }
);

export const updateExistingRole = createAsyncThunk(
    "permissions/updateRole",
    async ({ id, roleData }: { id: number; roleData: { role: string; permissions: Permission[] } }, { rejectWithValue }) => {
        try {
            await updateRole(id, roleData);
        } catch (error) {
            return rejectWithValue(handleReject(error));
        }
    }
);

export const fetchPagePermissions = createAsyncThunk(
    "permissions/fetchPagePermissions",
    async (_, { rejectWithValue }) => {
        try {
            return await getPagePermissions();
        } catch (error) {
            return rejectWithValue(handleReject(error));
        }
    }
);


const permissionsSlice = createSlice({
  name: "permissions",
  initialState,
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
      .addCase(fetchRoles.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchRoles.fulfilled, (state, action) => {
        state.loading = false;
        state.roles = action.payload;
      })
      .addCase(fetchRoles.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      .addCase(fetchRoleDetails.pending, (state) => {
          state.loading = true;
          state.error = null;
      })
      .addCase(fetchRoleDetails.fulfilled, (state, action) => {
          state.loading = false;
          state.currentRole = action.payload;
      })
      .addCase(fetchRoleDetails.rejected, (state, action) => {
          state.loading = false;
          state.error = action.payload as string;
      })
      // Create/Update just manage loading states or error, typically we refetch roles after
      .addCase(createNewRole.pending, (state) => {
          state.loading = true;
          state.error = null;
      })
      .addCase(createNewRole.fulfilled, (state) => {
          state.loading = false;
      })
      .addCase(createNewRole.rejected, (state, action) => {
          state.loading = false;
          state.error = action.payload as string;
      })
      .addCase(updateExistingRole.pending, (state) => {
          state.loading = true;
          state.error = null;
      })
      .addCase(updateExistingRole.fulfilled, (state) => {
          state.loading = false;
      })
      .addCase(updateExistingRole.rejected, (state, action) => {
          state.loading = false;
          state.error = action.payload as string;
      })
      .addCase(fetchPagePermissions.pending, (state) => {
          state.loading = true;
          state.error = null;
      })
      .addCase(fetchPagePermissions.fulfilled, (state, action) => {
          state.loading = false;
          state.defaultPermissions = action.payload;
      })
      .addCase(fetchPagePermissions.rejected, (state, action) => {
          state.loading = false;
          state.error = action.payload as string;
      });
  },
});

export const { clearError, setLoading } = permissionsSlice.actions;
export default permissionsSlice.reducer;
