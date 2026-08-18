class OpenRouterModel {
  final String id;
  final String name;
  final String description;
  final bool supportsVision;
  final bool goodForRoleplay;
  final bool supportsReasoning;
  final bool isPro;

  const OpenRouterModel({
    required this.id,
    required this.name,
    required this.description,
    this.supportsVision = false,
    this.goodForRoleplay = false,
    this.supportsReasoning = false,
    this.isPro = false,
  });
}
