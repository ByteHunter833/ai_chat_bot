import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nova_ai/features/chat/data/repository/chat_remote_data_source_impl.dart';
import 'package:nova_ai/features/chat/data/repository/chat_repository_impl.dart';
import 'package:nova_ai/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:nova_ai/features/chat/presentation/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChatCubit(ChatRepositoryImpl(ChatRemoteDataSourceImpl())),
      child: const MaterialApp(
        home: HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
