import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/message_service.dart';
import '../models/message_model.dart';
import 'auth_provider.dart';

/// Message service provider
final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService();
});

/// Messages provider - fetches all messages between user and admin
/// Automatically invalidates when auth state changes
final messagesProvider = FutureProvider<List<MessageModel>>((ref) async {
  // Watch auth state to automatically invalidate when auth changes
  final authState = ref.watch(authNotifierProvider);
  
  // Only fetch if authenticated
  if (!authState.isAuthenticated) {
    throw Exception('User not authenticated');
  }
  
  final messageService = ref.read(messageServiceProvider);
  final result = await messageService.getMessages();

  return result.fold(
    (error) => throw Exception(error),
    (messages) => messages,
  );
});

