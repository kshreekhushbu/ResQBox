import { JSX } from "react";
import { Config } from "./Routeconfig";
import Login from "@/features/auth/pages/login";
import { Route, Routes, Navigate } from "react-router-dom";
import NotFound from "@/features/NotFound";
import { useSelector } from "react-redux";
import { RootState } from "@/store/store";
import Forbidden from "@/features/Forbidden";
import { Layout } from "@/components/admin/Layout";
import Profile from "@/features/profile/pages/profile";
import ForgotPassword from "@/features/auth/pages/ForgotPassword";

function ProtectedRoute({ children }: { children: JSX.Element }) {
  const { token } = useSelector((state: RootState) => state.auth);

  if (!token) {
    return <Navigate to="/" replace />;
  }
  return children;
}

const AppRoutes: React.FC = () => {
  const PageData = Config.map(({ path, Element, Type, Name }) => {
    // Wrap ALL admin routes in ProtectedRoute to prevent access after logout
    // This ensures redirect to "/" (login) instead of 403 Forbidden
    const element = (
      <ProtectedRoute>
        {Type === "private" ? (
          <Element />
        ) : (
          <Layout Active={Name} header={{ title: Name }}>
            <Element />
          </Layout>
        )}
      </ProtectedRoute>
    );

    return <Route path={path} key={Name} element={element} />;
  });

  return (
    <Routes>
      <Route path="/" element={<Login />} />
      <Route path="/forgotpassword" element={<ForgotPassword />} />
      <Route path="/profile" element={<ProtectedRoute><Profile /></ProtectedRoute>} />
      {PageData}
      <Route path="/403" element={<Forbidden />} />
      <Route path="*" element={<NotFound />} />
    </Routes>
  );
};

export default AppRoutes;
