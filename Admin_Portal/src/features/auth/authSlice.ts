import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import {
  loginUser,
  logoutUser,
  ResetPassword,
  sendOTP,
  verifyOTP,
} from "./authService";
import {
  PermissionData,
  ResetPayload,
  SendPayload,
  VerifyPayload,
} from "./types.ts";

interface LoginState {
  user: any;
  token: string | null;
  permissions: PermissionData[];
  roleId: number | null;
  loading: boolean;
  error: string | null;
}

const initialState: LoginState = {
  user: null,
  token: localStorage.getItem("Token"),
  permissions: [],
  roleId: null,
  loading: false,
  error: null,
};

export const login = createAsyncThunk(
  "auth/login",
  async (
    credentials: { emailId: string; password: string },
    { rejectWithValue },
  ) => {
    try {
      const data = await loginUser(credentials);
      return data;
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.Message || "Login failed");
    }
  },
);

export const sendOTPThunk = createAsyncThunk(
  "auth/sendotp",
  async (credentials: SendPayload, { rejectWithValue }) => {
    try {
      return await sendOTP(credentials);
    } catch (err: any) {
      return rejectWithValue(
        err?.response?.data?.Message || "Failed to send OTP",
      );
    }
  },
);

export const verifyOTPThunk = createAsyncThunk(
  "auth/verifyotp",
  async (credentials: VerifyPayload, { rejectWithValue }) => {
    try {
      return await verifyOTP(credentials);
    } catch (err: any) {
      return rejectWithValue(
        err?.response?.data?.Message || "Failed to verify OTP",
      );
    }
  },
);

export const resetPasswordThunk = createAsyncThunk(
  "auth/reset",
  async (credentials: ResetPayload, { rejectWithValue }) => {
    try {
      return await ResetPassword(credentials);
    } catch (err: any) {
      return rejectWithValue(
        err?.response?.data?.Message || "Failed to reset password",
      );
    }
  },
);

// Async thunk for logout

const loginSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    setToken(state, action) {
      state.token = action.payload;
      localStorage.setItem("Token", action.payload);
    },
    logout(state) {
      state.user = null;
      state.token = null;
      state.permissions = [];
      state.roleId = null;
      state.loading = false;
      state.error = null;
      localStorage.clear();
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(login.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(login.fulfilled, (state, action) => {
        state.loading = false;
        state.user = action.payload.user;
        state.token = action.payload.token;
      })
      .addCase(login.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
        console.error(state.error || "An error occurred");
      })
      // send OTP
      .addCase(sendOTPThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(sendOTPThunk.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(sendOTPThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // verify OTP
      .addCase(verifyOTPThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(verifyOTPThunk.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(verifyOTPThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // reset password
      .addCase(resetPasswordThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(resetPasswordThunk.fulfilled, (state, action) => {
        state.loading = false;
      })
      .addCase(resetPasswordThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      });
  },
});

export const { setToken, logout } = loginSlice.actions;
export default loginSlice.reducer;
