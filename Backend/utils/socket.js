const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");
const { corsOriginDelegate } = require("./publicConfig");

let io;

const connectedKitchens = new Map();
const connectedUsers = new Map();
const connectedAdmins = new Map();

function extractSocketToken(socket) {
  const authToken = socket.handshake.auth?.token;
  if (authToken) return authToken;

  const queryToken = socket.handshake.query?.token;
  if (queryToken && typeof queryToken === "string") return queryToken;

  const header = socket.handshake.headers?.authorization;
  if (header && header.startsWith("Bearer ")) {
    return header.slice(7);
  }
  return null;
}

function initSocket(server) {
  io = new Server(server, {
    cors: {
      origin: corsOriginDelegate(),
      credentials: true,
    },
  });

  io.use((socket, next) => {
    const token = extractSocketToken(socket);
    if (!token) {
      return next(new Error("unauthorized"));
    }

    try {
      socket.decoded = jwt.verify(token, process.env.JWT_SECRET_KEY);
      return next();
    } catch (error) {
      return next(new Error("unauthorized"));
    }
  });

  io.on("connection", (socket) => {
    const decoded = socket.decoded || {};

    if (decoded.userId) {
      const userId = String(decoded.userId);
      socket.join(`user_${userId}`);
      connectedUsers.set(userId, socket.id);
    }

    if (decoded.role === "KITCHEN" && decoded.id) {
      const kitchenId = String(decoded.id);
      socket.join(`kitchen_${kitchenId}`);
      connectedKitchens.set(kitchenId, socket.id);
    }

    if (decoded.adminId) {
      const adminId = String(decoded.adminId);
      socket.join("admins");
      connectedAdmins.set(adminId, socket.id);
    }

    socket.on("disconnect", () => {
      for (const [id, sid] of connectedUsers.entries()) {
        if (sid === socket.id) connectedUsers.delete(id);
      }

      for (const [id, sid] of connectedKitchens.entries()) {
        if (sid === socket.id) connectedKitchens.delete(id);
      }

      for (const [id, sid] of connectedAdmins.entries()) {
        if (sid === socket.id) connectedAdmins.delete(id);
      }
    });
  });

  return io;
}

function getIO() {
  if (!io) throw new Error("Socket.io not initialized");
  return io;
}

module.exports = { initSocket, getIO };
