import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kuryl_kz/features/auth/auth_flags.dart';
import 'package:kuryl_kz/features/auth/models/auth_role.dart';
import 'package:kuryl_kz/features/auth/screens/otp_verify_screen.dart';
import 'package:kuryl_kz/features/auth/screens/temp_email_login_screen.dart';
import 'package:kuryl_kz/features/auth/services/phone_auth_service.dart';
import 'package:kuryl_kz/features/auth/ui/auth_theme.dart';
import 'package:kuryl_kz/features/auth/ui/auth_widgets.dart';
import 'package:kuryl_kz/features/auth/widgets/phone_number_field.dart';

class LoginScreen extends StatelessWidget {
  final bool initialIsWorker;

  const LoginScreen({super.key, required this.initialIsWorker});

  @override
  Widget build(BuildContext context) {
    return PhoneLoginScreen(
      selectedRole: AuthRole.fromIsWorker(initialIsWorker),
    );
  }
}

class PhoneLoginScreen extends StatefulWidget {
  final AuthRole selectedRole;

  const PhoneLoginScreen({super.key, required this.selectedRole});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _authService = PhoneAuthService();

  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizedPhone() {
    final digits = normalizeKzLocalPhoneDigits(_phoneController.text);
    return buildKzPhone(digits);
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSending = true;
      _error = null;
    });

    final result = await _authService.requestCode(
      phoneNumber: _normalizedPhone(),
    );

    if (!mounted) return;

    setState(() => _isSending = false);

    if (result.autoVerified) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (result.codeSent && result.verificationId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(
            selectedRole: widget.selectedRole,
            phoneNumber: _normalizedPhone(),
            verificationId: result.verificationId!,
            resendToken: result.resendToken,
          ),
        ),
      );
      return;
    }

    setState(() {
      _error = result.errorMessage ?? 'Код жіберу сәтсіз аяқталды';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authTheme = authThemeForRole(widget.selectedRole);
    final isWorker = widget.selectedRole == AuthRole.worker;

    return AuthScaffold(
      theme: authTheme,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthHeader(
              theme: authTheme,
              icon: isWorker ? Icons.handyman_rounded : Icons.flash_on_rounded,
              title: 'Телефон арқылы кіру',
              subtitle: isWorker
                  ? 'Шебер аккаунтына кіру үшін SMS кодты алыңыз.'
                  : 'Тапсырыс беруші аккаунтына кіру үшін SMS кодты алыңыз.',
            ),
            const SizedBox(height: 24),
            AuthCard(
              theme: authTheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthTextField(
                    theme: authTheme,
                    controller: _phoneController,
                    label: 'Телефон нөмірі',
                    hint: '7000000000',
                    prefixText: '+7 ',
                    keyboardType: TextInputType.phone,
                    maxLength: kKzPhoneInputMaxDigits,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(kKzPhoneInputMaxDigits),
                    ],
                    validator: (value) {
                      final digits = normalizeKzLocalPhoneDigits(value ?? '');
                      if (digits.length != kKzPhoneDigitsCount) {
                        return 'Нөмір дұрыс емес';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_error != null) {
                        setState(() => _error = null);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Код осы нөмірге келеді',
                    style: TextStyle(
                      color: authTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: TextStyle(color: authTheme.error, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            AuthPrimaryButton(
              theme: authTheme,
              label: 'Код жіберу',
              onPressed: _isSending ? null : _sendCode,
              isLoading: _isSending,
            ),
            if (kEnableTempEmailAuth) ...[
              const SizedBox(height: 12),
              Center(
                child: AuthSecondaryButton(
                  theme: authTheme,
                  label: isWorker
                      ? 'Уақытша Email тіркелу'
                      : 'Уақытша Email кіру',
                  onPressed: _isSending
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TempEmailLoginScreen(
                                selectedRole: widget.selectedRole,
                              ),
                            ),
                          );
                        },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
