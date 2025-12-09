import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/message_model.dart';

class MessagingService {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://quick-fix-89d7f-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  // Generate consistent chat ID
  String _generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Get or create a chat between two users
  Future<String> getOrCreateChat(String userId1, String userId2, String userName1, String userName2, {String? userImageUrl1, String? userImageUrl2}) async {
    final chatId = _generateChatId(userId1, userId2);
    final chatRef = _db.ref('chats/$chatId');

    // Check if chat exists
    final snapshot = await chatRef.get();
    if (snapshot.exists) {
      return chatId;
    }

    // Create new chat
    await chatRef.set({
      'participant1Id': userId1,
      'participant2Id': userId2,
      'participant1Name': userName1,
      'participant2Name': userName2,
      if (userImageUrl1 != null) 'participant1ImageUrl': userImageUrl1,
      if (userImageUrl2 != null) 'participant2ImageUrl': userImageUrl2,
      'participant1Online': false,
      'participant2Online': false,
    });

    return chatId;
  }

  // Send a message
  Future<void> sendMessage(String chatId, String senderId, String receiverId, String text) async {
    final messageRef = _db.ref('messages').push();
    final message = Message(
      id: messageRef.key!,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: DateTime.now(),
    );

    await messageRef.set(message.toMap());

    // Update chat's last message
    await _db.ref('chats/$chatId').update({
      'lastMessage': text,
      'lastMessageTime': DateTime.now().toIso8601String(),
    });
  }

  // Get messages for a chat
  Stream<List<Message>> getMessages(String chatId) {
    return _db
        .ref('messages')
        .orderByChild('chatId')
        .equalTo(chatId)
        .onValue
        .map((event) {
      final List<Message> messages = [];
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          messages.add(Message.fromMap(value, key));
        });
      }
      // Sort by timestamp ascending
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  // Get all chats for a user
  Stream<List<Chat>> getUserChats(String userId) {
    return _db.ref('chats').onValue.map((event) {
      final List<Chat> chats = [];
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final chat = Chat.fromMap(value, key);
          // Only include chats where user is a participant
          if (chat.participant1Id == userId || chat.participant2Id == userId) {
            chats.add(chat);
          }
        });
      }
      // Sort by last message time descending
      chats.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      return chats;
    });
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    await _db.ref('messages/$messageId').update({'isRead': true});
  }

  // Update user online status
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    // Update in all chats where user is participant
    final chatsSnapshot = await _db.ref('chats').get();
    if (chatsSnapshot.exists) {
      final Map<dynamic, dynamic> chats = chatsSnapshot.value as Map<dynamic, dynamic>;
      chats.forEach((chatId, chatData) {
        final chat = chatData as Map<dynamic, dynamic>;
        if (chat['participant1Id'] == userId) {
          _db.ref('chats/$chatId').update({'participant1Online': isOnline});
        } else if (chat['participant2Id'] == userId) {
          _db.ref('chats/$chatId').update({'participant2Online': isOnline});
        }
      });
    }
  }
}

