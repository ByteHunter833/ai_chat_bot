import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';

class UserMessageBubble extends StatelessWidget {
  final Message message;

  const UserMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = _buildImage();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      padding: const EdgeInsets.all(8),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (image != null)
            ClipRRect(borderRadius: BorderRadius.circular(14), child: image),
          if (message.content.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: image != null ? 8 : 0,
                left: 8,
                right: 8,
                bottom: 4,
              ),
              child: Text(
                message.content,
                style: TextStyle(fontSize: 16.0, color: colorScheme.onPrimary),
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildImage() {
    final imageBase64 = message.imageBase64;
    if (imageBase64 != null) {
      return Image.memory(base64Decode(imageBase64), fit: BoxFit.cover);
    }

    final filePath = message.filePath;
    if (message.isImage && filePath != null) {
      return Image.file(File(filePath), fit: BoxFit.cover);
    }

    return null;
  }
}
