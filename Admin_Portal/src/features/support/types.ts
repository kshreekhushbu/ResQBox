import type { SupportChat, ChatMessage } from "./supportSerice";

export interface SupportChatUI extends SupportChat {
  messages: ChatMessage[];
  unreadCount: number;
}
