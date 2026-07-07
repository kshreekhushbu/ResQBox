export interface Banner {
  bannerId: number;
  banner: string;
  isActive: number;
  createdAt: string;
  linkUrl: string;
  linkType: string;
}

export interface AddBanner {
  banner: string;
  isActive?: number;
  linkUrl: string;
  linkType: string;
}
