import ApiService from "../../services/config";

export interface SupportUser {
  userId: number;
  name: string;
  phoneNumber: string;
  profilePicture: string | null;
  email: string;
}

export interface Kitchen {
  kitchenId: number;
  kitchenName: string;
  kitchenProfilePhoto: string | null;
  email: string;
}

export interface SupportChat {
  roomId: number;
  status: "OPEN" | "CLOSED" | "PENDING";
  lastMessage: string;
  lastMessageAt: string;
  user?: SupportUser;
  kitchen?: Kitchen;
  unreadCount?: number;
}

export interface SupportChatsResponse {
  status: number;
  userChats: SupportChat[];
  kitchenChats: SupportChat[];
}

export interface ChatMessage {
  messageId: number;
  senderRole: string;
  senderId?: number;
  roomId?: number;
  message: string;
  image?: string | null;
  createdAt: string;
}

export interface ChatMessagesResponse {
  status: number;
  messages: ChatMessage[];
}

export const supportService = {
  getSupportChats: async (): Promise<SupportChatsResponse> => {
    const response = await ApiService.get("/adminGetSupportChats");
    return response.data;
  },

  getChatMessages: async (roomId: number): Promise<ChatMessagesResponse> => {
    const response = await ApiService.get(`/getChatMessages/${roomId}`);
    return response.data;
  },

  sendMessage: async (roomId: number, message: string) => {
    const response = await ApiService.post("/sendAdminSupportMessage", {
      roomId,
      message,
    });
    return response.data;
  },

  updateChatStatus: async (
    roomId: number,
    status: "OPEN" | "CLOSED" | "PENDING",
  ) => {
    const response = await ApiService.put("/admin/updateChatStatus", {
      roomId,
      status,
    });
    return response.data;
  },

  closeSupportChat: async (roomId: number) => {
    const response = await ApiService.put(`/closeSupportChat/${roomId}`);
    return response.data;
  },
};
