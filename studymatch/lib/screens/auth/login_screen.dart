import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final error = await context.read<AppState>().signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.error),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _forgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _ForgotPasswordSheet(),
    );
  }

  void _signInWithGoogle() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _GoogleSignInSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF120E2A), AppTheme.bgDark],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 32),
                    // Logo
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [AppTheme.primary, AppTheme.accent]),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.school_rounded,
                                color: Colors.white, size: 34),
                          ),
                          const SizedBox(height: 16),
                          const Text('Welcome Back',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins')),
                          const SizedBox(height: 6),
                          const Text(
                              'Sign in to continue your learning journey',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                  fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    AppTextField(
                      label: 'Email',
                      hint: 'your@email.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passCtrl,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Forgot Password?',
                            style: TextStyle(
                                color: AppTheme.primaryLight,
                                fontFamily: 'Poppins')),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      text: 'Sign In',
                      onPressed: _signIn,
                      isLoading: _loading,
                    ),
                    const SizedBox(height: 24),
                    Row(children: [
                      const Expanded(child: Divider(color: AppTheme.divider)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or continue with',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 13)),
                      ),
                      const Expanded(child: Divider(color: AppTheme.divider)),
                    ]),
                    const SizedBox(height: 24),
                    _SocialButton(
                      icon: 'G',
                      label: 'Continue with Google',
                      onTap: _signInWithGoogle,
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text.rich(TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontFamily: 'Poppins'),
                          children: [
                            TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                    color: AppTheme.primaryLight,
                                    fontWeight: FontWeight.w600)),
                          ],
                        )),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Forgot Password Bottom Sheet ──────────────────────────────────────────────
class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet();
  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _emailCtrl = TextEditingController();
  bool _sending  = false;
  bool _sent     = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      final result = await context.read<AppState>().forgotPassword(email);
      if (mounted) {
        setState(() {
          _sending = false;
          if (result['success'] == true) {
            _sent = true;
          } else {
            _error = result['message'] as String? ?? 'Something went wrong.';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _sending = false; _error = 'Network error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Icon
          Center(
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  color: AppTheme.primaryLight, size: 30),
            ),
          ),
          const SizedBox(height: 16),

          const Center(
            child: Text('Forgot Password?',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins')),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
                "Enter your email and we'll send you a reset link.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontFamily: 'Poppins',
                    fontSize: 13)),
          ),
          const SizedBox(height: 24),

          if (_sent) ...[
            // Success state
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppTheme.success, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Reset link sent! Check your inbox and follow the instructions.',
                      style: const TextStyle(
                          color: AppTheme.success,
                          fontFamily: 'Poppins',
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done',
                    style: TextStyle(
                        fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ),
            ),
          ] else ...[
            // Error
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.error,
                              fontFamily: 'Poppins',
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Email field
            AppTextField(
              label: 'Email Address',
              hint: 'your@email.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 20),

            // Send button
            GradientButton(
              text: 'Send Reset Link',
              onPressed: _send,
              isLoading: _sending,
              icon: Icons.send_rounded,
            ),
            const SizedBox(height: 12),

            // Cancel
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontFamily: 'Poppins')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Google Sign-In Sheet ──────────────────────────────────────────────────────
class _GoogleSignInSheet extends StatelessWidget {
  const _GoogleSignInSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),

          // Google logo placeholder
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1),
                    blurRadius: 12, offset: const Offset(0, 4))
              ],
            ),
            child: const Center(
              child: Text('G',
                  style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 36,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Google Sign-In',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
                    SizedBox(width: 8),
                    Text('Currently Unavailable',
                        style: TextStyle(
                            color: AppTheme.warning,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Google Sign-In requires Firebase or OAuth setup which needs a published app. '
                  'Please use email and password to sign in for now.',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Alternative — use email
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 Alternative',
                    style: TextStyle(
                        color: AppTheme.primaryLight,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 6),
                const Text(
                  'You can register with your Google email address and a password of your choice.',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      height: 1.5),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Use Email Instead',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(
                    color: AppTheme.textMuted, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}

// ── Social Button ─────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24, height: 24,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Center(
                child: Text(icon,
                    style: const TextStyle(
                        color: Color(0xFF4285F4),
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}