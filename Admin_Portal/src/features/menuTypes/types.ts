export interface MenuType {
  id: number;
  name: string;
  isActive: number;
  image: string;
  question?: string | null;
  type?: string;
  createdAt: string;
  updatedAt: string;
}

export interface AddMenuType {
  name: string;
  image: string;
}

export interface EditMenuType {
  name: string;
  isActive?: number;
  image?: string;
}
