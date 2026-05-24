import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/user_provider.dart';
import 'providers/areas_provider.dart';
import 'providers/activities_provider.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.instance.init();

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
