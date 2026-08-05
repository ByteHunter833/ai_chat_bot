import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nova_ai/core/theme/theme_cubit.dart';
import 'package:nova_ai/core/theme/theme_state.dart';
import 'package:nova_ai/features/chat/data/models/open_router_model.dart';
import 'package:nova_ai/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:nova_ai/features/chat/presentation/widgets/model_item.dart';
import 'package:nova_ai/features/chat/presentation/widgets/rounded_icon.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatCubit chatCubit;

  const ChatAppBar({required this.chatCubit, super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      leading: Builder(
        builder: (context) {
          return RoundedIconButton(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: SvgPicture.asset(
              'assets/icons/menu_ic.svg',
              colorFilter: ColorFilter.mode(
                colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
          );
        },
      ),
      title: Anchor(
        placement: Placement.bottom,

        overlayBuilder: (context) =>
            _buildModelMenu(context, chatCubit.state.models),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nova AI', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
      actions: [
        BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            final isDark = state.themeMode == ThemeMode.dark;
            return RoundedIconButton(
              onTap: context.read<ThemeCubit>().toggle,
              child: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: colorScheme.onSurface,
                size: 22,
              ),
            );
          },
        ),
        RoundedIconButton(
          onTap: chatCubit.startNewChat,
          child: SvgPicture.asset(
            'assets/icons/new_chat_ic.svg',
            colorFilter: ColorFilter.mode(
              colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

Widget _buildModelMenu(BuildContext context, List<OpenRouterModel> models) {
  final colors = Theme.of(context).colorScheme;
  final chatCubit = context.read<ChatCubit>();
  return BlocBuilder<ChatCubit, ChatState>(
    builder: (context, state) {
      return Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          constraints: const BoxConstraints(maxHeight: 420),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant.withOpacity(.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  shrinkWrap: true,
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    final model = models[index];
                    final isSelected = model.id == state.selectedModel;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ModelTile(
                        title: model.name,
                        subtitle: model.description,
                        selected: isSelected,
                        idModel: model.id,
                        onTap: () {
                          chatCubit.setSelectedModel(model.id);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
