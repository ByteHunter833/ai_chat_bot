import 'package:nova_ai/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<AppUser> grantPro();
}