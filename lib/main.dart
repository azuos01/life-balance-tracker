import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/areas_provider.dart';
import 'providers/activities_provider.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa StorageService local
  await StorageService.instance.init();

  // Inicializa Firebase (Auth)
  // Se firebase_options.dart não estiver configurado, o app roda em modo demo
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase não configurado — modo demo ativo: $e');
  }

  final userProvider = UserProvider();
  final areasProvider = AreasProvider();
  final activitiesProvider = ActivitiesProvider();

  await Future.wait([
    userProvider.init(),
    areasProvider.init(),
    activitiesProvider.init(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: areasProvider),
        ChangeNotifierProvider.value(value: activitiesProvider),
      ],
      child: const LifeBalanceApp(),
    ),
  );
}
