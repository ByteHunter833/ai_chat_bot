import 'package:flutter/widgets.dart';
import 'package:nova_ai/core/shared_widgets/chat/suggestion_card.dart';
import 'package:nova_ai/features/chat/data/models/suggestions.dart';

class SuggestionList extends StatelessWidget {
  final void Function(Suggestion) onSuggestionTap;
  final List<Suggestion> suggestions;
  const SuggestionList({
    super.key,
    required this.onSuggestionTap,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onSuggestionTap(suggestions[index]),
            child: SuggestionCard(suggestion: suggestions[index]),
          );
        },
        itemCount: suggestions.length,
      ),
    );
  }
}
