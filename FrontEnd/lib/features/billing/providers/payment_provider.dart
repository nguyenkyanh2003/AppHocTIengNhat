import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/payment_plan.dart';
import '../services/transaction_service.dart';

/// Gói đang chọn và yêu cầu đăng ký gói đang gửi.
///
/// Phiên bản đồ án không thu tiền tự động: gửi chỉ tạo một yêu cầu chờ quản trị
/// viên duyệt, nên kết quả là "đã gửi" hoặc câu báo lỗi để màn hiện.
class PaymentProvider extends ChangeNotifier {
  PaymentProvider({TransactionService? service}) : _service = service ?? TransactionService();

  final TransactionService _service;

  String _selectedPlanId = paymentPlans.first.id;
  bool _submitting = false;
  bool _disposed = false;

  PaymentPlan get selectedPlan => paymentPlans.firstWhere((plan) => plan.id == _selectedPlanId);
  bool get isSubmitting => _submitting;

  /// Gói miễn phí là gói đang dùng, không có gì để đăng ký.
  bool get isFreePlanSelected => selectedPlan.amount == 0;
  bool get canSubmit => !isFreePlanSelected && !_submitting;

  void selectPlan(String planId) {
    if (planId == _selectedPlanId) return;
    _selectedPlanId = planId;
    _notify();
  }

  /// Gửi yêu cầu đăng ký gói đang chọn; trả `null` khi đã gửi, hoặc câu báo lỗi.
  Future<String?> submit() async {
    if (isFreePlanSelected) return 'Chọn một gói trả phí để đăng ký.';
    if (_submitting) return 'Yêu cầu trước vẫn đang được gửi.';
    final plan = selectedPlan;
    _submitting = true;
    _notify();
    try {
      await _service.createSubscriptionRequest(packageId: plan.id, amount: plan.amount);
      return null;
    } catch (error) {
      return userMessageOf(error);
    } finally {
      _submitting = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
