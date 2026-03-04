import 'package:flutter/material.dart';
import 'package:kuryl_kz/features/auth/models/auth_role.dart';
import 'package:kuryl_kz/features/auth/services/auth_profile_repository.dart';
import 'package:kuryl_kz/features/auth/ui/auth_theme.dart';
import 'package:kuryl_kz/features/auth/ui/auth_widgets.dart';

class ClientProfileSetupScreen extends StatefulWidget {
  final String uid;
  final String phone;
  final VoidCallback onCompleted;
  final VoidCallback onBackToRoleSelection;

  const ClientProfileSetupScreen({
    super.key,
    required this.uid,
    required this.phone,
    required this.onCompleted,
    required this.onBackToRoleSelection,
  });

  @override
  State<ClientProfileSetupScreen> createState() =>
      _ClientProfileSetupScreenState();
}

class _ClientProfileSetupScreenState extends State<ClientProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _repository = AuthProfileRepository();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _repository.createClientProfile(
        uid: widget.uid,
        phone: widget.phone,
        name: _nameController.text,
        city: _cityController.text,
      );
      if (!mounted) return;
      widget.onCompleted();
    } on AuthProfileException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Профиль сақтау қатесі: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = authThemeForRole(AuthRole.client);

    return AuthScaffold(
      theme: theme,
      showBack: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthHeader(
              theme: theme,
              icon: Icons.assignment_turned_in_outlined,
              title: 'Профильді аяқтау',
              subtitle: 'Тапсырыс беруші профилін толтырыңыз.',
            ),
            const SizedBox(height: 24),
            AuthCard(
              theme: theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Телефон',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: theme.inputFill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.border),
                    ),
                    child: Text(
                      widget.phone,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    theme: theme,
                    controller: _nameController,
                    hint: 'Аты-жөніңіз',
                    label: 'Аты-жөні *',
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Аты-жөні міндетті';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    theme: theme,
                    controller: _cityController,
                    hint: 'Қала (міндетті емес)',
                    label: 'Қала',
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.error, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              theme: theme,
              label: 'Сақтау',
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 10),
            Center(
              child: AuthSecondaryButton(
                theme: theme,
                label: 'Рөлді өзгерту',
                onPressed: _isLoading ? null : widget.onBackToRoleSelection,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
