class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromMap(Map<dynamic, dynamic> map, String id) {
    return Message(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class Chat {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final String participant1Name;
  final String participant2Name;
  final String? participant1ImageUrl;
  final String? participant2ImageUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool participant1Online;
  final bool participant2Online;

  Chat({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    required this.participant1Name,
    required this.participant2Name,
    this.participant1ImageUrl,
    this.participant2ImageUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.participant1Online = false,
    this.participant2Online = false,
  });

  factory Chat.fromMap(Map<dynamic, dynamic> map, String id) {
    return Chat(
      id: id,
      participant1Id: map['participant1Id'] ?? '',
      participant2Id: map['participant2Id'] ?? '',
      participant1Name: map['participant1Name'] ?? '',
      participant2Name: map['participant2Name'] ?? '',
      participant1ImageUrl: map['participant1ImageUrl'],
      participant2ImageUrl: map['participant2ImageUrl'],
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.parse(map['lastMessageTime'])
          : null,
      participant1Online: map['participant1Online'] ?? false,
      participant2Online: map['participant2Online'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participant1Id': participant1Id,
      'participant2Id': participant2Id,
      'participant1Name': participant1Name,
      'participant2Name': participant2Name,
      if (participant1ImageUrl != null) 'participant1ImageUrl': participant1ImageUrl,
      if (participant2ImageUrl != null) 'participant2ImageUrl': participant2ImageUrl,
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageTime != null) 'lastMessageTime': lastMessageTime!.toIso8601String(),
      'participant1Online': participant1Online,
      'participant2Online': participant2Online,
    };
  }

  String getChatId(String userId) {
    // Generate consistent chat ID regardless of participant order
    final ids = [participant1Id, participant2Id]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  String getOtherParticipantName(String userId) {
    return userId == participant1Id ? participant2Name : participant1Name;
  }

  String? getOtherParticipantImageUrl(String userId) {
    return userId == participant1Id ? participant2ImageUrl : participant1ImageUrl;
  }

  bool isOtherParticipantOnline(String userId) {
    return userId == participant1Id ? participant2Online : participant1Online;
  }
}

