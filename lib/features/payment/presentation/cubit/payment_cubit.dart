import 'package:bloc/bloc.dart';
import 'package:nova_ai/features/payment/domain/entities/pro_plan.dart';
import 'package:nova_ai/features/payment/domain/repositories/payment_repository.dart';
import 'package:nova_ai/features/payment/presentation/cubit/payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository paymentRepository;

  PaymentCubit(this.paymentRepository) : super(const PaymentState());

  void selectPlan(ProPlan plan) {
    emit(state.copyWith(selectedPlan: plan, clearError: true));
  }

  Future<void> subscribe() async {
    if (state.isLoading) return;
    emit(
      state.copyWith(
        isLoading: true,
        purchaseComplete: false,
        clearError: true,
      ),
    );
    try {
      await paymentRepository.configure();
      final intent = await paymentRepository.createPaymentIntent(
        state.selectedPlan,
      );
      if (intent.isSimulated) {
        // Mock checkout: simulate network + processing latency so the flow
        // works without a Stripe backend configured.
        await Future<void>.delayed(const Duration(seconds: 1));
      } else {
        await paymentRepository.presentPaymentSheet(intent);
      }
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, purchaseComplete: true));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    }
  }

  void reset() {
    emit(const PaymentState());
  }
}