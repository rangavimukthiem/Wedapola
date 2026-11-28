import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/app_mode_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/customer_home_screen.dart';
import '../../features/jobs/presentation/active_job_screen.dart';
import '../../features/jobs/presentation/post_job_screen.dart';
import '../../features/worker/presentation/worker_home_screen.dart';
import '../../features/worker/presentation/worker_kyc_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final mode = ref.watch(appModeProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final canAccessHome = authState is AuthAuthenticated || authState is AuthGuest;

      if (!canAccessHome && !isLoggingIn) return '/login';
      if (canAccessHome && isLoggingIn) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) =>
            mode.role == AppRole.worker ? const WorkerHomeScreen() : const CustomerHomeScreen(),
      ),
      GoRoute(
        path: '/post-job',
        builder: (context, state) => const PostJobScreen(),
      ),
      GoRoute(
        path: '/active-job',
        builder: (context, state) => const ActiveJobScreen(),
      ),
      GoRoute(
        path: '/worker-kyc',
        builder: (context, state) => const WorkerKycScreen(),
      ),
    ],
  );
});
