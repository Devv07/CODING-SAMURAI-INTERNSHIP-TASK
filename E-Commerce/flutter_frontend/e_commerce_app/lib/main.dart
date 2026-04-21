import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/order_provider.dart';
import 'services/cache_service.dart';
import 'screens/splash/splash_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    _initFirebase(),
    CacheService.instance.loadProducts(),
    Future(() {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ));
    }),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _initFirebase() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maison',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: const _NoGlowScrollBehavior(),
      routes: {
        '/home':      (_) => const _HomeImport(),
        '/auth':      (_) => const _AuthImport(),
      },
      home: const SplashScreen(),
    );
  }
}

class _HomeImport extends StatelessWidget {
  const _HomeImport();
  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
class _AuthImport extends StatelessWidget {
  const _AuthImport();
  @override
  Widget build(BuildContext context) => const SplashScreen();
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) => child;
}