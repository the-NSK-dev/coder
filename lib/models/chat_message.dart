class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final DateTime timestamp;
  final List<MessageAttachment> attachments;
  final bool isPlanOrStatus;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.attachments = const [],
    this.isPlanOrStatus = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'isPlanOrStatus': isPlanOrStatus,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sender: json['sender'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isPlanOrStatus: json['isPlanOrStatus'] as bool? ?? false,
    );
  }
}

class MessageAttachment {
  final String name;
  final String type;

  MessageAttachment({required this.name, required this.type});

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
      };

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }
}
