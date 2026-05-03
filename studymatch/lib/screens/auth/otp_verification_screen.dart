import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String name;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const _baseUrl = 'http://localhost/StudyMatch/studymatch-api';
  static const _otpLength = 6;
  static const _resendCooldown = 60;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  bool _verifying = false;
  bool _sending = false;
  bool _otpSent = false;
  String? _errorMsg;

  int _secondsLeft = 0;
  Timer? _timer;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    _sendOtp();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _timer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _otpValue => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otpValue.length == _otpLength;

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _shake() => _shakeCtrl.forward(from: 0);

  void _clearOtp() {
    for (final c in _controllers) c.clear();
    _focusNodes.first.requestFocus();
  }

  Future<void> _sendOtp() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _errorMsg = null;
    });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/send_otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'name': widget.name}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        setState(() => _otpSent = true);
        _startCountdown();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Code sent to ${widget.email}'),
              backgroundColor: const Color(0xFF6C63FF),
            ),
          );
        }
      } else {
        setState(() => _errorMsg = data['message'] as String?);
      }
    } catch (e) {
      setState(() => _errorMsg = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_isComplete || _verifying) return;
    setState(() {
      _verifying = true;
      _errorMsg = null;
    });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/verify_otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'otp': _otpValue}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified! Please sign in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      } else {
        setState(() => _errorMsg = data['message'] as String?);
        _shake();
        _clearOtp();
      }
    } catch (e) {
      setState(() => _errorMsg = 'Network error: $e');
      _shake();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < _otpLength && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final nextEmpty =
          digits.length < _otpLength ? digits.length : _otpLength - 1;
      _focusNodes[nextEmpty].requestFocus();
    } else if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    if (_isComplete) _verifyOtp();
    setState(() {});
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.accent]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: const Icon(Icons.mark_email_read_rounded,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Verify Your Email',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _otpSent
                              ? "We've sent a 6-digit code to"
                              : "Sending code to",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // OTP Boxes
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (context, child) {
                      final dx = _shakeCtrl.isAnimating
                          ? _shakeAnim.value *
                              ((_shakeCtrl.value * 10).floor().isEven ? 1 : -1)
                          : 0.0;
                      return Transform.translate(
                          offset: Offset(dx, 0), child: child);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_otpLength, (i) {
                        final filled = _controllers[i].text.isNotEmpty;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (e) => _onKeyEvent(i, e),
                            child: SizedBox(
                              width: 46,
                              height: 56,
                              child: TextField(
                                controller: _controllers[i],
                                focusNode: _focusNodes[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 6,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: filled
                                      ? AppTheme.primary.withOpacity(0.15)
                                      : const Color(0xFF1a1535),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: filled
                                          ? AppTheme.primary
                                          : const Color(0xFF2e2850),
                                      width: filled ? 2 : 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryLight,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: (v) => _onDigitChanged(i, v),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Error message
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.error.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppTheme.error, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _errorMsg!,
                                style: const TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 36),

                  // ✅ FIXED: onPressed now uses _isComplete ? _verifyOtp : () {}
                  // instead of nullable callback which caused the type error
                  GradientButton(
                    text: 'Verify Email',
                    onPressed: _isComplete ? _verifyOtp : () {},
                    isLoading: _verifying,
                  ),

                  const SizedBox(height: 24),

                  // Resend
                  Center(
                    child: _secondsLeft > 0
                        ? Text(
                            'Resend code in ${_secondsLeft}s',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                          )
                        : TextButton(
                            onPressed: _sending ? null : _sendOtp,
                            child: _sending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryLight),
                                  )
                                : const Text.rich(TextSpan(
                                    text: "Didn't receive a code? ",
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontFamily: 'Poppins',
                                        fontSize: 13),
                                    children: [
                                      TextSpan(
                                        text: 'Resend',
                                        style: TextStyle(
                                          color: AppTheme.primaryLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )),
                          ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}