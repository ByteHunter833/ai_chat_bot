import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AiTypingBubble extends StatefulWidget {
  final String reasoningText;

  const AiTypingBubble({super.key, this.reasoningText = ''});

  @override
  State<AiTypingBubble> createState() => _AiTypingBubbleState();
}

class _AiTypingBubbleState extends State<AiTypingBubble>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasReasoning = widget.reasoningText.trim().isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(
              maxWidth: _expanded ? 320 : 210,
              minWidth: 150,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.65),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: Lottie.asset('assets/animations/trail_loading.json'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _expanded
                            ? 'Model reasoning'
                            : 'AI is thinking...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _pulseController,
                      curve: Curves.easeInOut,
                    ),
                    child: Container(
                      height: 1,
                      color: colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasReasoning
                        ? widget.reasoningText.trim()
                        : 'Reasoning stream is not available yet...',
                    style: theme.textTheme.bodySmall,
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    hasReasoning
                        ? _previewReasoning(widget.reasoningText)
                        : 'Tap to expand',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _previewReasoning(String value) {
    final clean = value.replaceAll('\n', ' ').trim();
    if (clean.length <= 70) return clean;
    return '${clean.substring(0, 70)}...';
  }
}
