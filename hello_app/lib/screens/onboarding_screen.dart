import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _pages = [
    _OBData(
      icon: Icons.chat_bubble_outline_rounded,
      badge: Icons.bolt_rounded,
      title: 'Real-Time\nMessaging',
      body:
      'Send and receive messages instantly. No refresh, no delay — conversations flow as fast as you think.',
      gradColors: [Color(0xFF00C9A7), Color(0xFF0072FF)],
      bgColor: Color(0xFF00C9A7),
    ),
    _OBData(
      icon: Icons.emoji_emotions_outlined,
      badge: Icons.favorite_rounded,
      title: 'Express with\nEmojis',
      body:
      'Words not enough? React with a full emoji keyboard and bring your personality to every message.',
      gradColors: [Color(0xFFFF6B6B), Color(0xFFFFB347)],
      bgColor: Color(0xFFFF6B6B),
    ),
    _OBData(
      icon: Icons.shield_outlined,
      badge: Icons.lock_rounded,
      title: 'Safe &\nPrivate',
      body:
      'Your chats are protected by Firebase Authentication. Your account, your data, your control.',
      gradColors: [Color(0xFF6C63FF), Color(0xFF00C9A7)],
      bgColor: Color(0xFF6C63FF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOutCubic);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: _pages.length,
            onPageChanged: (i) {
              setState(() => _page = i);
              _animCtrl.reset();
              _animCtrl.forward();
            },
            itemBuilder: (_, i) => _buildPage(_pages[i]),
          ),
          // Skip
          Positioned(
            top: 54,
            right: 22,
            child: TextButton(
              onPressed: _finish,
              child: Text('Skip',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          ),
          // Bottom controls
          Positioned(
              bottom: 0, left: 0, right: 0, child: _buildControls()),
        ],
      ),
    );
  }

  Widget _buildPage(_OBData data) {
    return Stack(
      children: [
        Positioned(
          top: -70,
          right: -70,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.bgColor.withOpacity(0.07),
            ),
          ),
        ),
        Positioned(
          top: 60,
          right: -20,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.bgColor.withOpacity(0.04),
            ),
          ),
        ),
        FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                const SizedBox(height: 110),
                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: data.gradColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: data.gradColors[0].withOpacity(0.35),
                        blurRadius: 50,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(data.icon,
                          size: 88,
                          color: Colors.white.withOpacity(0.88)),
                      Positioned(
                        bottom: 36,
                        right: 28,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(data.badge,
                              size: 22, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 56),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                        colors: data.gradColors)
                        .createShader(rect),
                    child: Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: Text(
                    data.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.5,
                      height: 1.65,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    final isLast = _page == _pages.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 50),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bgDark.withOpacity(0),
            AppColors.bgDark,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(_pages.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                width: active ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: active
                      ? LinearGradient(
                      colors: _pages[_page].gradColors)
                      : null,
                  color: active
                      ? null
                      : Colors.white.withOpacity(0.18),
                ),
              );
            }),
          ),

          GestureDetector(
            onTap: _next,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isLast ? 170 : 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _pages[_page].gradColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _pages[_page].gradColors[0].withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: isLast
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Get Started',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        )),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                )
                    : const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OBData {
  final IconData icon;
  final IconData badge;
  final String title;
  final String body;
  final List<Color> gradColors;
  final Color bgColor;

  const _OBData({
    required this.icon,
    required this.badge,
    required this.title,
    required this.body,
    required this.gradColors,
    required this.bgColor,
  });
}