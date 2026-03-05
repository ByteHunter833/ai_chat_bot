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
  final String? attachedFileName;
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
    this.attachedFileName,
    this.onRemoveAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),

      decoration: BoxDecoration(
        color: const Color(0xffF5F5F5),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (attachedFileName != null) ...[
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffE0E0E0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.doc,
                    size: 18,
                    color: Color(0xff616161),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attachedFileName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: onRemoveAttachment,
                    icon: const Icon(Icons.close, size: 18),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
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
              prefixIcon: IconButton(
                onPressed: onAttachTap,
                icon: const Icon(CupertinoIcons.paperclip),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              suffixIcon: canSend
                  ? IconButton(
                      icon: Icon(
                        CupertinoIcons.paperplane_fill,
                        color: const Color(0xff2196F3),
                      ),
                      onPressed: onSend,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: isSpeechEnabled ? onMicTap : null,
                          icon: Icon(
                            isListening
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            color: isListening ? Colors.red : null,
                          ),
                        ),
                        const SizedBox(width: 8),
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
