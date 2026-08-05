import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nova_ai/core/shared_widgets/chat/chat_history_drawer.dart';
import 'package:nova_ai/core/shared_widgets/chat/input_field.dart';
import 'package:nova_ai/features/chat/data/models/suggestions.dart';
import 'package:nova_ai/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:nova_ai/features/chat/presentation/widgets/attechment_preview.dart';
import 'package:nova_ai/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:nova_ai/features/chat/presentation/widgets/empty_state_widget.dart';
import 'package:nova_ai/features/chat/presentation/widgets/message_list.dart';
import 'package:nova_ai/features/chat/presentation/widgets/model_item.dart';
import 'package:nova_ai/features/chat/presentation/widgets/suggestion_list.dart';
import 'package:nova_ai/service/file_picker_service.dart';
import 'package:nova_ai/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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
    messageController.text = '${suggestion.text} ${suggestion.description}';
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
    if (!mimeTypeForFile(file).startsWith('image/')) {
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

      imageMimeType = mimeTypeForFile(image);
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
          : extensionForMimeType(mimeType);
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
        appBar: ChatAppBar(chatCubit: chatCubit),
        body: SafeArea(
          child: Column(
            children: [
              BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  final messages = state.messages;
                  return Expanded(
                    child: messages.isEmpty
                        ? const EmptyStateWidget()
                        : MessageList(
                            messages: messages,
                            isLoading: state.isLoading,
                            isStreaming: state.isStreaming,
                            scrollController: _scrollController,
                          ),
                  );
                },
              ),

              BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  final suggestions = state.suggestions;
                  final messages = state.messages;
                  return messages.isEmpty
                      ? SuggestionList(
                          onSuggestionTap: handleSuggestionTap,
                          suggestions: suggestions,
                        )
                      : const SizedBox();
                },
              ),

              if (attachedImage != null)
                AttechmentPreview(
                  file: attachedImage!,
                  onRemove: () => setState(() => attachedImage = null),
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
