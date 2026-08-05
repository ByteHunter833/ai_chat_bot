import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:nova_ai/core/theme/cubit/theme_cubit.dart';
import 'package:nova_ai/core/theme/cubit/theme_state.dart';
import 'package:url_launcher/url_launcher.dart';

class AiMessageBubble extends StatelessWidget {
  final String text;
  final bool showActions;

  const AiMessageBubble({
    super.key,
    required this.text,
    this.showActions = true,
  });

  void feedback(String feedbackType, BuildContext conn) {
    ScaffoldMessenger.of(conn).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SmoothMarkdown(
              selectable: true,
              data: text,
              styleSheet: MarkdownStyleSheet.vscode(
                brightness: state.themeMode == ThemeMode.dark
                    ? Brightness.dark
                    : Brightness.light,
              ),
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: child,
                  ),
                );
              },
              child: showActions
                  ? Padding(
                      key: const ValueKey('ai-message-actions'),
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          ActionButton(
                            icon: Icons.copy,
                            tooltip: 'Copy',
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: text),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copied to clipboard'),
                                ),
                              );
                            },
                          ),
                          ActionButton(
                            icon: Icons.thumb_up_alt_outlined,
                            tooltip: 'Like',
                            onPressed: () {
                              feedback('Like', context);
                            },
                          ),
                          ActionButton(
                            icon: Icons.thumb_down_outlined,
                            tooltip: 'Dislike',
                            onPressed: () {
                              feedback('Dislike', context);
                            },
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('ai-message-actions-hidden'),
                    ),
            ),
          ],
        ),
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
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}
