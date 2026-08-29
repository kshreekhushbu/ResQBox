import { io, Socket } from "socket.io-client";

let socket: Socket | null = null;

export const initializeSocket = (): Socket => {
  if (socket && socket.connected) {
    return socket;
  }

  const baseURL = import.meta.env.VITE_SOCKET_URL || "http://localhost:3000";
  const token = localStorage.getItem("Token");

  socket = io(baseURL, {
    transports: ["websocket"],
    auth: {
      token: token || "",
    },
    autoConnect: true,
  });

  socket.on("connect", () => {
    console.log("Admin connected to socket");
  });

  socket.on("disconnect", () => {
    console.log("Admin disconnected from socket");
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
  }
};

export default { initializeSocket, getSocket, disconnectSocket };
