import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/services/auth_service.dart';
import 'package:kuryl_kz/features/auth/models/auth_role.dart';
import 'package:kuryl_kz/features/auth/services/role_selection_cache.dart';
import 'package:kuryl_kz/features/auth/ui/auth_theme.dart';
import 'package:kuryl_kz/features/auth/ui/auth_widgets.dart';

class TempEmailLoginScreen extends StatefulWidget {
  final AuthRole selectedRole;

  const TempEmailLoginScreen({super.key, required this.selectedRole});

  @override
  State<TempEmailLoginScreen> createState() => _TempEmailLoginScreenState();
}

class _TempEmailLoginScreenState extends State<TempEmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _authService.signInOrRegisterWithEmailPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      RoleSelectionCache.instance.setRole(widget.selectedRole);
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() => _error = result.message);
  }

  @override
  Widget build(BuildContext context) {
    final authTheme = authThemeForRole(widget.selectedRole);
    final isWorker = widget.selectedRole == AuthRole.worker;

    return AuthScaffold(
      theme: authTheme,
      onBack: () => Navigator.of(context).pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthHeader(
              theme: authTheme,
              icon: isWorker ? Icons.engineering : Icons.person_outline,
              title: 'Уақытша Email кіру',
              subtitle: isWorker
                  ? 'Қарапайым режим: аккаунт бар болса кіреді, жоқ болса автоматты тіркеледі. Сәтті болса шебер тіркеліміне өтесіз.'
                  : 'Қарапайым режим: аккаунт бар болса кіреді, жоқ болса автоматты тіркеледі.',
            ),
            const SizedBox(height: 24),
            AuthCard(
              theme: authTheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthTextField(
                    theme: authTheme,
                    controller: _emailController,
                    label: 'Email',
                    hint: 'example@mail.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final raw = (value ?? '').trim();
                      if (raw.isEmpty) return 'Email енгізіңіз';
                      if (!raw.contains('@') || !raw.contains('.')) {
                        return 'Email форматы қате';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    theme: authTheme,
                    controller: _passwordController,
                    label: 'Құпиясөз',
                    hint: 'Кемі 6 таңба',
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      final raw = (value ?? '').trim();
                      if (raw.isEmpty) return 'Құпиясөз енгізіңіз';
                      if (raw.length < 6) return 'Кемі 6 таңба қажет';
                      return null;
                    },
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
            const SizedBox(height: 18),
            AuthPrimaryButton(
              theme: authTheme,
              label: 'Кіру / Тіркелу',
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
