import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/user_plan.dart';

class SubscriptionProvider extends ChangeNotifier {
  UserPlan _plan = UserPlan.freeFallback;
  bool _isLoading = false;

  UserPlan get plan => _plan;
  bool get isPro => _plan.isPro;
  bool get isAiFull => _plan.isAiFull;
  int get aiUsed => _plan.aiUsed;
  int get aiLimit => _plan.aiLimit;
  String get resetDate => _plan.resetDate;
  bool get isLoading => _isLoading;

  Future<void> fetch() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiClient.get('/subscription');
      _plan = UserPlan.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      _plan = UserPlan.freeFallback;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetch();

  Future<bool> verifyPurchase({
    required String purchaseToken,
    required String productId,
  }) async {
    try {
      await ApiClient.post('/subscription/verify', data: {
        'purchase_token': purchaseToken,
        'product_id': productId,
        'platform': 'android',
      });
      await fetch();
      return true;
    } catch (_) {
      return false;
    }
  }
}
