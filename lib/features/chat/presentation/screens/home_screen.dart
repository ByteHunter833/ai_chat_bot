import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart';
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
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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

String _mimeTypeForFile(XFile file) {
  final mimeType = file.mimeType;
  if (mimeType != null && mimeType.isNotEmpty) return mimeType;
  return _guessMimeType(file.path);
}

String _extensionForMimeType(String mimeType) {
  switch (mimeType) {
    case 'image/png':
      return '.png';
    case 'image/webp':
      return '.webp';
    case 'image/gif':
      return '.gif';
    case 'image/jpeg':
      return '.jpg';
    default:
      return '.bin';
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
  final ScrollController _scrollController = ScrollController();
  bool _shouldAutoScroll = true;

  void handleSuggestionTap(Suggestion suggestion) {
    messageController.text = suggestion.text + ' ' + suggestion.description;
  }

  bool get hasText => messageController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatCubit>().loadChats();
    });
    messageController.addListener(() {
      setState(() {});
    });
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAndAttach(
    BuildContext sheetContext,
    Future<XFile?> Function() pick,
  ) async {
    Navigator.pop(sheetContext);
    final file = await pick();
    if (file == null) return;
    if (!_mimeTypeForFile(file).startsWith('image/')) {
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
    if (!hasText && attachedImage == null) return;
    _shouldAutoScroll = true;
    String? imageBase64;
    String? imageMimeType;
    String? imageFilePath;
    final image = attachedImage;
    if (image != null) {
      late final List<int> imageBytes;
      try {
        imageBytes = await image.readAsBytes();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read attachment: $e')),
        );
        return;
      }

      imageMimeType = _mimeTypeForFile(image);
      imageBase64 = base64Encode(imageBytes);
      imageFilePath = await _saveAttachmentCopy(
        image,
        imageBytes,
        imageMimeType,
      );
    }
    chatCubit.sendMessage(
      messageController.text,
      imageBase64: imageBase64,
      imageMimeType: imageMimeType,
      imageFilePath: imageFilePath,
    );

    messageController.clear();
    setState(() => attachedImage = null);
  }

  Future<String> _saveAttachmentCopy(
    XFile file,
    List<int> bytes,
    String mimeType,
  ) async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final attachmentsDirectory = Directory(
        path.join(documentsDirectory.path, 'attachments'),
      );
      await attachmentsDirectory.create(recursive: true);

      final originalExtension = path.extension(file.path);
      final extension = originalExtension.isNotEmpty
          ? originalExtension
          : _extensionForMimeType(mimeType);
      final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension'
          .toLowerCase();
      final savedFile = File(path.join(attachmentsDirectory.path, fileName));

      await savedFile.writeAsBytes(bytes, flush: true);
      return savedFile.path;
    } catch (e) {
      debugPrint('Failed to persist attachment copy: $e');
      return file.path;
    }
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

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    _shouldAutoScroll = distanceToBottom <= 96;
  }

  void _queueScrollToBottom({bool animated = true}) {
    if (!_shouldAutoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_shouldAutoScroll || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final offset = position.maxScrollExtent;

      if (animated) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(offset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatCubit = context.read<ChatCubit>();
    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          current.messages != previous.messages ||
          current.isLoading != previous.isLoading ||
          current.isStreaming != previous.isStreaming ||
          current.errorMessage != previous.errorMessage,
      listener: (context, state) {
        final errorMessage = state.errorMessage;
        if (errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }

        if (state.messages.isNotEmpty || state.isLoading) {
          _queueScrollToBottom(animated: !state.isStreaming);
        }
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
                        : _buildMessageList(
                            context,
                            messages,
                            state.isLoading,
                            state.isStreaming,
                            _scrollController,
                          ),
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
                hasText: hasText || attachedImage != null,
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
    title: Anchor(
      placement: Placement.bottom,
      overlayBuilder: (context) => _buildModelMenu(context),
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
        onTap: chatCubit.startNewChat,
        child: SvgPicture.asset(
          'assets/icons/new_chat_ic.svg',
          colorFilter: ColorFilter.mode(colorScheme.onSurface, BlendMode.srcIn),
        ),
      ),
      const SizedBox(width: 8),
    ],
  );
}

Widget _buildModelMenu(BuildContext context) {
  final colors = Theme.of(context).colorScheme;

  return Material(
    elevation: 8,
    borderRadius: BorderRadius.circular(18),
    color: colors.surfaceContainer,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 260),
      child: ListView(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        children: const [
          _ModelTile(
            title: 'Nova AI',
            subtitle: 'Default model',
            selected: true,
          ),
          SizedBox(height: 4),
          _ModelTile(
            title: 'Gemini 2.5 Flash',
            subtitle: 'Fast and lightweight',
          ),
          SizedBox(height: 4),
          _ModelTile(title: 'Gemini 2.5 Pro', subtitle: 'Best reasoning'),
        ],
      ),
    ),
  );
}

class _ModelTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;

  const _ModelTile({
    required this.title,
    required this.subtitle,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_rounded, color: colors.primary),
          ],
        ),
      ),
    );
  }
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
  bool isStreaming,
  ScrollController _scrollController,
) {
  final itemCount = messages.length + (isLoading ? 1 : 0);
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    itemCount: itemCount,
    controller: _scrollController,
    itemBuilder: (context, index) {
      if (index == messages.length) {
        return const AiTypingBuble();
      }
      final message = messages[index];
      final isUserMessage = message.role == MessageType.user;
      final isStreamingMessage =
          isStreaming && index == messages.length - 1 && !isUserMessage;

      return Align(
        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: isUserMessage
            ? UserMessageBubble(message: message)
            : AiMessageBubble(
                text: message.content,
                showActions: !isStreamingMessage,
              ),
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
