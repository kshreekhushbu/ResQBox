export interface Category {
  id: number;
  name: string;
  isActive: number;
  isPopular: number;
  image: string;
  createdAt: string;
}

export interface AddCategory {
  name: string;
  isActive?: number;
  isPopular?: number;
  image: string;
}

export interface EditCategory {
  name?: string;
  isActive?: number;
  isPopular?: number;
  image: string;
}

export interface Pagination {
  totalRecords: number;
  currentPage: number;
  totalPages: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: Pagination;
  message?: string;
  success: boolean;
}
