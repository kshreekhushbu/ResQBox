import ApiService from "@services/config";

export const UplaodImage = (data: FormData): Promise<any> => {
  return ApiService.post(`/upload`, data);
};

export const UplaodImages = (data: FormData): Promise<any> => {
  return ApiService.post(`/uploads`, data);
};
