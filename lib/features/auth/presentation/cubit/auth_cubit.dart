import 'package:bloc/bloc.dart';
import 'package:nova_ai/features/auth/domain/entities/app_user.dart';
import 'package:nova_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:nova_ai/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit(this.authRepository) : super(const AuthState()) {
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final user = await authRepository.getCurrentUser();
      if (isClosed) return;
      emit(
        AuthState(
          status: user != null
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          user: user,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Failed to restore session.',
        ),
      );
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = await authRepository.signIn(
        email: email,
        password: password,
      );
      if (!isClosed) {
        emit(AuthState(status: AuthStatus.authenticated, user: user));
      }
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = await authRepository.signUp(
        name: name,
        email: email,
        password: password,
      );
      if (!isClosed) {
        emit(AuthState(status: AuthStatus.authenticated, user: user));
      }
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
      return false;
    }
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    if (!isClosed) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<AppUser?> grantPro() async {
    try {
      final user = await authRepository.grantPro();
      if (!isClosed) {
        emit(AuthState(status: AuthStatus.authenticated, user: user));
      }
      return user;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(errorMessage: e.toString()));
      }
      return null;
    }
  }
}