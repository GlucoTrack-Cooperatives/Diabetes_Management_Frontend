import 'dart:convert';

class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      senderId: json['senderId'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ChatThread {
  final String id;
  final String physicianName;
  final String participantName;
  final String patientId;
  final String lastMessage;
  final DateTime lastMessageTime;

  ChatThread({
    required this.id,
    required this.physicianName,
    required this.participantName,
    required this.patientId,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'] ?? '',
      physicianName: json['physicianName'] ?? '',
      participantName: json['participantName'] ?? '',
      patientId: json['patientId'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime']) 
          : DateTime.now(),
    );
  }
}
