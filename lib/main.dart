import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nova_ai/core/theme/app_theme.dart';
import 'package:nova_ai/core/theme/data/theme_local_data_source.dart';
import 'package:nova_ai/core/theme/data/theme_repository_impl.dart';
import 'package:nova_ai/core/theme/presentation/cubit/theme_cubit.dart';
import 'package:nova_ai/core/theme/presentation/cubit/theme_state.dart';
import 'package:nova_ai/features/chat/data/repository/chat_remote_data_source_impl.dart';
import 'package:nova_ai/features/chat/data/repository/chat_repository_impl.dart';
import 'package:nova_ai/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:nova_ai/features/chat/presentation/screens/home_screen.dart';
import 'package:nova_ai/service/data_base_service.dart';

const openRouterApiKey = String.fromEnvironment(
  'OPENROUTER_API_KEY',
  defaultValue: '',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  if (openRouterApiKey.isEmpty) {
    debugPrint(
      'Warning: OPENROUTER_API_KEY is not set. Run with '
      '--dart-define=OPENROUTER_API_KEY=<your key> or requests will fail.',
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ChatCubit(
            ChatRepositoryImpl(
              ChatRemoteDataSourceImpl(apiKey: openRouterApiKey),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => ThemeCubit(
            ThemeRepositoryImpl(ThemeLocalDataSource()),
          ),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeState.themeMode,
          );
        },
      ),
    );
  }
}
