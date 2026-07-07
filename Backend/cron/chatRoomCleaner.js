const prisma = require("../utils/prisma");

/**
 * Delete chatrooms that haven't had any messages in the last 7 days
 * This runs daily to clean up inactive chat rooms
 */
async function deleteOldChatRooms() {
    try {
        console.log('\n🗑️  [CHAT] Checking for old chat rooms to delete...');

        // Calculate the date 7 days ago
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        console.log(`Looking for chat rooms with last message before: ${sevenDaysAgo.toISOString()}`);

        // Find all chatrooms with their messages
        const allChatRooms = await prisma.chatRoom.findMany({
            include: {
                messages: {
                    orderBy: {
                        createdAt: 'desc' // Get latest message first
                    },
                    take: 1, // Only get the most recent message
                    select: {
                        messageId: true,
                        createdAt: true
                    }
                }
            }
        });

        // Filter chatrooms where last message is older than 7 days (or no messages at all)
        const oldChatRooms = allChatRooms.filter(room => {
            if (room.messages.length === 0) {
                // No messages - check room creation date
                return room.createdAt < sevenDaysAgo;
            } else {
                // Has messages - check last message date
                const lastMessage = room.messages[0];
                return lastMessage.createdAt < sevenDaysAgo;
            }
        });

        if (oldChatRooms.length === 0) {
            console.log('✅ [CHAT] No old chat rooms found to delete');
            return {
                success: true,
                deletedCount: 0,
                deletedRooms: []
            };
        }

        console.log(`Found ${oldChatRooms.length} chat room(s) to delete`);

        const deletedRooms = [];

        // Delete each chatroom and its messages
        for (const room of oldChatRooms) {
            try {
                const lastMessageDate = room.messages.length > 0
                    ? room.messages[0].createdAt
                    : room.createdAt;

                // Delete all messages in this room first (due to foreign key constraint)
                const deletedMessages = await prisma.chatMessage.deleteMany({
                    where: {
                        roomId: room.roomId
                    }
                });

                // Delete the chatroom
                await prisma.chatRoom.delete({
                    where: {
                        roomId: room.roomId
                    }
                });

                console.log(`✅ Deleted chat room ${room.roomId} (${deletedMessages.count} messages)`);
                console.log(`   Last message: ${lastMessageDate.toISOString()}`);
                console.log(`   User ID: ${room.userId || 'N/A'}, Kitchen ID: ${room.kitchenId || 'N/A'}`);

                deletedRooms.push({
                    roomId: room.roomId,
                    userId: room.userId,
                    kitchenId: room.kitchenId,
                    messagesDeleted: deletedMessages.count,
                    lastMessageDate: lastMessageDate
                });

            } catch (roomError) {
                console.error(`❌ Error deleting chat room ${room.roomId}:`, roomError.message);
            }
        }

        console.log(`\n========== CHAT CLEANUP SUMMARY ==========`);
        console.log(`Total rooms checked: ${allChatRooms.length}`);
        console.log(`Rooms eligible for deletion: ${oldChatRooms.length}`);
        console.log(`Successfully deleted: ${deletedRooms.length}`);
        console.log(`==========================================\n`);

        return {
            success: true,
            deletedCount: deletedRooms.length,
            deletedRooms
        };

    } catch (error) {
        console.error('❌ [CHAT] Error deleting old chat rooms:', error);
        return {
            success: false,
            error: error.message
        };
    }
}

module.exports = { deleteOldChatRooms };
