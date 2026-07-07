import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import type { RootState } from '@/store/store';

interface LayoutState {
  sidebarCollapsed: boolean;
  sidebarOpen: boolean; // For mobile
  theme: 'light' | 'dark' | 'system';
  breadcrumbs: Array<{ label: string; href?: string }>;
  pageTitle: string;
  pageSubtitle: string;
}

const initialState: LayoutState = {
  sidebarCollapsed: localStorage.getItem('sidebarCollapsed') === 'true',
  sidebarOpen: false,
  theme: (localStorage.getItem('theme') as 'light' | 'dark' | 'system') || 'system',
  breadcrumbs: [],
  pageTitle: '',
  pageSubtitle: '',
};

const layoutSlice = createSlice({
  name: 'layout',
  initialState,
  reducers: {
    toggleSidebar: (state) => {
      state.sidebarCollapsed = !state.sidebarCollapsed;
      localStorage.setItem('sidebarCollapsed', String(state.sidebarCollapsed));
    },
    
    setSidebarCollapsed: (state, action: PayloadAction<boolean>) => {
      state.sidebarCollapsed = action.payload;
      localStorage.setItem('sidebarCollapsed', String(action.payload));
    },
    
    toggleMobileSidebar: (state) => {
      state.sidebarOpen = !state.sidebarOpen;
    },
    
    setMobileSidebarOpen: (state, action: PayloadAction<boolean>) => {
      state.sidebarOpen = action.payload;
    },
    
    setTheme: (state, action: PayloadAction<'light' | 'dark' | 'system'>) => {
      state.theme = action.payload;
      localStorage.setItem('theme', action.payload);
    },
    
    setBreadcrumbs: (state, action: PayloadAction<Array<{ label: string; href?: string }>>) => {
      state.breadcrumbs = action.payload;
    },
    
    setPageInfo: (state, action: PayloadAction<{ title: string; subtitle?: string }>) => {
      state.pageTitle = action.payload.title;
      state.pageSubtitle = action.payload.subtitle || '';
    },
    
    resetLayout: (state) => {
      state.sidebarOpen = false;
      state.breadcrumbs = [];
      state.pageTitle = '';
      state.pageSubtitle = '';
    },
  },
});

export const {
  toggleSidebar,
  setSidebarCollapsed,
  toggleMobileSidebar,
  setMobileSidebarOpen,
  setTheme,
  setBreadcrumbs,
  setPageInfo,
  resetLayout,
} = layoutSlice.actions;

export default layoutSlice.reducer;

// Selectors
export const selectSidebarCollapsed = (state: RootState) => state.layout.sidebarCollapsed;
export const selectSidebarOpen = (state: RootState) => state.layout.sidebarOpen;
export const selectTheme = (state: RootState) => state.layout.theme;
export const selectBreadcrumbs = (state: RootState) => state.layout.breadcrumbs;
export const selectPageTitle = (state: RootState) => state.layout.pageTitle;
export const selectPageSubtitle = (state: RootState) => state.layout.pageSubtitle;
export const selectPageInfo = (state: RootState) => ({
  title: state.layout.pageTitle,
  subtitle: state.layout.pageSubtitle,
});
