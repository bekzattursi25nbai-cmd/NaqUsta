class ChatModel {
  final int id;
  final String name;
  final String img;
  final String lastMessage;
  final String time;
  final int unread;
  final bool online;

  ChatModel({
    required this.id,
    required this.name,
    required this.img,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.online,
  });
}