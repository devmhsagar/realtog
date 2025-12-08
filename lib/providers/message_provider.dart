import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/message_service.dart';
import '../models/message_model.dart';

/// Message service provider
final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService();
});

/// Messages provider - fetches all messages between user and admin
final messagesProvider = FutureProvider<List<MessageModel>>((ref) async {
  final messageService = ref.read(messageServiceProvider);
  final result = await messageService.getMessages();

  return result.fold(
    (error) => throw Exception(error),
    (messages) => messages,
  );
});

