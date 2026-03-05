import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool canSend;
  final VoidCallback onMicTap;
  final VoidCallback onSpeakerTap;
  final bool isListening;
  final bool isSpeechEnabled;
  final bool isVoiceModeEnabled;
  final String hintText;

  final VoidCallback onAttachTap;
  final String? attachedFilePath;
  final VoidCallback? onRemoveAttachment;

  const InputField({
    super.key,
    required this.controller,
    required this.onSend,
    required this.canSend,
    required this.onMicTap,
    required this.onSpeakerTap,
    required this.isListening,
    required this.isSpeechEnabled,
    required this.isVoiceModeEnabled,
    required this.hintText,
    required this.onAttachTap,
    this.attachedFilePath,
    this.onRemoveAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final fileExists =
        attachedFilePath != null && File(attachedFilePath!).existsSync();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffF5F5F5),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// attachment preview
          if (fileExists) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffE0E0E0)),
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    /// image preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(attachedFilePath!),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),

                    /// remove button
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: onRemoveAttachment,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          /// text input
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) {
              if (canSend) onSend();
            },
            decoration: InputDecoration(
              hintText: hintText,

              /// attach button
              prefixIcon: IconButton(
                onPressed: onAttachTap,
                icon: const Icon(CupertinoIcons.paperclip),
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),

              /// send / mic / speaker
              suffixIcon: canSend
                  ? IconButton(
                      icon: const Icon(
                        CupertinoIcons.paperplane_fill,
                        color: Color(0xff2196F3),
                      ),
                      onPressed: onSend,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// mic
                        IconButton(
                          onPressed: isSpeechEnabled ? onMicTap : null,
                          icon: Icon(
                            isListening
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            color: isListening ? Colors.red : null,
                          ),
                        ),

                        /// speaker
                        IconButton(
                          onPressed: onSpeakerTap,
                          icon: Icon(
                            isVoiceModeEnabled
                                ? Icons.record_voice_over_rounded
                                : Icons.volume_up_rounded,
                            color: isVoiceModeEnabled
                                ? const Color(0xff2196F3)
                                : null,
                          ),
                        ),
                      ],
                    ),

              suffixIconConstraints: const BoxConstraints(minWidth: 88),
            ),
          ),
        ],
      ),
    );
  }
}
