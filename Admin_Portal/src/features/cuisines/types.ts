export interface Cuisine {
  id: number;
  name: string;
  isActive: number;
  image: string;
  is_popular: number;
  createdAt: string;
}

export interface AddCuisine {
  name: string;
  isActive?: number;
  is_popular?: number;
  image: string;
}

export interface EditCuisine {
  name?: string;
  isActive?: number;
  is_popular?: number;
  image: string;
}
