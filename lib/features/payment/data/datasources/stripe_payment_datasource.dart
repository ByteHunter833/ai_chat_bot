import 'package:flutter_stripe/flutter_stripe.dart';

/// Stripe datasource built on top of the `flutter_stripe` PaymentSheet.
///
/// Stripe requires a backend to create a `PaymentIntent` and return its
/// client secret. In this demo build the checkout backend is mocked:
/// - `STRIPE_PUBLISHABLE_KEY`  -> Stripe publishable key (test mode).
/// - `STRIPE_CLIENT_SECRET`    -> a client secret produced by a checkout
///   server, injected at build time via `--dart-define`.
///
/// When neither define is present the datasource falls back to a simulated
/// checkout so the flow stays runnable without any backend.
class StripePaymentDataSource {
  static const String _publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  static const String _clientSecret = String.fromEnvironment(
    'STRIPE_CLIENT_SECRET',
    defaultValue: '',
  );

  Future<void> configure() async {
    if (_publishableKey.isEmpty) return;
    Stripe.publishableKey = _publishableKey;
  }

  bool get isConfigured => _clientSecret.isNotEmpty;

  /// Production code would POST to the checkout backend here to obtain a
  /// client secret. For the mock build a build-time value is returned.
  Future<String?> requestPaymentIntentClientSecret() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _clientSecret.isEmpty ? null : _clientSecret;
  }

  Future<bool> presentPaymentSheet(String clientSecret) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Nova AI',
      ),
    );
    await Stripe.instance.presentPaymentSheet();
    return true;
  }
}