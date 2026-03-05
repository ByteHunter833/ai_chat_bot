import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class AiMessageBubble extends StatelessWidget {
  final String text;
  final VoidCallback? onCopyAll;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final bool isLoading;

  const AiMessageBubble({
    super.key,
    required this.text,
    this.onCopyAll,
    this.onLike,
    this.onDislike,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
