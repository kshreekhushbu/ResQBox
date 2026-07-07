// // utils/socket.js
// const { Server } = require("socket.io");

// let io;
// const connectedKitchens = new Map(); // kitchenId -> socketId

// function initSocket(server) {
//     io = new Server(server, {
//         cors: {
//             origin: "*",
//         }
//     });

//     io.on("connection", (socket) => {
//         console.log("Socket connected:", socket.id);

//         // ⭐ Auto join kitchen room using query param
//         const kitchenId = socket.handshake.query.kitchenId;

//         if (kitchenId) {
//             console.log(`Kitchen ${kitchenId} joined socket room`);
//             socket.join(`kitchen_${kitchenId}`);
//             connectedKitchens.set(kitchenId, socket.id);
//         }

//         // Cleanup on disconnection
//         socket.on("disconnect", () => {
//             console.log("Socket disconnected:", socket.id);
//             for (let [kId, sId] of connectedKitchens.entries()) {
//                 if (sId === socket.id) {
//                     connectedKitchens.delete(kId);
//                     break;
//                 }
//             }
//         });
//     });

//     return io;
// }

// function getIO() {
//     if (!io) {
//         throw new Error("Socket.io not initialized!");
//     }
//     return io;
// }

// module.exports = { initSocket, getIO };
// utils/socket.js
const { Server } = require("socket.io");

let io;

// Track connections (optional, for debugging / future)
const connectedKitchens = new Map(); // kitchenId -> socketId
const connectedUsers = new Map();    // userId -> socketId
const connectedAdmins = new Map();   // adminId -> socketId

function initSocket(server) {
    io = new Server(server, {
        cors: {
            origin: "*",
        }
    });

    io.on("connection", (socket) => {
        console.log("\n========== SOCKET.IO CONNECTION ==========");
        console.log("🔌 Socket ID:", socket.id);
        console.log("📋 Query Parameters:", socket.handshake.query);

        const {
            role,
            userId,
            kitchenId,
            adminId
        } = socket.handshake.query;

        console.log("\n🔍 Parsed Values:");
        console.log("   Role:", role || "❌ MISSING");
        console.log("   User ID:", userId || "-");
        console.log("   Kitchen ID:", kitchenId || "-");
        console.log("   Admin ID:", adminId || "-");

        // ================= USER =================
        if (role === "USER" && userId) {
            socket.join(`user_${userId}`);
            connectedUsers.set(userId, socket.id);
            console.log(`✅ 👤 User ${userId} joined room: user_${userId}`);
        }

        // ================= KITCHEN =================
        // ⚠️ OLD BEHAVIOUR — DO NOT CHANGE
        if (kitchenId) {
            socket.join(`kitchen_${kitchenId}`);
            connectedKitchens.set(kitchenId, socket.id);
            console.log(`✅ 🏪 Kitchen ${kitchenId} joined room: kitchen_${kitchenId}`);
        }

        // ================= ADMIN =================
        if (role === "ADMIN" && adminId) {
            socket.join("admins");
            connectedAdmins.set(adminId, socket.id);
            console.log(`✅ 🛡️  Admin ${adminId} joined room: admins`);

            // Show current admin count
            const adminsRoom = io.sockets.adapter.rooms.get("admins");
            const adminCount = adminsRoom ? adminsRoom.size : 0;
            console.log(`📊 Total admins now connected: ${adminCount}`);
        } else if (role === "ADMIN" && !adminId) {
            console.log("⚠️  WARNING: Admin role detected but adminId is missing!");
            console.log("💡 Frontend must pass: ?role=ADMIN&adminId=<id>");
        } else if (!role && adminId) {
            console.log("⚠️  WARNING: adminId provided but role is missing!");
            console.log("💡 Frontend must pass: ?role=ADMIN&adminId=<id>");
        }

        console.log("==========================================\n");

        // ================= DISCONNECT =================
        socket.on("disconnect", () => {
            console.log("❌ Socket disconnected:", socket.id);

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
