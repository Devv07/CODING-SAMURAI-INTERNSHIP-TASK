import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../home/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _animController.reverse().then((_) {
      setState(() {
        _isLogin = !_isLogin;
        _formKey.currentState?.reset();
        context.read<AuthProvider>().clearError();
      });
      _animController.forward();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (_isLogin) {
      await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    } else {
      await auth.signUp(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
    }
    if (!mounted) return;
    if (auth.isLoggedIn) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 36),
                    _buildToggle(),
                    const SizedBox(height: 28),
                    _buildForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        const Text(
          'MAISON',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w300,
            fontSize: 28,
            letterSpacing: 8,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'CURATED FASHION',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 4,
            color: AppColors.muted,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _toggleBtn('Sign In', _isLogin),
          _toggleBtn('Create Account', !_isLogin),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: active ? null : _toggleMode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w500 : FontWeight.w400,
              color: active ? AppColors.primary : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_isLogin) ...[
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Full Name'),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email Address'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your email';
                  if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(v)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v != null && v.length < 6
                    ? 'At least 6 characters required'
                    : null,
              ),
              if (auth.status == AuthStatus.error) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.errorMessage,
                          style: const TextStyle(fontSize: 13, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(_isLogin ? 'Sign In' : 'Create Account'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Demo: any valid email + 6+ char password',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
