import 'package:nova_ai/features/payment/data/datasources/stripe_payment_datasource.dart';
import 'package:nova_ai/features/payment/domain/entities/payment_intent.dart';
import 'package:nova_ai/features/payment/domain/entities/pro_plan.dart';
import 'package:nova_ai/features/payment/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final StripePaymentDataSource stripeDataSource;

  PaymentRepositoryImpl(this.stripeDataSource);

  @override
  Future<void> configure() => stripeDataSource.configure();

  @override
  Future<PaymentIntent> createPaymentIntent(ProPlan plan) async {
    final clientSecret = await stripeDataSource.requestPaymentIntentClientSecret();
    return PaymentIntent(
      plan: plan,
      clientSecret: clientSecret ?? '',
      isSimulated: clientSecret == null,
    );
  }

  @override
  Future<bool> presentPaymentSheet(PaymentIntent intent) {
    if (intent.isSimulated || intent.clientSecret.isEmpty) {
      return Future.value(true);
    }
    return stripeDataSource.presentPaymentSheet(intent.clientSecret);
  }
}