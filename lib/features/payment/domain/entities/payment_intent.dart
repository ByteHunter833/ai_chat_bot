import 'package:nova_ai/features/payment/domain/entities/pro_plan.dart';

class PaymentIntent {
  final ProPlan plan;
  final String clientSecret;
  final bool isSimulated;

  const PaymentIntent({
    required this.plan,
    required this.clientSecret,
    required this.isSimulated,
  });
}