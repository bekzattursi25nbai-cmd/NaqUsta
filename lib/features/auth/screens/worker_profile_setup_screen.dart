import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/data/service_categories.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/features/auth/models/auth_role.dart';
import 'package:kuryl_kz/features/auth/services/auth_profile_repository.dart';
import 'package:kuryl_kz/features/auth/ui/auth_theme.dart';
import 'package:kuryl_kz/features/auth/ui/auth_widgets.dart';

class WorkerProfileSetupScreen extends StatefulWidget {
  final String uid;
  final String phone;
  final VoidCallback onCompleted;
  final VoidCallback onBackToRoleSelection;

  const WorkerProfileSetupScreen({
    super.key,
    required this.uid,
    required this.phone,
    required this.onCompleted,
    required this.onBackToRoleSelection,
  });

  @override
  State<WorkerProfileSetupScreen> createState() =>
      _WorkerProfileSetupScreenState();
}

class _WorkerProfileSetupScreenState extends State<WorkerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _villageController = TextEditingController();
  final _repository = AuthProfileRepository();

  final List<String> _selectedSpecialties = <String>[];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  void _toggleSpecialty(String value) {
    setState(() {
      if (_selectedSpecialties.contains(value)) {
        _selectedSpecialties.remove(value);
      } else {
        _selectedSpecialties.add(value);
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedSpecialties.isEmpty) {
      setState(() => _error = 'Кемінде 1 мамандық таңдаңыз');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _repository.createWorkerProfile(
        uid: widget.uid,
        phone: widget.phone,
        fullName: _nameController.text,
        city: _cityController.text,
        district: _districtController.text,
        village: _villageController.text,
        specialties: _selectedSpecialties,
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
    final theme = authThemeForRole(AuthRole.worker);

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
              icon: Icons.handyman_outlined,
              title: 'Шебер профилі',
              subtitle: 'Төмендегі міндетті деректерді толтырыңыз.',
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
                    hint: 'Қала',
                    label: 'Қала *',
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Қала міндетті';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    theme: theme,
                    controller: _districtController,
                    hint: 'Аудан',
                    label: 'Аудан *',
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Аудан міндетті';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    theme: theme,
                    controller: _villageController,
                    hint: 'Ауыл/елді мекен',
                    label: 'Ауыл/елді мекен *',
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Елді мекен міндетті';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Мамандық *',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ServiceCategories.interests.take(10).map((item) {
                      final selected = _selectedSpecialties.contains(item);
                      return FilterChip(
                        label: Text(item),
                        selected: selected,
                        onSelected: (_) => _toggleSpecialty(item),
                        selectedColor: theme.primary.withValues(alpha: 0.22),
                        checkmarkColor: theme.onPrimary,
                        labelStyle: TextStyle(
                          color: selected
                              ? theme.textPrimary
                              : theme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: theme.inputFill,
                        side: BorderSide(
                          color: selected ? theme.primary : theme.border,
                        ),
                      );
                    }).toList(),
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
            const SizedBox(height: 16),
            Text(
              'Локация өрісі feed-та қысқа форматта көрсетіледі (қала, аудан, ауыл).',
              style: AppTypography.caption.copyWith(color: theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
