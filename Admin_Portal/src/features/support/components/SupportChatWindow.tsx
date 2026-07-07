import React from "react";
import { MessageSquare, SendHorizontal, CheckCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
    Sheet,
    SheetContent,
    SheetHeader,
    SheetTitle,
    SheetDescription,
} from "@/components/ui/sheet";
import { Dialog, DialogContent } from "@/components/ui/dialog";
import { cn } from "@/lib/utils";
import { format } from "date-fns";
import type { SupportChatUI } from "../types";

interface SupportChatWindowProps {
    isOpen: boolean;
    onClose: (open: boolean) => void;
    selectedChat: SupportChatUI | null;
    isLoadingMessages: boolean;
    messageInput: string;
    onMessageInputChange: (value: string) => void;
    onSendMessage: () => void;
    isSending: boolean;
    scrollAreaRef: React.RefObject<HTMLDivElement>;
    isTyping?: boolean;
    onCloseChat: () => void;
}

export const SupportChatWindow: React.FC<SupportChatWindowProps> = ({
    isOpen,
    onClose,
    selectedChat,
    isLoadingMessages,
    messageInput,
    onMessageInputChange,
    onSendMessage,
    isSending,
    scrollAreaRef,
    isTyping,
    onCloseChat
}) => {
    const [previewImage, setPreviewImage] = React.useState<string | null>(null);

    return (
        <Sheet open={isOpen} onOpenChange={onClose}>
            <SheetContent className="w-full sm:w-[480px] sm:max-w-[95vw] flex flex-col p-0 gap-0 border-l border-border/50 shadow-xl overflow-hidden">
                <SheetHeader className="px-4 py-3 border-b bg-background/95 backdrop-blur-sm flex-shrink-0">
                    <div className="flex items-center gap-3">
                        <Avatar className="h-9 w-9 flex-shrink-0 border border-border/50">
                            <AvatarImage src={
                                selectedChat?.user?.profilePicture ||
                                selectedChat?.kitchen?.kitchenProfilePhoto ||
                                undefined
                            } />
                            <AvatarFallback className="bg-primary/10 text-primary text-xs font-medium">
                                {selectedChat?.user?.name?.substring(0, 2).toUpperCase() ||
                                    selectedChat?.kitchen?.kitchenName?.substring(0, 2).toUpperCase() ||
                                    "??"}
                            </AvatarFallback>
                        </Avatar>
                        <div className="flex flex-col gap-0.5 overflow-hidden">
                            <SheetTitle
                                className="text-sm font-semibold leading-tight max-w-[280px] truncate"
                                style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
                            >
                                {selectedChat?.user?.name || selectedChat?.kitchen?.kitchenName || "Unknown"}
                            </SheetTitle>
                            <SheetDescription
                                className="text-[11px] text-muted-foreground leading-tight max-w-[250px] truncate"
                                style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
                            >
                                {selectedChat?.user?.email ||
                                    (selectedChat?.kitchen ? `${selectedChat.kitchen.email}` : "N/A")}
                            </SheetDescription>
                        </div>
                    </div>
                    {selectedChat?.status !== "CLOSED" && (
                        <Button
                            variant="destructive"
                            size="sm"
                            onClick={onCloseChat}
                            className="ml-auto"
                        >
                            Close Support Request
                        </Button>
                    )}
                </SheetHeader>

                <ScrollArea ref={scrollAreaRef} className="flex-1 bg-muted/20 overflow-hidden">
                    <div className="p-3 space-y-0.5">
                        {isLoadingMessages ? (
                            <div className="flex flex-col items-center justify-center py-12 text-center">
                                <div className="w-8 h-8 border-2 border-primary/20 border-t-primary rounded-full animate-spin mb-3" />
                                <p className="text-xs text-muted-foreground">Loading messages...</p>
                            </div>
                        ) : (
                            <>
                                {selectedChat?.messages && selectedChat.messages.length > 0 ? (
                                    (() => {
                                        const groupedMessages: { [key: string]: typeof selectedChat.messages } = {};
                                        selectedChat.messages.forEach(msg => {
                                            const dateKey = format(new Date(msg.createdAt), "yyyy-MM-dd");
                                            if (!groupedMessages[dateKey]) {
                                                groupedMessages[dateKey] = [];
                                            }
                                            groupedMessages[dateKey].push(msg);
                                        });

                                        const today = format(new Date(), "yyyy-MM-dd");
                                        const yesterday = format(new Date(Date.now() - 86400000), "yyyy-MM-dd");

                                        return Object.entries(groupedMessages).map(([dateKey, messages]) => {
                                            let dateLabel = "";
                                            if (dateKey === today) {
                                                dateLabel = "Today";
                                            } else if (dateKey === yesterday) {
                                                dateLabel = "Yesterday";
                                            } else {
                                                dateLabel = format(new Date(dateKey), "MMM dd, yyyy");
                                            }
                                            return (
                                                <div key={dateKey} className="space-y-1.5 mb-3">
                                                    {/* Date Separator */}
                                                    <div className="flex justify-center py-2">
                                                        <span className="text-[10px] font-medium text-muted-foreground/70 bg-background/80 px-2.5 py-0.5 rounded-full border border-border/30">
                                                            {dateLabel}
                                                        </span>
                                                    </div>

                                                    {messages.map((msg, index) => {
                                                        const isAdmin = msg.senderRole === "ADMIN";
                                                        const prevMsg = index > 0 ? messages[index - 1] : null;
                                                        const nextMsg = index < messages.length - 1 ? messages[index + 1] : null;
                                                        const isFirstInGroup = !prevMsg || prevMsg.senderRole !== msg.senderRole;
                                                        const isLastInGroup = !nextMsg || nextMsg.senderRole !== msg.senderRole;

                                                        const partnerName = selectedChat?.user?.name || selectedChat?.kitchen?.kitchenName || "Unknown";
                                                        const partnerAvatar = selectedChat?.user?.profilePicture || selectedChat?.kitchen?.kitchenProfilePhoto;

                                                        return (
                                                            <div
                                                                key={msg.messageId}
                                                                className={cn(
                                                                    "flex w-full",
                                                                    isAdmin ? "justify-end" : "justify-start",
                                                                    !isLastInGroup ? "mb-0.5" : "mb-1.5"
                                                                )}
                                                            >
                                                                <div className={cn(
                                                                    "flex gap-1.5 max-w-[85%]",
                                                                    isAdmin ? "flex-row-reverse" : "flex-row",
                                                                    "items-end"
                                                                )}>
                                                                    {/* Avatar - Only show for last message in group */}
                                                                    <div className="flex-shrink-0 w-6">
                                                                        {isLastInGroup ? (
                                                                            <Avatar className="h-6 w-6">
                                                                                {isAdmin ? (
                                                                                    <AvatarFallback className="bg-primary text-primary-foreground text-[9px] font-medium">
                                                                                        AD
                                                                                    </AvatarFallback>
                                                                                ) : (
                                                                                    <>
                                                                                        <AvatarImage src={partnerAvatar || undefined} />
                                                                                        <AvatarFallback className="text-[9px] bg-muted text-muted-foreground">
                                                                                            {partnerName.substring(0, 2).toUpperCase()}
                                                                                        </AvatarFallback>
                                                                                    </>
                                                                                )}
                                                                            </Avatar>
                                                                        ) : null}
                                                                    </div>

                                                                    <div className="min-w-0 max-w-full overflow-hidden">
                                                                        <div className={cn(
                                                                            "px-3 py-1.5 overflow-hidden",
                                                                            isAdmin
                                                                                ? "bg-primary text-primary-foreground rounded-2xl rounded-br-md"
                                                                                : "bg-background border border-border/50 text-foreground rounded-2xl rounded-bl-md",
                                                                            isFirstInGroup && !isAdmin && "rounded-tl-2xl",
                                                                            isFirstInGroup && isAdmin && "rounded-tr-2xl"
                                                                        )}>
                                                                            {!isAdmin && isFirstInGroup && (
                                                                                <p className="text-[10px] font-semibold text-primary/80 mb-0.5 truncate max-w-[180px]">
                                                                                    {partnerName}
                                                                                </p>
                                                                            )}

                                                                            {msg.image && (
                                                                                <div className="mb-1.5 rounded-md overflow-hidden max-w-[200px]">
                                                                                    <img
                                                                                        src={msg.image}
                                                                                        alt="Shared"
                                                                                        className="max-w-full h-auto object-cover max-h-[140px] cursor-pointer hover:opacity-90 transition-opacity"
                                                                                        loading="lazy"
                                                                                        onClick={() => setPreviewImage(msg.image || null)}
                                                                                    />
                                                                                </div>
                                                                            )}


                                                                            <p className="text-[13px] leading-snug whitespace-pre-wrap break-words overflow-hidden"
                                                                                style={{ wordBreak: 'break-word', overflowWrap: 'anywhere' }}>
                                                                                {msg.message}
                                                                            </p>

                                                                            {/* Time stamp */}
                                                                            <div className={cn(
                                                                                "flex items-center gap-0.5 mt-0.5",
                                                                                isAdmin ? "justify-end" : "justify-end"
                                                                            )}>
                                                                                <span className={cn(
                                                                                    "text-[9px]",
                                                                                    isAdmin ? "text-primary-foreground/60" : "text-muted-foreground/60"
                                                                                )}>
                                                                                    {format(new Date(msg.createdAt), "h:mm a")}
                                                                                </span>
                                                                                {isAdmin && <CheckCheck className="w-3 h-3 text-primary-foreground/60" />}
                                                                            </div>
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        );
                                                    })}
                                                </div>
                                            );
                                        });
                                    })()
                                ) : (
                                    <div className="flex flex-col items-center justify-center py-12 text-center">
                                        <div className="w-10 h-10 rounded-full bg-muted flex items-center justify-center mb-2">
                                            <MessageSquare className="w-5 h-5 text-muted-foreground/50" />
                                        </div>
                                        <p className="text-xs font-medium text-muted-foreground">No messages yet</p>
                                        <p className="text-[10px] text-muted-foreground/60 mt-0.5">Start the conversation</p>
                                    </div>
                                )}

                                {isTyping && (
                                    <div className="flex w-full justify-start">
                                        <div className="flex gap-1.5 items-end">
                                            <Avatar className="h-6 w-6">
                                                <AvatarImage src={selectedChat?.user?.profilePicture || selectedChat?.kitchen?.kitchenProfilePhoto || undefined} />
                                                <AvatarFallback className="text-[9px] bg-muted text-muted-foreground">
                                                    {(selectedChat?.user?.name || selectedChat?.kitchen?.kitchenName || "?").substring(0, 2).toUpperCase()}
                                                </AvatarFallback>
                                            </Avatar>
                                            <div className="bg-background border border-border/50 rounded-2xl rounded-bl-md px-3 py-2">
                                                <div className="flex items-center gap-1">
                                                    <span className="w-1.5 h-1.5 bg-muted-foreground/40 rounded-full animate-bounce [animation-delay:-0.3s]"></span>
                                                    <span className="w-1.5 h-1.5 bg-muted-foreground/40 rounded-full animate-bounce [animation-delay:-0.15s]"></span>
                                                    <span className="w-1.5 h-1.5 bg-muted-foreground/40 rounded-full animate-bounce"></span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                )}
                            </>
                        )}
                        {selectedChat?.status === "CLOSED" && (
                            <div className="flex flex-col items-center justify-center py-6 mt-4">
                                <span className="bg-muted px-4 py-1.5 rounded-full text-xs font-medium text-muted-foreground border border-border/50">
                                    Support Request is closed
                                </span>
                            </div>
                        )}
                    </div>
                </ScrollArea>

                <div className="p-3 border-t bg-background flex-shrink-0">
                    <div className="flex gap-2 items-end">
                        <textarea
                            placeholder={selectedChat?.status === "CLOSED" ? "Chat is closed" : "Type a message..."}
                            value={messageInput}
                            onChange={(e) => {
                                onMessageInputChange(e.target.value);
                                e.target.style.height = 'auto';
                                e.target.style.height = Math.min(e.target.scrollHeight, 120) + 'px';
                            }}
                            onKeyDown={(e) => {
                                if (e.key === "Enter" && !e.shiftKey && !isSending && selectedChat?.status !== "CLOSED") {
                                    e.preventDefault();
                                    onSendMessage();
                                    e.currentTarget.style.height = '56px';
                                }
                            }}
                            disabled={isSending || selectedChat?.status === "CLOSED"}
                            rows={2}
                            className="flex-1 min-h-[56px] max-h-[120px] py-2.5 px-4 text-sm rounded-xl border border-border/50 bg-muted/30 resize-none overflow-y-auto focus:outline-none focus:ring-1 focus:ring-primary/30 disabled:opacity-50 disabled:cursor-not-allowed"
                            style={{ height: '56px' }}
                        />
                        <Button
                            onClick={() => {
                                onSendMessage();
                                const textarea = document.querySelector('textarea');
                                if (textarea) textarea.style.height = '56px';
                            }}
                            size="icon"
                            disabled={!messageInput.trim() || isSending || selectedChat?.status === "CLOSED"}
                            className="h-[56px] w-12 rounded-xl flex-shrink-0 flex items-center justify-center"
                        >
                            {isSending ? (
                                <div className="w-5 h-5 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                            ) : (
                                <SendHorizontal className="h-5 w-5" />
                            )}
                        </Button>
                    </div>
                </div>
            </SheetContent>

            <Dialog open={!!previewImage} onOpenChange={(open) => !open && setPreviewImage(null)}>
                <DialogContent className="max-w-3xl w-full p-2 overflow-hidden bg-background/95 backdrop-blur-sm">
                    {previewImage && (
                        <img
                            src={previewImage}
                            alt="Preview"
                            className="max-w-full max-h-[80vh] w-auto h-auto rounded-md mx-auto"
                        />
                    )}
                </DialogContent>
            </Dialog>
        </Sheet >
    );
};
