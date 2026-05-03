import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D0B1E),
                  Color(0xFF1A0A3A),
                  Color(0xFF0D0B1E)
                ],
              ),
            ),
          ),
          // Purple glow
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // App branding
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accent],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'StudyMatch',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Hero text
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                      children: [
                        const TextSpan(text: 'Find your perfect\n'),
                        TextSpan(
                          text: 'Study Match\n',
                          style: TextStyle(
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [
                                  AppTheme.primaryLight,
                                  AppTheme.accent
                                ],
                              ).createShader(Rect.fromLTWH(0, 0, 300, 50)),
                          ),
                        ),
                        const TextSpan(text: 'today.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Connect with students who match your learning style, schedule, and goals. Stop studying alone and start achieving more together.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                      height: 1.6,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Feature highlights
                  _FeatureRow(
                      icon: Icons.psychology_rounded,
                      text: 'AI-powered study partner matching'),
                  const SizedBox(height: 12),
                  _FeatureRow(
                      icon: Icons.chat_bubble_rounded,
                      text: 'Real-time messaging & collaboration'),
                  const SizedBox(height: 12),
                  _FeatureRow(
                      icon: Icons.library_books_rounded,
                      text: 'Shared academic resources'),
                  const Spacer(),
                  GradientButton(
                    text: 'Join Now Free',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupScreen())),
                    icon: Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen())),
                      child: const Text.rich(
                        TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontFamily: 'Poppins'),
                          children: [
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryLight, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontFamily: 'Poppins'),
          ),
        ),
      ],
    );
  }
}
