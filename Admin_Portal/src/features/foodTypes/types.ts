export interface FoodType {
  id: number;
  name: string;
  isActive: number;
  image: string;
  question?: string;
  createdAt: string;
  updatedAt: string;
}

export interface AddFoodType {
  name: string;
  image: string;
  question: string;
}

export interface EditFoodType {
  name: string;
  isActive?: number;
  image?: string;
  question?: string;
}
