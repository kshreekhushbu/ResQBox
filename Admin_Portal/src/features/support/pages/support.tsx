import { useState, useRef, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";
import { usePermissions } from "@/hooks/usePermissions";
import { supportService, type ChatMessage } from "../supportSerice";
import { initializeSocket, disconnectSocket } from "@/services/socket";
import type { SupportChatUI } from "../types";
import { SupportChatList } from "../components/SupportChatList";
import { SupportChatWindow } from "../components/SupportChatWindow";
import { useDispatch } from "react-redux";
import { checkActiveTickets } from "@/features/support/supportSlice";
import { AppDispatch } from "@/store/store";

const Support: React.FC = () => {
    const navigate = useNavigate();
    const permissions = usePermissions("support requests");
    const [activeTab, setActiveTab] = useState<"users" | "kitchens">("users");
    const [userChats, setUserChats] = useState<SupportChatUI[]>([]);
    const [kitchenChats, setKitchenChats] = useState<SupportChatUI[]>([]);
    const [selectedChat, setSelectedChat] = useState<SupportChatUI | null>(null);
    const [isSheetOpen, setIsSheetOpen] = useState(false);
    const [messageInput, setMessageInput] = useState("");
    const scrollAreaRef = useRef<HTMLDivElement>(null);
    const [searchTerm, setSearchTerm] = useState("");
    const [isLoading, setIsLoading] = useState(true);
    const [messagesLoading, setMessagesLoading] = useState(false);
    const [sendingMessage, setSendingMessage] = useState(false);
    const selectedChatRef = useRef<SupportChatUI | null>(null);
    const [isPartnerTyping, setIsPartnerTyping] = useState(false);
    const typingTimeoutRef = useRef<NodeJS.Timeout | null>(null);

    const dispatch = useDispatch<AppDispatch>();
    const chatsRef = useRef<{ userChats: SupportChatUI[]; kitchenChats: SupportChatUI[] }>({ userChats: [], kitchenChats: [] });

    useEffect(() => {
        chatsRef.current = { userChats, kitchenChats };
    }, [userChats, kitchenChats]);

    const fetchSupportChats = useCallback(async (isBackground = false) => {
        try {
            if (!isBackground) setIsLoading(true);
            const response = await supportService.getSupportChats();

            const transformedUserChats: SupportChatUI[] = (response.userChats || []).map(chat => ({
                ...chat,
                messages: [],
                unreadCount: chat.unreadCount || 0,
            }));

            const transformedKitchenChats: SupportChatUI[] = (response.kitchenChats || []).map(chat => ({
                ...chat,
                messages: [],
                unreadCount: chat.unreadCount || 0,
            }));

            setUserChats(transformedUserChats);
            setKitchenChats(transformedKitchenChats);
        } catch (error) {
            console.error("Failed to fetch support chats:", error);
            if (!isBackground) toast.error("Failed to load support chats");
        } finally {
            if (!isBackground) setIsLoading(false);
        }
    }, []);

    useEffect(() => {
        selectedChatRef.current = selectedChat;
    }, [selectedChat]);

    useEffect(() => {
        if (!permissions.hasRead) {
            navigate("/403", { replace: true });
        }
    }, [permissions.hasRead, navigate]);

    useEffect(() => {
        if (permissions.hasRead) {
            fetchSupportChats();
        }
    }, [permissions.hasRead, fetchSupportChats]);

    useEffect(() => {
        if (scrollAreaRef.current) {
            setTimeout(() => {
                const scrollContainer = scrollAreaRef.current?.querySelector('[data-radix-scroll-area-viewport]');
                if (scrollContainer) {
                    scrollContainer.scrollTop = scrollContainer.scrollHeight;
                }
            }, 100);
        }
    }, [selectedChat?.messages]);

    useEffect(() => {
        const socket = initializeSocket();

        const handleSupportMessage = (msg: ChatMessage) => {
            console.log("📩 Received support message:", msg);

            // Check if this message belongs to a CLOSED chat using the ref
            let isClosedChat = false;
            const currentChats = [...chatsRef.current.userChats, ...chatsRef.current.kitchenChats];

            const targetChat = currentChats.find(c => {
                if (msg.roomId && String(c.roomId) === String(msg.roomId)) return true;
                if (msg.senderId) {
                    if (c.user && (msg.senderRole === "USER" || msg.senderRole === "user") && String(c.user.userId) === String(msg.senderId)) return true;
                    if (c.kitchen && (msg.senderRole === "KITCHEN" || msg.senderRole === "kitchen" || msg.senderRole === "Kitchen") && String((c.kitchen as any).kitchenId) === String(msg.senderId)) return true;
                }
                return false;
            });

            if (targetChat && targetChat.status === "CLOSED") {
                console.log("Re-fetching chats because message received for closed chat");
                fetchSupportChats(true);
                dispatch(checkActiveTickets());
            }

            const updateChatList = (chats: SupportChatUI[]) =>
                chats.map(c => {
                    let matches = false;

                    if (msg.roomId && String(c.roomId) === String(msg.roomId)) {
                        matches = true;
                    }
                    else if (msg.senderId) {
                        if (c.user && (msg.senderRole === "USER" || msg.senderRole === "user")) {
                            if (String(c.user.userId) === String(msg.senderId)) matches = true;
                        }

                        if (c.kitchen && (msg.senderRole === "KITCHEN" || msg.senderRole === "kitchen" || msg.senderRole === "Kitchen")) {
                            if (String((c.kitchen as any).kitchenId) === String(msg.senderId)) matches = true;
                        }
                    }

                    if (matches) {
                        const messageExists = c.messages.some(m => String(m.messageId) === String(msg.messageId));
                        if (messageExists) return c;

                        dispatch(checkActiveTickets());
                        return {
                            ...c,
                            messages: [...c.messages, msg],
                            lastMessage: msg.message,
                            lastMessageAt: msg.createdAt,
                            unreadCount: (selectedChatRef.current?.roomId == c.roomId) ? 0 : (c.unreadCount || 0) + 1,
                            status: "PENDING" as const // Re-open chat on new message
                        };
                    }
                    return c;
                });

            setUserChats(prev => updateChatList(prev));
            setKitchenChats(prev => updateChatList(prev));

            const currentChat = selectedChatRef.current;
            if (currentChat) {
                let belongsToCurrent = false;

                if (msg.roomId && String(currentChat.roomId) === String(msg.roomId)) {
                    belongsToCurrent = true;
                } else if (msg.senderId) {
                    if (currentChat.user && (msg.senderRole === "USER" || msg.senderRole === "user")) {
                        if (String(currentChat.user.userId) === String(msg.senderId)) belongsToCurrent = true;
                    }

                    if (currentChat.kitchen && (msg.senderRole === "KITCHEN" || msg.senderRole === "kitchen" || msg.senderRole === "Kitchen")) {
                        if (String((currentChat.kitchen as any).kitchenId) === String(msg.senderId)) belongsToCurrent = true;
                    }
                }

                if (belongsToCurrent) {
                    setSelectedChat(prev => {
                        if (!prev) return null;
                        const messageExists = prev.messages.some(m => m.messageId === msg.messageId);
                        if (messageExists) return prev;
                        return {
                            ...prev,
                            messages: [...prev.messages, msg],
                            lastMessage: msg.message,
                            lastMessageAt: msg.createdAt,
                            status: "PENDING" as const // Update open chat status immediately
                        };
                    });
                }
            }
        };

        socket.on("support-message", handleSupportMessage);

        socket.on("typing-event", (data: { roomId: string | number, isTyping: boolean }) => {
            if (selectedChatRef.current && String(data.roomId) === String(selectedChatRef.current.roomId)) {
                setIsPartnerTyping(data.isTyping);
            }
        });

        return () => {
            socket.off("support-message", handleSupportMessage);
            socket.off("typing-event");
            disconnectSocket();
        };
    }, [fetchSupportChats]);

    const handleOpenChat = async (chat: SupportChatUI) => {
        if (!chat || !chat.roomId) {
            toast.error("Invalid chat selected");
            return;
        }

        setSelectedChat(chat);
        setIsSheetOpen(true);
        setMessagesLoading(true);

        try {
            const response = await supportService.getChatMessages(chat.roomId);
            const updatedChat = {
                ...chat,
                messages: response?.messages || [],
                unreadCount: 0
            };
            setSelectedChat(updatedChat);

            if (chat.user) {
                setUserChats(prev => prev.map(c => c.roomId === chat.roomId ? updatedChat : c));
            } else if (chat.kitchen) {
                setKitchenChats(prev => prev.map(c => c.roomId === chat.roomId ? updatedChat : c));
            }
        } catch (error) {
            toast.error("Failed to load messages");
        } finally {
            setMessagesLoading(false);
        }
    };

    const handleSendMessage = async () => {
        if (!messageInput.trim() || !selectedChat || !selectedChat.roomId) return;
        if (!permissions.checkWrite()) {
            return;
        }

        if (sendingMessage) return;
        const adminData = localStorage.getItem("user");
        const admin = adminData ? JSON.parse(adminData) : { id: 1 };

        const optimisticMessage: ChatMessage = {
            messageId: Date.now(),
            senderRole: "ADMIN",
            senderId: admin.id,
            message: messageInput,
            createdAt: new Date().toISOString(),
        };

        setSelectedChat(prev => {
            if (!prev) return prev;
            return {
                ...prev,
                messages: [...prev.messages, optimisticMessage],
                lastMessage: messageInput,
                lastMessageAt: optimisticMessage.createdAt,
            };
        });

        const updateChatList = (chats: SupportChatUI[]) =>
            chats.map(c => {
                if (c.roomId === selectedChat.roomId) {
                    return {
                        ...c,
                        messages: [...c.messages, optimisticMessage],
                        lastMessage: messageInput,
                        lastMessageAt: optimisticMessage.createdAt,
                    };
                }
                return c;
            });

        if (selectedChat.user) {
            setUserChats(updateChatList);
        } else if (selectedChat.kitchen) {
            setKitchenChats(updateChatList);
        }
        const messageToSend = messageInput;
        setMessageInput("");

        setSendingMessage(true);
        try {
            await supportService.sendMessage(selectedChat.roomId, messageToSend);
        } catch (error) {
            toast.error("Failed to send message");

            setSelectedChat(prev => {
                if (!prev) return prev;
                return {
                    ...prev,
                    messages: prev.messages.filter(m => m.messageId !== optimisticMessage.messageId),
                };
            });
            setMessageInput(messageToSend);
        } finally {
            setSendingMessage(false);
        }
    };

    const handleCloseChat = async () => {
        if (!selectedChat || !selectedChat.roomId) return;

        if (!permissions.checkWrite()) {
            return;
        }

        try {
            await supportService.closeSupportChat(selectedChat.roomId);
            toast.success("Chat closed successfully");
            dispatch(checkActiveTickets());
            const updateChatList = (chats: SupportChatUI[]) =>
                chats.map(c => {
                    if (c.roomId === selectedChat.roomId) {
                        return {
                            ...c,
                            status: "CLOSED" as const,
                        };
                    }
                    return c;
                });

            if (selectedChat.user) {
                setUserChats(updateChatList);
            } else if (selectedChat.kitchen) {
                setKitchenChats(updateChatList);
            }

            setSelectedChat(prev => prev ? { ...prev, status: "CLOSED" } : null);

        } catch (error) {
            toast.error("Failed to close chat");
        }
    };

    const handleInputChange = (value: string) => {
        setMessageInput(value);

        if (!selectedChat?.roomId) return;
        const socket = initializeSocket();

        socket.emit("typing-event", { roomId: selectedChat.roomId, isTyping: true });

        if (typingTimeoutRef.current) clearTimeout(typingTimeoutRef.current);

        typingTimeoutRef.current = setTimeout(() => {
            socket.emit("typing-event", { roomId: selectedChat.roomId, isTyping: false });
        }, 2000);
    };

    return (
        <div className="space-y-6">

            <SupportChatList
                userChats={userChats}
                kitchenChats={kitchenChats}
                activeTab={activeTab}
                onTabChange={setActiveTab}
                searchTerm={searchTerm}
                onSearchChange={setSearchTerm}
                isLoading={isLoading}
                onChatSelect={handleOpenChat}
            />

            <SupportChatWindow
                isOpen={isSheetOpen}
                onClose={setIsSheetOpen}
                selectedChat={selectedChat}
                isLoadingMessages={messagesLoading}
                messageInput={messageInput}
                onMessageInputChange={handleInputChange}
                onSendMessage={handleSendMessage}
                isSending={sendingMessage}
                scrollAreaRef={scrollAreaRef}
                isTyping={isPartnerTyping}
                onCloseChat={handleCloseChat}
            />

        </div>
    );
};
export default Support;