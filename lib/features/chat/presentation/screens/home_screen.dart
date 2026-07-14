import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:nova_ai/core/shared_widgets/chat/ai_message_buble.dart';
import 'package:nova_ai/core/shared_widgets/chat/chat_history_drawer.dart';
import 'package:nova_ai/core/shared_widgets/chat/input_field.dart';
import 'package:nova_ai/core/shared_widgets/chat/suggestion_card.dart';
import 'package:nova_ai/core/shared_widgets/chat/user_message_buble.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';
import 'package:nova_ai/features/chat/data/models/suggestions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Suggestion> suggestions = [
    const Suggestion(
      text: 'Design a database schema',
      description: 'for an online merch store',
    ),
    const Suggestion(
      text: 'Explain airplain',
      description: 'to someone 5 years old',
    ),

    const Suggestion(
      text: 'What is the capital of France?',
      description: 'Learn about the capital city of France.',
    ),
  ];
  final List<Message> messages = [
    Message(content: 'Hi how are you', role: MessageType.user),
    Message(
      content: 'I am fine, How can I help you today?',
      role: MessageType.assistant,
    ),
  ];
  final TextEditingController messageController = TextEditingController();

  void handleSuggestionTap(Suggestion suggestion) {
    messageController.text = suggestion.text;
  }

  bool hasText() {
    return messageController.text.isNotEmpty;
  }

  void onSend() {
    if (hasText()) {
      setState(() {
        messages.add(
          Message(content: messageController.text, role: MessageType.user),
        );
      });
      messageController.clear();
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const ChatHistoryDrawer(),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(context)
                : _buildMessageList(context, messages),
          ),
          messages.isEmpty
              ? _buildSuggestions(suggestions, handleSuggestionTap)
              : const SizedBox(),
          const SizedBox(height: 20),
          InputField(
            messageController: messageController,
            hasText: hasText(),
            onSend: onSend,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

Widget _buildEmptyState(BuildContext context) {
  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/logo.json', width: 150, height: 150),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}

PreferredSizeWidget _buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.white,
    leading: Builder(
      builder: (context) {
        return InkWell(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Material(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SvgPicture.asset('assets/icons/menu_ic.svg'),
            ),
          ),
        );
      },
    ),
    title: const Text(
      'Nova AI',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: SvgPicture.asset('assets/icons/new_chat_ic.svg'),
      ),
    ],
  );
}

Widget _buildSuggestions(
  List<Suggestion> suggestions,

  void Function(Suggestion) onSuggestionTap,
) {
  return SizedBox(
    height: 80,
    child: ListView.builder(
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

Widget _buildMessageList(BuildContext context, List<Message> messages) {
  return ListView.builder(
    itemCount: messages.length,
    itemBuilder: (context, index) {
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
