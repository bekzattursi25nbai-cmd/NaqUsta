import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/theme/app_theme.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/core/widgets/app_buttons.dart';
import 'package:kuryl_kz/core/widgets/offline_overlay.dart';
import 'package:kuryl_kz/features/auth/screens/verification_screen.dart';
import 'package:kuryl_kz/features/auth/widgets/phone_number_field.dart';

class RegisterScreen extends StatefulWidget {
  final String role; // 'worker' немесе 'client'
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWorker = widget.role == 'worker';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Theme(
      data: AppTheme.clientDark(),
      child: OfflineFullScreenGate(
        child: Scaffold(
          appBar: AppBar(
            leading: appBarBackButton(context),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWorker ? "Шебер тіркеуі" : "Тапсырыс беруші",
                      style: AppTypography.h1,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isWorker
                          ? "Шебер тіркелуі уақытша жабық."
                          : "Үйіңізге маман табу үшін тіркеліңіз.",
                      style: AppTypography.bodyMuted,
                    ),
                    const SizedBox(height: 30),
                    if (!isWorker)
                      PhoneNumberField(
                        controller: _phoneController,
                        textInputAction: TextInputAction.done,
                        validator: validateKzPhone,
                      ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: isWorker ? "Жабық" : "Код алу",
                      onPressed: isWorker
                          ? null
                          : () {
                              final isValid =
                                  _formKey.currentState?.validate() ?? false;
                              if (!isValid) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OtpVerificationScreen(),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
