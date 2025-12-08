class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderType; // 'user' or 'admin'
  final String content;
  final String timestamp;
  final bool read;
  final List<String> images;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.timestamp,
    required this.read,
    required this.images,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderType: json['senderType'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] as String,
      read: json['read'] as bool? ?? false,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'content': content,
      'timestamp': timestamp,
      'read': read,
      'images': images,
    };
  }

  bool get isUserMessage => senderType == 'user';
  bool get isAdminMessage => senderType == 'admin';
}

