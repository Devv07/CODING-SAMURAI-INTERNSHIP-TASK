import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../screens/auth/auth_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    final auth     = context.read<AuthProvider>();
    final products = context.read<ProductProvider>();

    await Future.wait([
      Future.delayed(const Duration(milliseconds: 300)),
      auth.tryAutoLogin(),
      products.loadFromCache(),
    ]);

    if (!mounted) return;

    // Navigate NOW — screen renders with cached data
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) =>
        auth.isLoggedIn ? const HomeScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );

    if (auth.isLoggedIn) {
      products.fetchProducts(silent: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MAISON',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w300,
                  fontSize: 40,
                  letterSpacing: 10,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'CURATED FASHION',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 5,
                  color: Colors.white38,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//onboarding
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl  = PageController();
  int  _currentPage = 0;

  static const _pages = [
    _OnboardPage(emoji: '🧥', color: Color(0xFFD4C5B0),
        title: 'Curated Essentials',
        subtitle: 'Discover timeless pieces handpicked by our fashion editors.'),
    _OnboardPage(emoji: '🛍', color: Color(0xFFC9B8C5),
        title: 'Effortless Shopping',
        subtitle: 'Browse, save favourites, and checkout in seconds.'),
    _OnboardPage(emoji: '✦', color: Color(0xFFB8C5B0),
        title: 'Free & Fast Delivery',
        subtitle: 'Complimentary shipping on all orders over \$200.'),
  ];

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      _goToAuth();
    }
  }

  void _goToAuth() => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                          (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(_currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Continue'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _goToAuth,
                      child: const Text('Skip',
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color  color;
  const _OnboardPage({
    required this.emoji, required this.color,
    required this.title, required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
      child: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 100)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 28,
                  fontWeight: FontWeight.w400),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.muted, height: 1.6),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}