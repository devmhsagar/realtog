import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _selectedImagesKeyPrefix = 'selected_images_';
  static const String _pricingPlanContextKeyPrefix = 'pricing_plan_context_';

  /// Get storage key for selected images based on pricing plan ID
  String _getSelectedImagesKey(String pricingPlanId) {
    return '$_selectedImagesKeyPrefix$pricingPlanId';
  }

  /// Get storage key for pricing plan context based on pricing plan ID
  String _getPricingPlanContextKey(String pricingPlanId) {
    return '$_pricingPlanContextKeyPrefix$pricingPlanId';
  }

  /// Save selected image paths for a specific package
  Future<void> saveSelectedImages(
    List<String> imagePaths,
    String pricingPlanId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _getSelectedImagesKey(pricingPlanId),
      imagePaths,
    );
  }

  /// Get saved selected image paths for a specific package
  Future<List<String>> getSelectedImages(String pricingPlanId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_getSelectedImagesKey(pricingPlanId)) ?? [];
  }

  /// Save pricing plan context for a specific package
  Future<void> savePricingPlanContext({
    required String pricingPlanId,
    required double basePrice,
    required bool hasDecluttering,
    required int declutteringPrice,
    required double totalPrice,
    required int maxImages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final context = {
      'pricingPlanId': pricingPlanId,
      'basePrice': basePrice,
      'hasDecluttering': hasDecluttering,
      'declutteringPrice': declutteringPrice,
      'totalPrice': totalPrice,
      'maxImages': maxImages,
    };
    await prefs.setString(
      _getPricingPlanContextKey(pricingPlanId),
      jsonEncode(context),
    );
  }

  /// Get saved pricing plan context for a specific package
  Future<Map<String, dynamic>?> getPricingPlanContext(
    String pricingPlanId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final contextString = prefs.getString(
      _getPricingPlanContextKey(pricingPlanId),
    );
    if (contextString == null) return null;
    try {
      return jsonDecode(contextString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Clear selected images for a specific package
  Future<void> clearSelectedImages(String pricingPlanId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getSelectedImagesKey(pricingPlanId));
    await prefs.remove(_getPricingPlanContextKey(pricingPlanId));
  }

  /// Clear all app data (used during logout)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

