import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AiTypingBuble extends StatelessWidget {
  const AiTypingBuble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

        child: SizedBox(
          height: 40,
          width: 40,
          child: LottieBuilder.asset('assets/animations/trail_loading.json'),
        ),
      ),
    );
  }
}
