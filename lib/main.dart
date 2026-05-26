import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/areas_provider.dart';
import 'providers/activities_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa StorageService local (SharedPreferences)
  await StorageService.instance.init();

  // Inicializa Firebase (Auth + Firestore)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Ativa persistência offline do Firestore (cache local automático)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Firebase não configurado — modo demo ativo: $e');
  }

  // SettingsProvider: tema e idioma (inicializado antes do UserProvider)
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  // UserProvider inicializado antes do runApp (routing depende de isInitialized)
  final userProvider = UserProvider();
  await userProvider.init();

  runApp(
    MultiProvider(
      providers: [
        // SettingsProvider: tema e idioma
        ChangeNotifierProvider.value(value: settingsProvider),

        // UserProvider: fonte de verdade de autenticação
        ChangeNotifierProvider.value(value: userProvider),

        // AreasProvider: sincroniza com Firestore quando autenticado
        ChangeNotifierProxyProvider<UserProvider, AreasProvider>(
          create: (_) => AreasProvider()..initLocal(),
          update: (_, up, ap) {
            ap!.syncUser(up.user?.id, up.isCloudUser);
            return ap;
          },
        ),

        // ActivitiesProvider: sincroniza com Firestore quando autenticado
        ChangeNotifierProxyProvider<UserProvider, ActivitiesProvider>(
          create: (_) => ActivitiesProvider()..initLocal(),
          update: (_, up, act) {
            act!.syncUser(up.user?.id, up.isCloudUser);
            return act;
          },
        ),

        // CalendarProvider: Google Calendar integration
        // Declarado ANTES de TasksProvider para ser usado pelo ProxyProvider2
        ChangeNotifierProxyProvider<UserProvider, CalendarProvider>(
          create: (_) => CalendarProvider(),
          update: (_, up, cp) {
            cp!.syncUser(up.authProvider);
            return cp;
          },
        ),

        // TasksProvider: tarefas MIT + Matriz de Eisenhower + eventos de calendário
        ChangeNotifierProxyProvider2<UserProvider, CalendarProvider,
            TasksProvider>(
          create: (_) => TasksProvider()..initLocal(),
          update: (_, up, cp, tp) {
            tp!.syncUser(up.user?.id, up.isCloudUser);
            // Sincroniza eventos do calendário se o usuário tiver acesso
            if (cp.isAuthorized && up.user != null) {
              tp.syncCalendarTasks(cp.upcomingEvents, up.user!.id);
            } else if (!cp.isAuthorized) {
              // Limpa tarefas de calendário quando perde acesso
              tp.syncCalendarTasks([], up.user?.id ?? '');
            }
            return tp;
          },
        ),
      ],
      child: const LifeBalanceApp(),
    ),
  );
}
