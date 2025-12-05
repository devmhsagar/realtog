import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/pricing_service.dart';
import '../models/pricing_model.dart';

/// Pricing service provider
final pricingServiceProvider = Provider<PricingService>((ref) {
  return PricingService();
});

/// Pricing plans provider - fetches pricing plans
final pricingPlansProvider = FutureProvider<List<PricingModel>>((ref) async {
  final pricingService = ref.read(pricingServiceProvider);
  final result = await pricingService.getPricingPlans();

  return result.fold(
    (error) => throw Exception(error),
    (plans) => plans,
  );
});

