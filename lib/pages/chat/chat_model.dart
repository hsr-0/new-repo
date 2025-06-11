import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatUser {
  final String id;
  final String name;
  final bool isDoctor;

  ChatUser({required this.id, required this.name, required this.isDoctor});

  types.User toChatUser() {
    return types.User(
      id: id,
      firstName: name,
      metadata: {'isDoctor': isDoctor},
    );
  }
}