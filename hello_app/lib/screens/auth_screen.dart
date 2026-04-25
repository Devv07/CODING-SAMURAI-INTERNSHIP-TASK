import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  late TabController _tab;

  // Login controllers
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _loginKey = GlobalKey<FormState>();

  // Register controllers
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  final _regConfirm = TextEditingController();
  final _regKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _loginPassVisible = false;
  bool _regPassVisible = false;
  bool _regConfirmVisible = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPass.dispose();
    _regConfirm.dispose();
    super.dispose();
  }

  //Action Methods

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;
    _setLoading(true);
    try {
      await _auth.signInWithEmail(
        email: _loginEmail.text,
        password: _loginPass.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _register() async {
    if (!_regKey.currentState!.validate()) return;
    _setLoading(true);
    try {
      await _auth.registerWithEmail(
        name: _regName.text,
        email: _regEmail.text,
        password: _regPass.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    if (mounted) setState(() => _loading = v);
  }

  // Build Method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Decorative glows
          _glow(top: -100, left: -100, size: 320,
              color: AppColors.primary.withOpacity(0.14)),
          _glow(top: -60, right: -110, size: 280,
              color: const Color(0xFF0072FF).withOpacity(0.10)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                children: [
                  const SizedBox(height: 36),
                  _buildHeader(),
                  const SizedBox(height: 36),
                  _buildTabBar(),
                  const SizedBox(height: 28),
                  if (_error != null) _buildError(),
                  SizedBox(
                    height: _tab.index == 0 ? 360 : 500,
                    child: TabBarView(
                      controller: _tab,
                      children: [_buildLoginForm(), _buildRegForm()],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: const Icon(Icons.chat_bubble_rounded,
              color: Colors.white, size: 34),
        ),
        const SizedBox(height: 16),
        const Text(
          'Hello Chat',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your world, your conversations',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF0072FF)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [Tab(text: 'Sign In'), Tab(text: 'Register')],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.accent,
                  fontSize: 13,
                )),
          ),
        ],
      ),
    );
  }

  // Login Form

  Widget _buildLoginForm() {
    return Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Email Address'),
          const SizedBox(height: 8),
          _field(
            ctrl: _loginEmail,
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress,
            validator: (v) =>
            v == null || v.isEmpty ? 'Email is required' : null,
          ),
          const SizedBox(height: 18),
          _label('Password'),
          const SizedBox(height: 8),
          _field(
            ctrl: _loginPass,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            visible: _loginPassVisible,
            onToggle: () =>
                setState(() => _loginPassVisible = !_loginPassVisible),
            validator: (v) =>
            v == null || v.isEmpty ? 'Password is required' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPassword,
              child: const Text('Forgot Password?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          ),
          const SizedBox(height: 8),
          _primaryBtn(label: 'Sign In', onTap: _login),
        ],
      ),
    );
  }

  //Register Form

  Widget _buildRegForm() {
    return Form(
      key: _regKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Full Name'),
          const SizedBox(height: 8),
          _field(
            ctrl: _regName,
            hint: 'John Doe',
            icon: Icons.person_outline_rounded,
            validator: (v) =>
            v == null || v.trim().isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          _label('Email Address'),
          const SizedBox(height: 8),
          _field(
            ctrl: _regEmail,
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress,
            validator: (v) =>
            v == null || v.isEmpty ? 'Email is required' : null,
          ),
          const SizedBox(height: 16),
          _label('Password'),
          const SizedBox(height: 8),
          _field(
            ctrl: _regPass,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            visible: _regPassVisible,
            onToggle: () =>
                setState(() => _regPassVisible = !_regPassVisible),
            validator: (v) => (v?.length ?? 0) < 6
                ? 'Minimum 6 characters'
                : null,
          ),
          const SizedBox(height: 16),
          _label('Confirm Password'),
          const SizedBox(height: 8),
          _field(
            ctrl: _regConfirm,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            visible: _regConfirmVisible,
            onToggle: () => setState(
                    () => _regConfirmVisible = !_regConfirmVisible),
            validator: (v) =>
            v != _regPass.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 26),
          _primaryBtn(label: 'Create Account', onTap: _register),
        ],
      ),
    );
  }

  //Reusable Widgets

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
  );

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
    bool isPassword = false,
    bool visible = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPassword && !visible,
      keyboardType: keyboard,
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            visible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.textHint,
            size: 20,
          ),
          onPressed: onToggle,
        )
            : null,
      ),
      validator: validator,
    );
  }

  Widget _primaryBtn({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF0072FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _loading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          )
              : Text(label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
        ),
      ),
    );
  }

  Widget _glow({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  //Forgot Password Sheet

  void _showForgotPassword() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 28, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reset Password',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 6),
            Text('Enter your email to receive a reset link.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                )),
            const SizedBox(height: 22),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                  fontFamily: 'Poppins', color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email_outlined,
                    color: AppColors.textHint, size: 20),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) return;
                  try {
                    await _auth.resetPassword(ctrl.text);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reset link sent! Check your inbox.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.accent),
                      );
                    }
                  }
                },
                child: const Text('Send Reset Link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}