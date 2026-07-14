import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Drawer(),
      appBar: _buildAppBar(context),
      body: Column(children: [_buildEmptyState(context)]),
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

Widget _buildSuggestions() {
  return Container();
}
