import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final TextEditingController messageController;
  final bool hasText;
  final VoidCallback? onSend;
  const InputField({
    super.key,
    required this.messageController,
    required this.hasText,
    this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton.filled(
            icon: const Icon(Icons.add),
            onPressed: () {},
            color: Colors.grey,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                Colors.grey[300]!,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xffF5F5F5),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xffE0E0E0)),
              ),
              child: TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          IconButton.filled(
            onPressed: hasText ? onSend : null,
            icon: const Icon(Icons.arrow_upward),
            disabledColor: Colors.grey[100],
            style: hasText
                ? ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.black,
                    ),
                  )
                : ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.grey,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
