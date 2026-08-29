import axios from "axios";
import type { AxiosInstance, AxiosResponse } from "axios";
import Swal from "sweetalert2";

const ApiService: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_BASE_URL as string,
});

const token: string | null = localStorage.getItem("Token");
if (token) {
  ApiService.defaults.headers.common["Authorization"] = `Bearer ${token}`;
}

export const addResponseInterceptor = (
  navigate: (path: string) => void
): void => {
  ApiService.interceptors.response.use(
    (response: AxiosResponse) => {
      return response;
    },
    (error: any) => {
      if (
        error.response &&
        error.response.status === 401 &&
        ((error?.response &&
          error?.response.status === 401 &&
          ((error?.response.data as any)?.message === "Token expired" ||
            (error?.response.data as any)?.message === "Invalid token" ||
            (error?.response.data as any)?.message === "Session expired")) ||
          (error?.response?.data as any)?.message === "Unauthorized Admin User")
      ) {
        let timerInterval: ReturnType<typeof setInterval>;
        let remainingTime: number = 5;
        Swal.fire({
          title: "Unauthorized",
          icon: "error",
          html: "Session Expired, will Navigate to Login Page in <b></b> sec.",
          timer: remainingTime * 1000,
          timerProgressBar: true,
          allowEscapeKey: false,
          allowOutsideClick: false,
          didOpen: () => {
            Swal.showLoading();
            const timer = Swal.getPopup()?.querySelector("b");
            timerInterval = setInterval(() => {
              if (timer) {
                timer.textContent = remainingTime.toString();
                remainingTime--;
              }
            }, 1000);
          },
          willClose: () => {
            clearInterval(timerInterval);
          },
        }).then((result) => {
          navigate("/");
          localStorage.clear();
          if (result.dismiss === Swal.DismissReason.timer) {
          }
        });
        return Promise.reject(error);
      }
      return Promise.reject(error);
    }
  );
};

export default ApiService;
