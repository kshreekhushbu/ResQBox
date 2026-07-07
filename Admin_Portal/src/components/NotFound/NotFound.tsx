import React from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
const NotFound: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="w-full min-h-[70vh] flex flex-col items-center justify-center text-center py-12 px-6">
      <div className="text-6xl mb-4">🔍</div>
      <h1 className="mt-6 text-4xl font-bold text-foreground">404</h1>
      <p className="mt-2 text-lg text-muted-foreground">Page Not Found</p>
      <p className="mt-2 text-sm text-muted-foreground">
        The page you're looking for doesn't exist.
      </p>
      <Button className="mt-6" onClick={() => navigate("/")}>
        Go to Home
      </Button>
    </div>
  );
};

export default NotFound;
