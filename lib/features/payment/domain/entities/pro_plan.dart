enum ProPlan { monthly, yearly }

extension ProPlanX on ProPlan {
  String get id => switch (this) {
        ProPlan.monthly => 'price_pro_monthly',
        ProPlan.yearly => 'price_pro_yearly',
      };

  String get label => switch (this) {
        ProPlan.monthly => 'Monthly',
        ProPlan.yearly => 'Yearly',
      };

  double get price => switch (this) {
        ProPlan.monthly => 4.99,
        ProPlan.yearly => 49.99,
      };

  String get priceLabel => switch (this) {
        ProPlan.monthly => r'$4.99',
        ProPlan.yearly => r'$49.99',
      };

  String get periodLabel => switch (this) {
        ProPlan.monthly => '/month',
        ProPlan.yearly => '/year',
      };

  String get savingsLabel => switch (this) {
        ProPlan.monthly => null,
        ProPlan.yearly => 'Save 17%',
      } ?? '';
}