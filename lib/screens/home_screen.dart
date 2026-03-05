import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_chat_bot/models/chat.dart';
import 'package:ai_chat_bot/models/message.dart';
import 'package:ai_chat_bot/open_router_client.dart';
import 'package:ai_chat_bot/repository/sql_chat_repository.dart';
import 'package:ai_chat_bot/service/chat_service.dart';
import 'package:ai_chat_bot/service/file_picker_service.dart';
import 'package:ai_chat_bot/widgets/ai_typing_buble.dart';
import 'package:ai_chat_bot/widgets/chat_history_drawer.dart';
import 'package:ai_chat_bot/widgets/input_field.dart';
import 'package:ai_chat_bot/widgets/message_buble.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Duration _staleAttachmentTtl = Duration(days: 14);
  static const int _maxUnreferencedAttachments = 80;

  // ── Зависимости ────────────────────────────────────────────────────────────
  // Чтобы сменить хранилище — достаточно подменить репозиторий здесь.
  // В крупном проекте это делается через DI (get_it, riverpod, provider и т.д.)
  late final ChatService _chatService;
  var reasoningEnabled = false;
  String _selectedModelId = OpenRouterClient.defaultModelId;

  OpenRouterModel get _selectedModel {
    for (final model in OpenRouterClient.models) {
      if (model.id == _selectedModelId) return model;
    }
    return OpenRouterClient.models.first;
  }

  OpenRouterClient get _openRouter => OpenRouterClient(
    reasoningEnabled && _selectedModel.supportsReasoning,
    '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',
    model: _selectedModelId,
  );
  final _speechToText = SpeechToText();
  final _flutterTts = FlutterTts();
  final _filePickerService = FilePickerService();

  // ── Состояние UI ───────────────────────────────────────────────────────────
  String? _activeChatId;
  bool _isSending = false;
  bool _isLoading = true;
  bool _userScrolledUp = false;
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _voiceModeEnabled = false;

  final List<String> _voiceQueue = [];
  String _voicePending = '';
  bool _isProcessingVoiceQueue = false;
  XFile? _attachedFile;
  bool _attachedFileIsImage = false;
  String? _attachedMimeType;

  final Map<String, String> _reasoningByMessageId = {};

  final _scrollController = ScrollController();
  final _messageController = TextEditingController();

  // Геттер — всегда читаем актуальный чат из сервиса, не храним копию
  List<Message> get _activeMessages {
    if (_activeChatId == null) return [];
    return _chatService.findById(_activeChatId!)?.messages ?? [];
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(SQLiteChatRepository());
    _scrollController.addListener(_onScroll);
    _messageController.addListener(
      () => setState(() {}),
    ); // для обновления иконки отправки
    _loadChats();
    _initVoice();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    _speechToText.stop();
    _flutterTts.stop();
    _messageController.dispose();
    super.dispose();
  }

  // ── Инициализация данных ───────────────────────────────────────────────────

  Future<void> _loadChats() async {
    await _chatService.init();
    setState(() {
      _isLoading = false;
      // Активируем первый чат из списка (или ничего, если список пуст)
      if (_chatService.chats.isNotEmpty) {
        _activeChatId = _chatService.chats.first.id;
      }
    });
    unawaited(_cleanupStaleAttachments());
  }

  // ── Управление чатами ──────────────────────────────────────────────────────

  void _createNewChat() {
    final chat = _chatService.createChat();
    setState(() => _activeChatId = chat.id);
    Navigator.pop(context); // закрыть Drawer
  }

  void _selectChat(Chat chat) {
    setState(() {
      _activeChatId = chat.id;
      _userScrolledUp = false;
    });
    Navigator.pop(context); // закрыть Drawer
    _scrollToBottom(animated: false);
  }

  void _deleteChat(Chat chat) {
    _chatService.deleteChat(chat.id);
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Чат успешно удален')));
  }

  void _clearActiveChat() {
    if (_activeChatId == null) return;
    _chatService.clearChat(_activeChatId!);
    setState(() {});
  }

  // ── Voice mode (STT + TTS) ────────────────────────────────────────────────

  Future<void> _initVoice() async {
    final enabled = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'listening' && !_isListening) {
          setState(() => _isListening = true);
        }
        if ((status == 'notListening' || status == 'done') && _isListening) {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
    );

    await _flutterTts.awaitSpeakCompletion(true);
    _flutterTts.setStartHandler(() {
      if (!mounted) return;
      setState(() => _isSpeaking = true);
    });
    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    });
    _flutterTts.setCancelHandler(() {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    });
    _flutterTts.setErrorHandler((_) {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    });
    await _flutterTts.setSpeechRate(0.48);
    await _flutterTts.setPitch(1.0);

    if (!mounted) return;
    setState(() => _speechEnabled = enabled);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    if (!_speechEnabled) {
      _showSnackBar('Голосовой ввод недоступен на этом устройстве');
      return;
    }

    FocusScope.of(context).unfocus();
    if (_isSpeaking) await _stopSpeaking();

    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: _localeIdForSpeech(),
      partialResults: true,
      listenMode: ListenMode.dictation,
      cancelOnError: true,
    );

    if (!mounted) return;
    setState(() => _isListening = _speechToText.isListening);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final recognized = result.recognizedWords.trim();
    _messageController.value = TextEditingValue(
      text: recognized,
      selection: TextSelection.collapsed(offset: recognized.length),
    );

    if (!result.finalResult) return;

    if (recognized.isEmpty) {
      _showSnackBar('Не расслышал. Повторите, пожалуйста.');
      return;
    }

    _sendMessage();
  }

  String _localeIdForSpeech() {
    final locale = Localizations.maybeLocaleOf(context);
    if (locale == null) return 'en_US';
    return locale.toLanguageTag().replaceAll('-', '_');
  }

  Future<void> _toggleVoiceMode() async {
    final next = !_voiceModeEnabled;
    setState(() => _voiceModeEnabled = next);

    if (!next) {
      _voiceQueue.clear();
      _voicePending = '';
      _isProcessingVoiceQueue = false;
      await _stopSpeaking();
      _showSnackBar('Голосовой чат выключен');
    } else {
      _showSnackBar('Голосовой чат включен');
    }
  }

  void _handleVoiceChunk(String chunk) {
    if (!_voiceModeEnabled) return;
    _voicePending += chunk;
    _splitPendingVoiceByBoundary();
    _processVoiceQueue();
  }

  void _splitPendingVoiceByBoundary() {
    if (_voicePending.isEmpty) return;
    final matches = RegExp(r'[.!?\n]+').allMatches(_voicePending).toList();
    if (matches.isEmpty) return;

    var start = 0;
    for (final m in matches) {
      final end = m.end;
      if (end <= start) continue;
      _enqueueVoiceText(_voicePending.substring(start, end));
      start = end;
    }
    _voicePending = _voicePending.substring(start);
  }

  void _enqueueVoiceText(String text) {
    final clean = normalizeForVoice(text);
    if (clean.isEmpty) return;
    _voiceQueue.add(clean);
  }

  Future<void> _flushVoicePending() async {
    if (!_voiceModeEnabled) return;
    if (_voicePending.trim().isNotEmpty) {
      _enqueueVoiceText(_voicePending);
      _voicePending = '';
    }
    await _processVoiceQueue();
  }

  Future<void> _processVoiceQueue() async {
    if (_isProcessingVoiceQueue || !_voiceModeEnabled) return;
    _isProcessingVoiceQueue = true;
    try {
      while (_voiceQueue.isNotEmpty && _voiceModeEnabled) {
        final next = _voiceQueue.removeAt(0);
        await _speak(next);
      }
    } finally {
      _isProcessingVoiceQueue = false;
    }
  }

  Future<void> _speak(String text) async {
    final cleanText = normalizeForVoice(text);
    if (cleanText.isEmpty) return;
    final locale = Localizations.maybeLocaleOf(context);
    if (locale != null) {
      await _flutterTts.setLanguage(locale.toLanguageTag());
    }
    await _flutterTts.speak(cleanText);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    if (!mounted) return;
    setState(() => _isSpeaking = false);
  }

  String normalizeForVoice(String text) {
    var normalized = text;

    // Remove markdown links [text](url)
    normalized = normalized.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (match) => match.group(1) ?? '',
    );

    // Remove bold/italic markers (*, **, _, __)
    normalized = normalized.replaceAll(RegExp(r'[*_]{1,3}'), '');

    // Remove inline/backtick code blocks
    normalized = normalized.replaceAll(RegExp(r'`{1,3}'), '');

    // Remove headings, blockquotes, lists
    normalized = normalized.replaceAll(
      RegExp(r'^[\s>*#\-]+', multiLine: true),
      '',
    );

    // Remove emojis (basic unicode emoji range)
    normalized = normalized.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F6FF}]|'
        r'[\u{1F700}-\u{1F77F}]|'
        r'[\u{1F780}-\u{1F7FF}]|'
        r'[\u{1F800}-\u{1F8FF}]|'
        r'[\u{1F900}-\u{1F9FF}]|'
        r'[\u{2600}-\u{26FF}]|'
        r'[\u{2700}-\u{27BF}]',
        unicode: true,
      ),
      '',
    );

    // Remove stray quotes formatting artifacts
    normalized = normalized.replaceAll(RegExp(r'["“”]'), '');

    // Collapse multiple spaces
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }

  void _showSnackBar(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ── Отправка сообщения ─────────────────────────────────────────────────────

  void _sendMessage() async {
    final text = _messageController.text.trim();
    final attachedFile = _attachedFile;
    final attachedFileIsImage = _attachedFileIsImage;
    final attachedMimeType = _attachedMimeType;
    final activeChatId = _activeChatId;
    if ((text.isEmpty && attachedFile == null) ||
        _isSending ||
        activeChatId == null) {
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
    }
    if (_isSpeaking) {
      await _stopSpeaking();
    }
    _voiceQueue.clear();
    _voicePending = '';
    _isProcessingVoiceQueue = false;

    final persistedAttachment = await _persistAttachment(attachedFile);
    final history = _chatService.buildApiHistory(activeChatId);
    final userPayload = await _buildUserPayload(
      text,
      persistedAttachment,
      attachedFileIsImage,
      attachedMimeType,
    );
    final userMessageText = text;
    HapticFeedback.lightImpact();
    _messageController.clear();

    setState(() {
      _attachedFile = null;
      _attachedFileIsImage = false;
      _attachedMimeType = null;
    });
    _chatService.addUserMessage(
      activeChatId,
      userMessageText,
      filePath: persistedAttachment?.path,
      isImage: attachedFileIsImage,
    );
    final chatWithAssistant = _chatService.addAssistantMessage(
      activeChatId,
      '',
    );
    final assistantMessageId = chatWithAssistant.messages.last.id;
    await _chatService.persist();
    unawaited(_cleanupStaleAttachments());

    setState(() {
      _isSending = true;
      _userScrolledUp = false;

      _reasoningByMessageId.remove(assistantMessageId);
    });
    _scrollToBottom();

    try {
      final stream = _openRouter.streamChatCompletion([
        ...history,
        userPayload,
      ]);

      String accumulated = '';

      await for (final chunk in stream) {
        accumulated += chunk;
        _chatService.updateLastAssistantMessage(activeChatId, accumulated);
        _handleVoiceChunk(chunk);
        setState(() {});
        if (!_userScrolledUp) _scrollToBottom();
      }
      await _flushVoicePending();
    } catch (e) {
      final errorText = e.toString();
      _chatService.updateLastAssistantMessage(
        activeChatId,
        'Ошибка при ответе сервера. $errorText',
      );
      _showSnackBar(errorText);
      setState(() {});
    } finally {
      setState(() {
        _isSending = false;
      });
      if (!_userScrolledUp) _scrollToBottom();
    }
  }

  Future<XFile?> _persistAttachment(XFile? attachment) async {
    if (attachment == null) return null;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(p.join(docsDir.path, 'attachments'));
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final ext = _fileExtension(attachment.name);
      final baseName = p
          .basenameWithoutExtension(attachment.name)
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = ext.isEmpty
          ? '${DateTime.now().microsecondsSinceEpoch}_$baseName'
          : '${DateTime.now().microsecondsSinceEpoch}_$baseName.$ext';
      final targetPath = p.join(attachmentsDir.path, fileName);
      final sourceFile = File(attachment.path);

      if (await sourceFile.exists()) {
        await sourceFile.copy(targetPath);
      } else {
        final bytes = await attachment.readAsBytes();
        await File(targetPath).writeAsBytes(bytes, flush: true);
      }

      return XFile(targetPath, mimeType: attachment.mimeType, name: fileName);
    } catch (_) {
      return attachment;
    }
  }

  Future<void> _cleanupStaleAttachments() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(p.join(docsDir.path, 'attachments'));
      if (!await attachmentsDir.exists()) return;

      final referencedPaths = <String>{};
      for (final chat in _chatService.chats) {
        for (final message in chat.messages) {
          final path = message.filePath;
          if (path == null || path.isEmpty) continue;
          referencedPaths.add(p.normalize(path));
        }
      }

      final now = DateTime.now();
      final unreferencedFreshFiles = <({File file, DateTime modified})>[];

      await for (final entity in attachmentsDir.list(followLinks: false)) {
        if (entity is! File) continue;
        final normalizedPath = p.normalize(entity.path);
        if (referencedPaths.contains(normalizedPath)) continue;

        final stat = await entity.stat();
        final isExpired = now.difference(stat.modified) > _staleAttachmentTtl;
        if (isExpired) {
          await entity.delete();
          continue;
        }

        unreferencedFreshFiles.add((file: entity, modified: stat.modified));
      }

      if (unreferencedFreshFiles.length <= _maxUnreferencedAttachments) return;

      unreferencedFreshFiles.sort((a, b) => a.modified.compareTo(b.modified));

      final overflow =
          unreferencedFreshFiles.length - _maxUnreferencedAttachments;
      for (var i = 0; i < overflow; i++) {
        await unreferencedFreshFiles[i].file.delete();
      }
    } catch (_) {
      // cleanup is best-effort
    }
  }

  Future<Map<String, dynamic>> _buildUserPayload(
    String text,
    XFile? attachment,
    bool isImage,
    String? mimeType,
  ) async {
    if (attachment == null) {
      return {'role': 'user', 'content': text};
    }

    final prompt = text.isEmpty ? 'Analyze the attached file.' : text;
    if (!isImage) {
      return {
        'role': 'user',
        'content': '$prompt\n\nAttached file: ${attachment.name}',
      };
    }

    try {
      final bytes = await attachment.readAsBytes();
      final resolvedMimeType = _imageMimeType(
        fileName: attachment.name,
        rawMimeType: mimeType,
      );
      final base64Image = base64Encode(bytes);
      return {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:$resolvedMimeType;base64,$base64Image'},
          },
        ],
      };
    } catch (_) {
      return {
        'role': 'user',
        'content': '$prompt\n\nAttached image: ${attachment.name}',
      };
    }
  }

  String _imageMimeType({required String fileName, String? rawMimeType}) {
    final normalized = rawMimeType?.toLowerCase();
    if (normalized != null && normalized.startsWith('image/')) {
      return normalized;
    }
    switch (_fileExtension(fileName)) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  String _fileExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  // ── Scroll ─────────────────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom =
        _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 80;
    if (atBottom && _userScrolledUp) {
      setState(() => _userScrolledUp = false);
    } else if (!atBottom && !_userScrolledUp) {
      setState(() => _userScrolledUp = true);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(max);
      }
    });
  }

  void _openBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // маленький индикатор сверху
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                ListTile(
                  leading: const Icon(CupertinoIcons.photo),
                  title: const Text('Photos'),
                  onTap: () => _pickAttachment(
                    _filePickerService.pickImageFromGallery,
                    forceImage: true,
                  ),
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.paperclip),
                  title: const Text('Files'),
                  onTap: () => _pickAttachment(_filePickerService.pickFile),
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.camera),
                  title: const Text('Camera'),
                  onTap: () => _pickAttachment(
                    _filePickerService.pickImageFromCamera,
                    forceImage: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openModelSelectorBottomSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Select model',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final model in OpenRouterClient.models)
                ListTile(
                  leading: Icon(
                    model.id == _selectedModelId
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(model.name),
                  subtitle: Text(model.description),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      if (model.supportsVision)
                        const Icon(Icons.image_outlined, size: 18),
                      if (model.goodForRoleplay)
                        const Icon(Icons.auto_stories_outlined, size: 18),
                      if (model.supportsReasoning)
                        const Icon(Icons.psychology_outlined, size: 18),
                    ],
                  ),
                  onTap: () {
                    setState(() => _selectedModelId = model.id);
                    Navigator.pop(context);
                    _showSnackBar('Model switched to: ${model.name}');
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAttachment(
    Future<XFile?> Function() picker, {
    bool forceImage = false,
  }) async {
    final file = await picker();
    if (!mounted) return;
    Navigator.pop(context);
    if (file == null) {
      _showSnackBar('Файл не выбран');
      return;
    }
    final mime = file.mimeType?.toLowerCase();
    final isImageFromMime = mime != null && mime.startsWith('image/');
    final isImageFromExt = {
      'png',
      'jpg',
      'jpeg',
      'webp',
      'gif',
      'bmp',
      'heic',
    }.contains(_fileExtension(file.name));
    setState(() {
      _attachedFile = file;
      _attachedMimeType = mime;
      _attachedFileIsImage = forceImage || isImageFromMime || isImageFromExt;
    });
    _showSnackBar('Прикреплено: ${file.name}');
  }

  void _removeAttachment() {
    if (_attachedFile == null) return;
    setState(() {
      _attachedFile = null;
      _attachedFileIsImage = false;
      _attachedMimeType = null;
    });
  }
  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoading) return _buildLoadingState();

    final messages = _activeMessages;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,

        // ── Drawer ─────────────────────────────────────────────────
        drawer: ChatHistoryDrawer(
          chats: _chatService.chats,
          activeChatId: _activeChatId,
          onNewChat: _createNewChat,
          onChatSelected: _selectChat,
          onChatDeleted: _deleteChat,
        ),

        // ── AppBar ─────────────────────────────────────────────────
        appBar: _buildAppBar(colorScheme, messages),

        // ── FAB: прокрутка вниз ────────────────────────────────────
        floatingActionButton: _buildFABbutton(),

        // ── Body ───────────────────────────────────────────────────
        body: Column(
          children: [
            Expanded(
              child: _activeChatId == null
                  ? _buildNoActiveChat()
                  : messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessageList(messages),
            ),
            Container(
              height: 1,
              color: colorScheme.outlineVariant.withOpacity(0.4),
            ),
            _buildMessageInput(colorScheme),
          ],
        ),
      ),
    );
  }

  // ── Вспомогательные виджеты ────────────────────────────────────────────────

  Widget _buildNoActiveChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Выберите чат или создайте новый',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () {
              final chat = _chatService.createChat();
              setState(() => _activeChatId = chat.id);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Новый чат'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final suggestions = [
      ('💡', 'Explain quantum computing'),
      ('🧮', 'Help solve a math problem'),
      ('✍️', 'Write a short story'),
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/logo.json',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            Text(
              'How can I assist you today?',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions.map((s) {
                return ActionChip(
                  avatar: Text(s.$1, style: const TextStyle(fontSize: 16)),
                  label: Text(s.$2),
                  onPressed: () => _messageController.text = s.$2,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(dynamic colorScheme) {
    return SafeArea(
      top: false,
      child: Container(
        color: colorScheme.surface,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: InputField(
          controller: _messageController,
          onSend: _sendMessage,
          canSend:
              _activeChatId != null &&
              (_messageController.text.trim().isNotEmpty ||
                  _attachedFile != null) &&
              !_isSending,
          onMicTap: _toggleListening,
          onSpeakerTap: _toggleVoiceMode,
          isListening: _isListening,
          isSpeechEnabled: _speechEnabled,
          isVoiceModeEnabled: _voiceModeEnabled,
          hintText: _isListening ? 'Listening...' : 'Type here...',
          onAttachTap: _openBottomSheet,
          attachedFilePath: _attachedFile?.path,
          onRemoveAttachment: _removeAttachment,
        ),
      ),
    );
  }

  Widget _buildMessageList(dynamic messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return Padding(
            padding: EdgeInsets.only(top: 4),
            child: AiTypingBuble(),
          );
        }
        final msg = messages[index];
        if (!msg.isUser && msg.content.isEmpty && _isSending) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: MessageBubble(
            isLoading: _isSending,

            onCopyAll: () {
              Clipboard.setData(ClipboardData(text: msg.content));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Скопировано')));
            },
            onDislike: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Спасибо за отзыв!')),
              );
            },
            onLike: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Спасибо за отзыв!'))),
            message: msg,
          ),
        );
      },
    );
  }

  Widget _buildFABbutton() {
    return AnimatedSlide(
      offset: _userScrolledUp ? Offset.zero : const Offset(0, 2),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _userScrolledUp ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.small(
          heroTag: 'scroll_bottom',
          onPressed: () async {
            setState(() => _userScrolledUp = false);
            _scrollToBottom();
          },
          child: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(dynamic colorScheme, dynamic messages) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _activeChatId != null
                  ? (_chatService.findById(_activeChatId!)?.title ??
                        'AI Chat Bot')
                  : 'AI Chat Bot',
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _selectedModel.name,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Select model',
          onPressed: _openModelSelectorBottomSheet,
        ),
        if (messages.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear chat history',
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Clear chat history?'),
                content: const Text('All messages will be deleted.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      _clearActiveChat();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(width: 4),
      ],
      elevation: 0,
      scrolledUnderElevation: 1,
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/animations/trail_loading.json',
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}
