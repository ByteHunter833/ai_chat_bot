import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AiTypingBuble extends StatelessWidget {
  const AiTypingBuble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 80,
        width: 80,
        child: LottieBuilder.asset('assets/animations/trail_loading.json'),
      ),
    );
  }
}
