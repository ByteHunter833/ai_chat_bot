import 'package:flutter/material.dart';
import 'package:nova_ai/features/chat/presentation/widgets/rounded_icon.dart';

class ModelTile extends StatelessWidget {
  const ModelTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.idModel,
    this.selected = false,
    this.supportsVision = false,
    this.supportsReasoning = false,
    this.goodForRoleplay = false,
    this.isPro = false,
    this.isProUnlocked = true,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String idModel;

  final bool selected;
  final bool supportsVision;
  final bool supportsReasoning;
  final bool goodForRoleplay;
  final bool isPro;
  final bool isProUnlocked;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isProLocked = isPro && !isProUnlocked;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? colors.primaryContainer.withOpacity(.55)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (isPro) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: colors.tertiaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .5,
                                  color: colors.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 2),

                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selected
                      ? Icon(
                          Icons.check_circle,
                          key: const ValueKey(true),
                          color: colors.primary,
                        )
                      : isProLocked
                      ? Icon(
                          Icons.lock_outline,
                          key: const ValueKey('lock'),
                          color: colors.onSurfaceVariant,
                        )
                      : const SizedBox(key: ValueKey(false), width: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModalItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  const ModalItem({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          RoundedIconButton(child: Icon(icon)),
          Text(text),
        ],
      ),
    );
  }
}
