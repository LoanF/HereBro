import 'package:go_router/go_router.dart';

import '../../presentation/views/contact_page.dart';
import '../../presentation/views/home_page.dart';
import '../../presentation/views/login_page.dart';
import '../../presentation/views/register_page.dart';
import '../../presentation/views/settings_page.dart';
import '../di.dart';
import '../notifiers/auth_notifier.dart';
import '../services/auth_service.dart';
import 'app_routes.dart';

final authNotifier = AuthNotifier(getIt<IAuthService>());

final List<String> unauthenticatedRoutes = [
  AppRoutes.login,
  AppRoutes.register,
];

final GoRouter appRouter = GoRouter(
  refreshListenable: authNotifier,
  initialLocation: AppRoutes.login,
  redirect: (context, state) async {
    final loggedIn = authNotifier.isAuthenticated;
    final loggingIn = state.matchedLocation == AppRoutes.login;

    // Pas connecté et pas sur la page de login
    if (!loggedIn) {
      if (!unauthenticatedRoutes.contains(state.matchedLocation)) {
        return AppRoutes.login;
      }
      return null;
    }

    // Connecté et sur la page de login
    if (loggingIn) {
      return AppRoutes.home;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.contact,
      name: 'contact',
      builder: (context, state) => const ContactPage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
