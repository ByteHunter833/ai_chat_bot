import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class AiMessageBubble extends StatelessWidget {
  final String text;

  const AiMessageBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmoothMarkdown(
            selectable: true,
            data: text,
            styleSheet: MarkdownStyleSheet.vscode(),
            builderRegistry: BuilderRegistry()
              ..register(
                'code_block',
                const EnhancedCodeBlockBuilder(
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
          Row(
            children: [
              ActionButton(
                icon: Icons.copy,
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
              ActionButton(
                icon: Icons.thumb_up_alt_outlined,
                tooltip: 'Like',
                onPressed: () {},
              ),
              ActionButton(
                icon: Icons.thumb_down_outlined,
                tooltip: 'Dislike',
                onPressed: () {
                  // Handle dislike action
                },
              ),
            ],
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const ActionButton({
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
