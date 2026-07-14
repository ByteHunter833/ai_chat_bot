import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:nova_ai/core/shared_widgets/chat/input_field.dart';
import 'package:nova_ai/features/chat/data/models/suggestions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Suggestions> suggestions = [
    const Suggestions(
      text: 'Design a database schema',
      description: 'for an online merch store',
    ),
    const Suggestions(
      text: 'Explain airplain',
      description: 'to someone 5 years old',
    ),

    const Suggestions(
      text: 'What is the capital of France?',
      description: 'Learn about the capital city of France.',
    ),
  ];
  final TextEditingController messageController = TextEditingController();

  void handleSuggestionTap(Suggestions suggestion) {
    messageController.text = suggestion.text;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const Drawer(),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(child: _buildEmptyState(context)),
          _buildSuggestions(suggestions, handleSuggestionTap),
          const SizedBox(height: 20),
          InputField(messageController: messageController, hasText: hasText()),
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
  List<Suggestions> suggestions,

  void Function(Suggestions) onSuggestionTap,
) {
  return SizedBox(
    height: 80,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onSuggestionTap(suggestions[index]),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xffF6F6F6),
              borderRadius: BorderRadius.circular(15),
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestions[index].text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  suggestions[index].description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
      itemCount: suggestions.length,
    ),
  );
}
