import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';

class LifeBalanceApp extends StatelessWidget {
  const LifeBalanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Balance Tracker',
      theme: AppTheme.dark(),
      debugShowCheckedModeBanner: false,
      home: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (!userProvider.isInitialized) return const SplashScreen();
          if (!userProvider.onboardingComplete) return const OnboardingScreen();
          return const MainScreen();
        },
      ),
    );
  }
}
