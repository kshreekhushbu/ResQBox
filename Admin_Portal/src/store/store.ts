import { configureStore } from "@reduxjs/toolkit";
import authReducer from "@/features/auth/authSlice";
import layoutReducer from "./layoutSlice";
import bannersReducer from "@/features/banners/bannersSlice";
import categoriesReducer from "@/features/categories/categoriesSlice";
import cuisinesReducer from "@/features/cuisines/cuisinesSlice";
import kitchensReducer from "@/features/restarents/kitchensSlice";
import permissionsReducer from "@/features/permissions/permissionsSlice";
import foodTypesReducer from "@/features/foodTypes/foodTypesSlice";
import usersReducer from "@/features/users/usersSlice";
import ordersReducer from "@/features/orders/ordersSlice";
import teamReducer from "@/features/team/teamSlice";
import configsReducer from "@/features/configs/configsSlice";
import payoutsReducer from "@/features/payouts/payoutsSlice";
import invoicesReducer from "@/features/invoices/invoicesSlice";
import notificationsReducer from "@/features/notifications/notificationsSlice";
import dashboardReducer from "@/features/dashboard/dashboardSlice";
import supportReducer from "@/features/support/supportSlice";
import menuTypesReducer from "@/features/menuTypes/menuTypesSlice";

export const store = configureStore({
  reducer: {
    auth: authReducer,
    layout: layoutReducer,
    banners: bannersReducer,
    categories: categoriesReducer,
    cuisines: cuisinesReducer,
    kitchens: kitchensReducer,
    permissions: permissionsReducer,
    foodTypes: foodTypesReducer,
    users: usersReducer,
    orders: ordersReducer,
    team: teamReducer,
    configs: configsReducer,
    payouts: payoutsReducer,
    invoices: invoicesReducer,
    notifications: notificationsReducer,
    dashboard: dashboardReducer,
    support: supportReducer,
    menuTypes: menuTypesReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
export default store;
