import 'package:flutter/material.dart';

class ChatHistoryDrawer extends StatefulWidget {
  const ChatHistoryDrawer({super.key});

  @override
  State<ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends State<ChatHistoryDrawer> {
  final List<String> chatHistory = [
    'Chat 1',
    'Chat 2',
    'Chat 3',
    'Chat 4',
    'Chat 5',
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nova AI',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Recent Chats'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: chatHistory.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(chatHistory[index]),
                    onTap: () {
                      // Handle chat selection
                      Navigator.pop(context); // Close the drawer
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
