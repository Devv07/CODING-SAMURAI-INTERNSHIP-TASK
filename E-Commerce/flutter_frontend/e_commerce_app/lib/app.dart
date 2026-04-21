import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maison',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isLoggedIn ? const HomeScreen() : const AuthScreen();
        },
      ),
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
