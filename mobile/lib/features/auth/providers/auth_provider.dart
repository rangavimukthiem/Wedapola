import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {}
class AuthGuest extends AuthState {}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkInitialState();
    return AuthInitial();
  }

  Future<void> _checkInitialState() async {
    final repository = ref.read(authRepositoryProvider);
    try {
      final isLoggedIn = await repository.isLoggedIn();
      if (isLoggedIn) {
        state = AuthAuthenticated();
      } else {
        state = AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthUnauthenticated();
    }
  }

  Future<void> loginWithGoogle() async {
    final repository = ref.read(authRepositoryProvider);
    state = AuthLoading();
    try {
      await repository.signInWithGoogle();
      state = AuthAuthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  void continueAsGuest() {
    state = AuthGuest();
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    state = AuthLoading();
    try {
      await repository.signOut();
      state = AuthUnauthenticated();
    } catch (e) {
      state = AuthUnauthenticated();
    }
  }
}
