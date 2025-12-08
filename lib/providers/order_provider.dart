import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/order_service.dart';
import '../models/order_model.dart';
import 'auth_provider.dart';

/// Order service provider
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

/// Orders provider - fetches all orders for the current user
/// Automatically invalidates when auth state changes
final ordersProvider = FutureProvider<List<OrderModel>>((ref) async {
  // Watch auth state to automatically invalidate when auth changes
  final authState = ref.watch(authNotifierProvider);
  
  // Only fetch if authenticated
  if (!authState.isAuthenticated) {
    throw Exception('User not authenticated');
  }
  
  final orderService = ref.read(orderServiceProvider);
  final result = await orderService.getOrders();

  return result.fold(
    (error) => throw Exception(error),
    (orders) => orders,
  );
});

