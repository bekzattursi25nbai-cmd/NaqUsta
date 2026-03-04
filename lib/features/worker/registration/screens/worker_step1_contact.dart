import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/safe_button_text.dart';
import 'package:kuryl_kz/features/auth/widgets/phone_number_field.dart';
import 'package:kuryl_kz/features/worker/widgets/worker_input_field.dart';

class WorkerStep1Contact extends StatefulWidget {
  // onNext енді парольді де қабылдайды
  final Function(String phone, String email, String password) onNext;

  const WorkerStep1Contact({super.key, required this.onNext});

  @override
  State<WorkerStep1Contact> createState() => _WorkerStep1ContactState();
}

class _WorkerStep1ContactState extends State<WorkerStep1Contact> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // Құпия сөз контроллерлері
  String _password = "";
  String _confirmPassword = "";
  bool _obscurePassword = true;

  void _validateAndContinue() {
    final normalized = normalizeKzLocalPhoneDigits(_phoneController.text);
    
    // 1. Телефон тексеру
    if (normalized.length != kKzPhoneDigitsCount) {
      _showSnack("Телефон нөмірін толық енгізіңіз");
      return;
    }
    // 2. Пароль тексеру
    if (_password.length < 6) {
      _showSnack("Құпия сөз тым қысқа (кемі 6 таңба)");
      return;
    }
    if (_password != _confirmPassword) {
      _showSnack("Құпия сөздер сәйкес келмейді");
      return;
    }

    // Бәрі дұрыс болса -> Келесі бет
    widget.onNext(normalized, _emailController.text.trim(), _password);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("1-ҚАДАМ", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Байланыс және Қауіпсіздік", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Телефон нөміріңіз логин ретінде қолданылады", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            
            // ТЕЛЕФОН
            PhoneNumberField(
              controller: _phoneController,
              label: 'ТЕЛЕФОН',
              hint: '700 000 00 00',
            ),

            const SizedBox(height: 20),
            
            // ҚҰПИЯ СӨЗ
            const Text("ҚҰПИЯ СӨЗ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            // Егер WorkerInputField-те obscureText жоқ болса, қарапайым TextField қолданамыз немесе виджетті жаңартыңыз
            Container(
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: TextField(
                obscureText: _obscurePassword,
                onChanged: (v) => _password = v,
                decoration: InputDecoration(
                  hintText: "••••••",
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ҚҰПИЯ СӨЗДІ ҚАЙТАЛАУ
            const Text("ҚҰПИЯ СӨЗДІ ҚАЙТАЛАУ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: TextField(
                obscureText: _obscurePassword,
                onChanged: (v) => _confirmPassword = v,
                decoration: InputDecoration(
                  hintText: "••••••",
                  prefixIcon: const Icon(Icons.lock_reset, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // EMAIL
            const Text("EMAIL (ҚОСЫМША)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            WorkerInputField(
              controller: _emailController,
              hintText: "example@mail.com",
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validateAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E), 
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                child: const SafeButtonText(
                  "Жалғастыру",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
