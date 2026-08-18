import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nova_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nova_ai/features/auth/presentation/cubit/auth_state.dart';
import 'package:nova_ai/features/auth/presentation/screens/login_screen.dart';
import 'package:nova_ai/features/payment/domain/entities/pro_plan.dart';
import 'package:nova_ai/features/payment/presentation/cubit/payment_cubit.dart';
import 'package:nova_ai/features/payment/presentation/cubit/payment_state.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova AI Pro')),
      body: SafeArea(
        child: BlocListener<PaymentCubit, PaymentState>(
          listenWhen: (previous, current) =>
              current.purchaseComplete && !previous.purchaseComplete,
          listener: (context, state) {
            context.read<AuthCubit>().grantPro();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Welcome to Nova AI Pro!')),
            );
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: BlocListener<PaymentCubit, PaymentState>(
            listenWhen: (previous, current) =>
                current.errorMessage != null &&
                previous.errorMessage != current.errorMessage,
            listener: (context, state) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            },
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState.isPro) {
                  return const _AlreadyProView();
                }
                if (!authState.isAuthenticated) {
                  return const _SignInRequiredView();
                }
                return const _CheckoutView();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  static const List<(IconData, String, String)> _features = [
    (
      Icons.smart_toy_outlined,
      'Roleplay model',
      'Ling 3.0 Flash — immersive roleplay conversations',
    ),
    (
      Icons.code_outlined,
      'Coding model',
      'North Mini Code — fast code generation and refactoring',
    ),
    (Icons.remove_red_eye_outlined, 'Priority access', 'Faster responses during peak hours'),
    (
      Icons.workspace_premium_outlined,
      'Pro badge',
      'Support development of Nova AI',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Nova AI Pro',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock every model and priority access.',
                  style: TextStyle(color: Colors.white.withValues(alpha: .9)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (final (icon, title, subtitle) in _features) ...[
            _FeatureRow(icon: icon, title: title, subtitle: subtitle),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          BlocBuilder<PaymentCubit, PaymentState>(
            builder: (context, paymentState) {
              return Row(
                children: [
                  Expanded(
                    child: _PlanCard(
                      plan: ProPlan.monthly,
                      selected: paymentState.selectedPlan == ProPlan.monthly,
                      onTap: () => context.read<PaymentCubit>().selectPlan(
                        ProPlan.monthly,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PlanCard(
                      plan: ProPlan.yearly,
                      selected: paymentState.selectedPlan == ProPlan.yearly,
                      onTap: () => context.read<PaymentCubit>().selectPlan(
                        ProPlan.yearly,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          BlocBuilder<PaymentCubit, PaymentState>(
            builder: (context, paymentState) {
              return FilledButton(
                onPressed: paymentState.isLoading
                    ? null
                    : () => context.read<PaymentCubit>().subscribe(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: paymentState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Subscribe · ${paymentState.selectedPlan.priceLabel}'
                        '${paymentState.selectedPlan.periodLabel}',
                      ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Payments are processed securely by Stripe. Cancel anytime.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final ProPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: .55)
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    plan.label,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (plan.savingsLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        plan.savingsLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.priceLabel,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    plan.periodLabel,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInRequiredView extends StatelessWidget {
  const _SignInRequiredView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_circle_outlined, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Sign in to subscribe',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a free account to unlock Nova AI Pro.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text('Continue with account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlreadyProView extends StatelessWidget {
  const _AlreadyProView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'You are Pro',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'All models are unlocked. Enjoy!',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}