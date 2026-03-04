import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kuryl_kz/features/auth/models/auth_role.dart';
import 'package:kuryl_kz/features/auth/services/phone_auth_service.dart';
import 'package:kuryl_kz/features/auth/ui/auth_theme.dart';
import 'package:kuryl_kz/features/auth/ui/auth_widgets.dart';

class OtpVerifyScreen extends StatefulWidget {
  final AuthRole selectedRole;
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const OtpVerifyScreen({
    super.key,
    required this.selectedRole,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _authService = PhoneAuthService();
  final _codeController = TextEditingController();

  Timer? _timer;
  String? _error;
  bool _isVerifying = false;
  bool _isResending = false;
  int _secondsLeft = 60;
  late String _verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = '6 таңбалы кодты енгізіңіз');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final error = await _authService.verifyCode(
      verificationId: _verificationId,
      smsCode: code,
    );

    if (!mounted) return;

    setState(() => _isVerifying = false);

    if (error == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() => _error = error);
  }

  Future<void> _resendCode() async {
    if (_secondsLeft > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _error = null;
    });

    final result = await _authService.requestCode(
      phoneNumber: widget.phoneNumber,
      forceResendingToken: _resendToken,
    );

    if (!mounted) return;

    setState(() => _isResending = false);

    if (result.autoVerified) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (result.codeSent && result.verificationId != null) {
      setState(() {
        _verificationId = result.verificationId!;
        _resendToken = result.resendToken;
      });
      _startTimer();
      return;
    }

    setState(() {
      _error = result.errorMessage ?? 'Кодты қайта жіберу сәтсіз аяқталды';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authTheme = authThemeForRole(widget.selectedRole);
    final isWorker = widget.selectedRole == AuthRole.worker;

    return AuthScaffold(
      theme: authTheme,
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthHeader(
            theme: authTheme,
            icon: isWorker ? Icons.construction_outlined : Icons.task_alt,
            title: 'OTP кодын растау',
            subtitle:
                '${widget.phoneNumber} нөміріне келген 6 таңбалы кодты енгізіңіз.',
          ),
          const SizedBox(height: 24),
          AuthCard(
            theme: authTheme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthTextField(
                  theme: authTheme,
                  controller: _codeController,
                  label: 'Код *',
                  hint: '000000',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (_) {
                    if (_error != null) {
                      setState(() => _error = null);
                    }
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(color: authTheme.error, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: (_secondsLeft == 0 && !_isResending)
                            ? _resendCode
                            : null,
                        child: Text(
                          _secondsLeft == 0
                              ? 'Қайта жіберу'
                              : 'Қайта жіберу ($_secondsLeft сек)',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Нөмірді өзгерту'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            theme: authTheme,
            label: 'Растау',
            onPressed: _isVerifying ? null : _verifyCode,
            isLoading: _isVerifying,
          ),
        ],
      ),
    );
  }
}
