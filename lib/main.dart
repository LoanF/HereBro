import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/di.dart';
import 'core/routes/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/themes/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/view_models/auth_view_model.dart';
import 'presentation/view_models/contact_view_model.dart';
import 'presentation/view_models/home_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  configureDependencies();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<ContactViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<HomeViewModel>()),
      ],
      child: const HereBro(),
    ),
  );
}

class HereBro extends StatelessWidget {
  const HereBro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HereBro',
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
