import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class AiMessageBubble extends StatelessWidget {
  final String text;
  final VoidCallback? onCopyAll;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final bool isLoading;
  final String? reasoningText;
  final bool isReasoningStreaming;

  const AiMessageBubble({
    super.key,
    required this.text,
    this.onCopyAll,
    this.onLike,
    this.onDislike,
    this.isLoading = false,
    this.reasoningText,
    this.isReasoningStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((reasoningText ?? '').trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ReasoningPanel(
              reasoningText: reasoningText!.trim(),
              isStreaming: isReasoningStreaming,
            ),
          ),
        SmoothMarkdown(
          selectable: true,
          data: text,
          styleSheet: MarkdownStyleSheet.vscode(),
          builderRegistry: BuilderRegistry()
            ..register(
              'code_block',
              EnhancedCodeBlockBuilder(
                showCopyButton: true,
                showLanguageTag: true,
                enableSyntaxHighlighting: true,
              ),
            ),
          onTapLink: (String url) async {
            final uri = Uri.parse(url);

            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.inAppWebView);
            } else {
              debugPrint('Не удалось открыть $url');
            }
          },
        ),

        const SizedBox(height: 6),

        isLoading
            ? SizedBox(height: 24, width: 24)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onCopyAll != null)
                    _ActionButton(
                      icon: Icons.copy_outlined,
                      tooltip: 'Copy',
                      onPressed: onCopyAll!,
                    ),
                  if (onLike != null)
                    _ActionButton(
                      icon: Icons.thumb_up_alt_outlined,
                      tooltip: 'Good response',
                      onPressed: onLike!,
                    ),
                  if (onDislike != null)
                    _ActionButton(
                      icon: Icons.thumb_down_alt_outlined,
                      tooltip: 'Bad response',
                      onPressed: onDislike!,
                    ),
                ],
              ),
      ],
    );
  }
}

class _ReasoningPanel extends StatefulWidget {
  final String reasoningText;
  final bool isStreaming;

  const _ReasoningPanel({
    required this.reasoningText,
    required this.isStreaming,
  });

  @override
  State<_ReasoningPanel> createState() => _ReasoningPanelState();
}

class _ReasoningPanelState extends State<_ReasoningPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology_alt_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isStreaming
                        ? 'Reasoning (live)'
                        : 'Reasoning (saved)',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
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
                Text(
                  widget.reasoningText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
          ),
        ),
      ),
    );
  }
}
