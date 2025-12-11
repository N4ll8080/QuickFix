import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessagingServiceFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate consistent chat ID
  String _generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Get or create a chat between two users
  Future<String> getOrCreateChat(
    String userId1,
    String userId2,
    String userName1,
    String userName2, {
    String? userImageUrl1,
    String? userImageUrl2,
  }) async {
    final chatId = _generateChatId(userId1, userId2);
    final chatRef = _firestore.collection('chats').doc(chatId);

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
      'createdAt': FieldValue.serverTimestamp(),
    });

    return chatId;
  }

  // Send a message
  Future<void> sendMessage(
    String chatId,
    String senderId,
    String receiverId,
    String text,
  ) async {
    final messagesRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    final messageData = {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    await messagesRef.add(messageData);

    // Update chat's last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Get messages for a chat
  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Message(
          id: doc.id,
          chatId: data['chatId'] ?? '',
          senderId: data['senderId'] ?? '',
          receiverId: data['receiverId'] ?? '',
          text: data['text'] ?? '',
          timestamp: data['timestamp'] != null
              ? (data['timestamp'] is DateTime
                  ? data['timestamp'] as DateTime
                  : (data['timestamp'] as dynamic).toDate())
              : DateTime.now(),
          isRead: data['isRead'] ?? false,
        );
      }).toList();
    });
  }

  // Get all chats for a user
  Stream<List<Chat>> getUserChats(String userId) {
    // Use a StreamController to combine both queries
    final controller = StreamController<List<Chat>>();
    final chatsMap = <String, Chat>{};

    void emitCombined() {
      final chats = chatsMap.values.toList();
      chats.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      controller.add(chats);
    }

    // Listen to participant1 chats
    _firestore
        .collection('chats')
        .where('participant1Id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        chatsMap[doc.id] = Chat.fromMap(data, doc.id);
      }
      emitCombined();
    });

    // Listen to participant2 chats
    _firestore
        .collection('chats')
        .where('participant2Id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        chatsMap[doc.id] = Chat.fromMap(data, doc.id);
      }
      emitCombined();
    });

    return controller.stream;
  }

  // Mark message as read
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  // Update user online status
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    final chatsSnapshot = await _firestore
        .collection('chats')
        .where('participant1Id', isEqualTo: userId)
        .get();
    for (var doc in chatsSnapshot.docs) {
      await doc.reference.update({'participant1Online': isOnline});
    }

    final chatsSnapshot2 = await _firestore
        .collection('chats')
        .where('participant2Id', isEqualTo: userId)
        .get();
    for (var doc in chatsSnapshot2.docs) {
      await doc.reference.update({'participant2Online': isOnline});
    }
  }
}

