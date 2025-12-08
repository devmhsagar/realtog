import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/order_service.dart';
import '../models/order_model.dart';

/// Order service provider
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

/// Orders provider - fetches all orders for the current user
final ordersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final orderService = ref.read(orderServiceProvider);
  final result = await orderService.getOrders();

  return result.fold(
    (error) => throw Exception(error),
    (orders) => orders,
  );
});

