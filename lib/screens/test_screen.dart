import 'package:ai_chat_bot/widgets/ai_typing_buble.dart';
import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: AiTypingBuble()));
  }
}
