import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import { AdminUser, Pagination, CreateAdminUser, UpdateAdminUser } from "./types";
import { getAdminUsers, createAdminUser, getAdminUserById, updateAdminUser, deleteAdminUser, ApiError } from "./teamService";

// ... TeamState

export const fetchAdminUserById = createAsyncThunk(
    "team/fetchUserById",
    async (id: number, { rejectWithValue }) => {
        try {
            return await getAdminUserById(id);
        } catch (error) {
            return rejectWithValue(handleReject(error));
        }
    }
);

export const modifyAdminUser = createAsyncThunk(
    "team/modifyUser",
    async ({ id, userData }: { id: number; userData: UpdateAdminUser }, { rejectWithValue }) => {
        try {
            return await updateAdminUser(id, userData);
        } catch (error) {
            return rejectWithValue(handleReject(error));
        }
    }
);

export const removeAdminUser = createAsyncThunk(
    "team/removeUser",
    async (id: number, { rejectWithValue }) => {
        try {
            return await deleteAdminUser(id);
        } catch (error) {
            return rejectWithValue(handleReject(error));
        }
    }
);

interface TeamState {
    users: AdminUser[];
    loading: boolean;
    error: string | null;
    pagination: Pagination | null;
}

const initialState: TeamState = {
    users: [],
    loading: false,
    error: null,
    pagination: null,
};

const handleReject = (error: unknown) => {
    if (error instanceof ApiError) return error.message;
    return "An unexpected error occurred";
};

export const fetchAdminUsers = createAsyncThunk(
    "team/fetchUsers",
    async (
        { page, limit, search }: { page: number; limit: number; search: string },
        { rejectWithValue }
    ) => {
        try {
            return await getAdminUsers(page, limit, search);
        } catch (error) {
            return rejectWithValue(handleReject(error));
        }
    }
);

export const addAdminUser = createAsyncThunk(
    "team/addUser",
    async (userData: CreateAdminUser, { rejectWithValue }) => {
        try {
            return await createAdminUser(userData);
        } catch (error) {
            return rejectWithValue(handleReject(error));
        }
    }
);

const teamSlice = createSlice({
    name: "team",
    initialState,
    reducers: {
        clearError: (state) => {
            state.error = null;
        },
    },
    extraReducers: (builder) => {
        builder
            // Fetch Users
            .addCase(fetchAdminUsers.pending, (state) => {
                state.loading = true;
                state.error = null;
            })
            .addCase(fetchAdminUsers.fulfilled, (state, action) => {
                state.loading = false;
                state.users = action.payload.subadmins;
                state.pagination = {
                    total: action.payload.pagination ? action.payload.pagination.total : 0,
                    currentPage: action.payload.pagination ? action.payload.pagination.currentPage : 1,
                    totalPages: action.payload.pagination ? action.payload.pagination.totalPages : 0,
                };
            })
            .addCase(fetchAdminUsers.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload as string;
            })
            // Add User
            .addCase(addAdminUser.pending, (state) => {
                state.loading = true;
                state.error = null;
            })
            .addCase(addAdminUser.fulfilled, (state) => {
                state.loading = false;
            })
            .addCase(addAdminUser.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload as string;
            });
    },
});

export const { clearError } = teamSlice.actions;
export default teamSlice.reducer;
