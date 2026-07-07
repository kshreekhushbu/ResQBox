import { io, Socket } from "socket.io-client";

let socket: Socket | null = null;

export const initializeSocket = (): Socket => {
  if (socket && socket.connected) {
    return socket;
  }

  const baseURL = import.meta.env.VITE_SOCKET_URL || "http://localhost:3000";

  let adminId = 1;
  try {
    const adminData = localStorage.getItem("admindata");
    if (adminData) {
      const admin = JSON.parse(adminData);
      if (admin && admin.adminId) {
        adminId = admin.adminId;
      }
    }
  } catch (e) {
    console.error("Error parsing admin data for socket:", e);
  }

  socket = io(baseURL, {
    transports: ["websocket"],
    query: {
      role: "ADMIN",
      adminId: adminId.toString(),
    },
    autoConnect: true,
  });

  socket.on("connect", () => {
    console.log("🛡️ Admin connected to socket");
  });

  socket.on("disconnect", () => {
    console.log("❌ Admin disconnected from socket");
  });

  socket.on("connect_error", (error) => {
    console.error("Socket connection error:", error);
  });

  return socket;
};

export const getSocket = (): Socket | null => {
  return socket;
};

export const disconnectSocket = () => {
  if (socket) {
    socket.disconnect();
    socket = null;
    console.log("🔌 Socket disconnected");
  }
};

export default { initializeSocket, getSocket, disconnectSocket };
