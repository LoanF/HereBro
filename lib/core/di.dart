import 'package:get_it/get_it.dart';

import '../presentation/view_models/auth_view_model.dart';
import '../presentation/view_models/contact_view_model.dart';
import '../presentation/view_models/home_view_model.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<IAppUserService>(() => AppUserService());
  getIt.registerLazySingleton<IAuthService>(
    () => AuthService(getIt<IAppUserService>()),
  );
  getIt.registerSingleton<NotificationService>(NotificationService());
  getIt.registerSingleton<AuthViewModel>(AuthViewModel());
  getIt.registerSingleton<ContactViewModel>(ContactViewModel());
  getIt.registerSingleton<HomeViewModel>(HomeViewModel());
}
