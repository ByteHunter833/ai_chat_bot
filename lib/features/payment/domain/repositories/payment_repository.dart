import 'package:nova_ai/features/payment/domain/entities/payment_intent.dart';
import 'package:nova_ai/features/payment/domain/entities/pro_plan.dart';

abstract class PaymentRepository {
  Future<void> configure();

  Future<PaymentIntent> createPaymentIntent(ProPlan plan);

  Future<bool> presentPaymentSheet(PaymentIntent intent);
}