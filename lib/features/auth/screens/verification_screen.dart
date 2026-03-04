// lib/features/auth/screens/verification_screen.dart
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/features/auth/widgets/otp_field.dart';
import 'package:kuryl_kz/core/widgets/safe_button_text.dart';
import 'package:kuryl_kz/core/widgets/offline_overlay.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _code = '';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return OfflineFullScreenGate(
      child: Scaffold(
        appBar: AppBar(
          leading: appBarBackButton(context),
          title: const Text('Кодты растау'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
            child: Column(
              children: [
              const SizedBox(height: 24),
              const Text(
                'SMS арқылы келген 4 санды кодты енгізіңіз',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              OtpField(
                length: 4,
                onChanged: (code) {
                  setState(() {
                    _code = code;
                  });
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _code.length == 4 ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const SafeButtonText(
                    'Растау',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
