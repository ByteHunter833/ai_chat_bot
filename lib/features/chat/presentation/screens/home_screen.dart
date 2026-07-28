import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:nova_ai/core/shared_widgets/chat/ai_message_buble.dart';
import 'package:nova_ai/core/shared_widgets/chat/ai_typing_buble.dart';
import 'package:nova_ai/core/shared_widgets/chat/chat_history_drawer.dart';
import 'package:nova_ai/core/shared_widgets/chat/input_field.dart';
import 'package:nova_ai/core/shared_widgets/chat/suggestion_card.dart';
import 'package:nova_ai/core/shared_widgets/chat/user_message_buble.dart';
import 'package:nova_ai/core/theme/theme_cubit.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';
import 'package:nova_ai/features/chat/data/models/suggestions.dart';
import 'package:nova_ai/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:nova_ai/service/file_picker_service.dart';

String _guessMimeType(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    default:
      return 'application/octet-stream';
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController messageController = TextEditingController();
  final FilePickerService fileService = FilePickerService();
  XFile? attachedImage;

  void handleSuggestionTap(Suggestion suggestion) {
    messageController.text = suggestion.text + ' ' + suggestion.description;
  }

  bool hasText() {
    return messageController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    messageController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndAttach(
    BuildContext sheetContext,
    Future<XFile?> Function() pick,
  ) async {
    Navigator.pop(sheetContext);
    final file = await pick();
    if (file == null) return;
    if (!_guessMimeType(file.path).startsWith('image/')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only images are supported right now')),
      );
      return;
    }
    setState(() => attachedImage = file);
  }

  void openBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModalItem(
                icon: CupertinoIcons.photo,
                text: 'Photos',
                onTap: () => _pickAndAttach(
                  sheetContext,
                  fileService.pickImageFromGallery,
                ),
              ),
              const SizedBox(height: 20),
              ModalItem(
                icon: CupertinoIcons.photo_camera,
                text: 'Camera',
                onTap: () => _pickAndAttach(
                  sheetContext,
                  fileService.pickImageFromCamera,
                ),
              ),
              const SizedBox(height: 20),
              ModalItem(
                icon: CupertinoIcons.paperclip,
                text: 'Files',
                onTap: () => _pickAndAttach(sheetContext, fileService.pickFile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(ChatCubit chatCubit) async {
    if (!hasText() && attachedImage == null) return;
    String? imageBase64;
    String? imageMimeType;
    final image = attachedImage;
    if (image != null) {
      imageBase64 = base64Encode(await image.readAsBytes());
      imageMimeType = _guessMimeType(image.path);
    }
    chatCubit.sendMessage(
      messageController.text,
      imageBase64: imageBase64,
      imageMimeType: imageMimeType,
    );
    messageController.clear();
    setState(() => attachedImage = null);
  }

  Widget _buildAttachmentPreview(
    BuildContext context,
    XFile file,
    VoidCallback onRemove,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(file.path),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatCubit = context.read<ChatCubit>();
    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          current.errorMessage != previous.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        drawer: const ChatHistoryDrawer(),
        appBar: _buildAppBar(context, chatCubit),
        body: SafeArea(
          child: Column(
            children: [
              BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  final messages = state.messages;
                  return Expanded(
                    child: messages.isEmpty
                        ? _buildEmptyState(context)
                        : _buildMessageList(context, messages, state.isLoading),
                  );
                },
              ),

              BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  final suggestions = state.suggestions;
                  final messages = state.messages;
                  return messages.isEmpty
                      ? _buildSuggestions(suggestions, handleSuggestionTap)
                      : const SizedBox();
                },
              ),

              if (attachedImage != null)
                _buildAttachmentPreview(
                  context,
                  attachedImage!,
                  () => setState(() => attachedImage = null),
                ),
              const SizedBox(height: 12),
              InputField(
                messageController: messageController,
                hasText: hasText() || attachedImage != null,
                onSend: () => _sendMessage(chatCubit),
                onPressed: () => openBottomSheet(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildEmptyState(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.primaryContainer.withValues(alpha: 0),
                ],
              ),
            ),
            child: Lottie.asset('assets/animations/logo.json'),
          ),
          const SizedBox(height: 24),
          Text(
            'How can I assist you today?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Try asking me anything or use one of the suggestions below!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}

PreferredSizeWidget _buildAppBar(BuildContext context, ChatCubit chatCubit) {
  final colorScheme = Theme.of(context).colorScheme;
  return AppBar(
    leading: Builder(
      builder: (context) {
        return _RoundedIconButton(
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
    title: const Text('Nova AI'),
    actions: [
      BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final isDark =
              themeMode == ThemeMode.dark ||
              (themeMode == ThemeMode.system &&
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark);
          return _RoundedIconButton(
            onTap: context.read<ThemeCubit>().toggle,
            child: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: colorScheme.onSurface,
              size: 22,
            ),
          );
        },
      ),
      _RoundedIconButton(
        onTap: chatCubit.clearChat,
        child: SvgPicture.asset(
          'assets/icons/new_chat_ic.svg',
          colorFilter: ColorFilter.mode(colorScheme.onSurface, BlendMode.srcIn),
        ),
      ),
      const SizedBox(width: 8),
    ],
  );
}

class _RoundedIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _RoundedIconButton({this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(10), child: child),
        ),
      ),
    );
  }
}

Widget _buildSuggestions(
  List<Suggestion> suggestions,

  void Function(Suggestion) onSuggestionTap,
) {
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

Widget _buildMessageList(
  BuildContext context,
  List<Message> messages,
  bool isLoading,
) {
  final itemCount = messages.length + (isLoading ? 1 : 0);
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    itemCount: itemCount,
    itemBuilder: (context, index) {
      if (index == messages.length) {
        return const AiTypingBuble();
      }
      final message = messages[index];
      final isUserMessage = message.role == MessageType.user;

      return Align(
        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: isUserMessage
            ? UserMessageBubble(message: message)
            : AiMessageBubble(text: message.content),
      );
    },
  );
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
          _RoundedIconButton(child: Icon(icon)),
          Text(text),
        ],
      ),
    );
  }
}
