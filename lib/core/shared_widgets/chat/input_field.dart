import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final TextEditingController messageController;
  final bool hasText;
  final VoidCallback? onSend;
  final void Function()? onPressed;

  const InputField({
    super.key,
    required this.messageController,
    required this.hasText,
    this.onSend,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _RoundIconButton(
            icon: Icons.add,
            background: colorScheme.surfaceContainerHigh,
            foreground: colorScheme.onSurfaceVariant,
            onPressed: onPressed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: TextField(
                controller: messageController,
                minLines: 1,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.arrow_upward_rounded,
            background: hasText
                ? colorScheme.primary
                : colorScheme.surfaceContainerHigh,
            foreground: hasText
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            onPressed: hasText ? onSend : null,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  const _RoundIconButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: foreground, size: 22),
        ),
      ),
    );
  }
}
