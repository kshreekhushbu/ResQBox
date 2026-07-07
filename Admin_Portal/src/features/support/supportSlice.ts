import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import { supportService } from "./supportSerice";

interface SupportState {
  hasActiveTickets: boolean;
  status: "idle" | "loading" | "succeeded" | "failed";
}

const initialState: SupportState = {
  hasActiveTickets: false,
  status: "idle",
};

export const checkActiveTickets = createAsyncThunk(
  "support/checkActiveTickets",
  async () => {
    const response = await supportService.getSupportChats();
    if (response.status === 200 || response.status === 1) {
      const hasOpen =
        response.userChats?.some(
          (chat) => chat.status === "OPEN" || chat.status === "PENDING",
        ) ||
        response.kitchenChats?.some(
          (chat) => chat.status === "OPEN" || chat.status === "PENDING",
        );
      return !!hasOpen;
    }
    return false;
  },
);

const supportSlice = createSlice({
  name: "support",
  initialState,
  reducers: {
    setHasActiveTickets: (state, action: PayloadAction<boolean>) => {
      state.hasActiveTickets = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(checkActiveTickets.fulfilled, (state, action) => {
        state.hasActiveTickets = action.payload;
        state.status = "succeeded";
      })
      .addCase(checkActiveTickets.pending, (state) => {
        state.status = "loading";
      })
      .addCase(checkActiveTickets.rejected, (state) => {
        state.status = "failed";
      });
  },
});

export const { setHasActiveTickets } = supportSlice.actions;
export default supportSlice.reducer;
