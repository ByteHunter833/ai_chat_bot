import 'package:equatable/equatable.dart';
import 'package:nova_ai/features/payment/domain/entities/pro_plan.dart';

class PaymentState extends Equatable {
  final ProPlan selectedPlan;
  final bool isLoading;
  final bool purchaseComplete;
  final String? errorMessage;

  const PaymentState({
    this.selectedPlan = ProPlan.monthly,
    this.isLoading = false,
    this.purchaseComplete = false,
    this.errorMessage,
  });

  PaymentState copyWith({
    ProPlan? selectedPlan,
    bool? isLoading,
    bool? purchaseComplete,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PaymentState(
      selectedPlan: selectedPlan ?? this.selectedPlan,
      isLoading: isLoading ?? this.isLoading,
      purchaseComplete: purchaseComplete ?? this.purchaseComplete,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [selectedPlan, isLoading, purchaseComplete, errorMessage];
}