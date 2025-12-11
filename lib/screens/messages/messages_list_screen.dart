import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/messaging_service_firestore.dart';
import '../../models/message_model.dart';
import 'chat_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  final MessagingServiceFirestore _messagingService =
      MessagingServiceFirestore();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B84FF)),
              ),
            );
          }

          final user = authSnapshot.data;
          if (user == null) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Please log in to view messages',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            );
          }

          return StreamBuilder<List<Chat>>(
            stream: _messagingService.getUserChats(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF0B84FF),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  ),
                );
              }

              final chats = snapshot.data ?? [];

              return CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(0xFF0B84FF),
                    flexibleSpace: const FlexibleSpaceBar(
                      title: Text(
                        'Messages',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      centerTitle: true,
                    ),
                  ),
                  // Chat List
                  if (chats.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.message_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start a conversation with a provider',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final chat = chats[index];
                          return _buildChatCard(chat, user.uid);
                        }, childCount: chats.length),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatCard(Chat chat, String currentUserId) {
    final otherParticipantName = chat.getOtherParticipantName(currentUserId);
    final otherParticipantImageUrl = chat.getOtherParticipantImageUrl(
      currentUserId,
    );
    final isOnline = chat.isOtherParticipantOnline(currentUserId);
    final lastMessage = chat.lastMessage ?? 'No messages yet';
    final lastMessageTime = chat.lastMessageTime;

    String timeText = '';
    if (lastMessageTime != null) {
      final now = DateTime.now();
      final difference = now.difference(lastMessageTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          timeText = '${difference.inMinutes}m ago';
        } else {
          timeText = '${difference.inHours}h ago';
        }
      } else if (difference.inDays == 1) {
        timeText = 'Yesterday';
      } else if (difference.inDays < 7) {
        timeText = '${difference.inDays}d ago';
      } else {
        timeText = '${lastMessageTime.day}/${lastMessageTime.month}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: chat.id,
                  otherUserId: currentUserId == chat.participant1Id
                      ? chat.participant2Id
                      : chat.participant1Id,
                  otherUserName: otherParticipantName,
                  otherUserImageUrl: otherParticipantImageUrl,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Picture with Online Indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      child:
                          otherParticipantImageUrl != null &&
                              otherParticipantImageUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                otherParticipantImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey,
                            ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Chat Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              otherParticipantName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeText.isNotEmpty)
                            Text(
                              timeText,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
