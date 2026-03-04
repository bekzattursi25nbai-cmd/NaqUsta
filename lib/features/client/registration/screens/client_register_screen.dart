import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kuryl_kz/core/data/service_categories.dart';
import 'package:kuryl_kz/core/services/auth_service.dart';
import 'package:kuryl_kz/core/theme/app_theme.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/core/widgets/app_buttons.dart';
import 'package:kuryl_kz/core/widgets/app_chips.dart';
import 'package:kuryl_kz/core/widgets/app_text_field.dart';
import 'package:kuryl_kz/core/widgets/offline_overlay.dart';
import 'package:kuryl_kz/features/auth/widgets/phone_number_field.dart';
import 'package:kuryl_kz/features/location/models/kato_models.dart';
import 'package:kuryl_kz/features/location/widgets/location_picker.dart';
import 'package:kuryl_kz/features/client/navigation/client_main_navigation.dart';
import '../controller/client_register_controller.dart';

class ClientRegisterScreen extends StatefulWidget {
  final String? prefillPhone;

  const ClientRegisterScreen({super.key, this.prefillPhone});

  @override
  State<ClientRegisterScreen> createState() => _ClientRegisterScreenState();
}

class _ClientRegisterScreenState extends State<ClientRegisterScreen> {
  final controller = ClientRegisterController();
  final AuthService _authService = AuthService();
  final _phoneFormKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  LocationBreakdown? _selectedLocation;
  final List<String> _selectedInterests = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.phoneNumber != null) {
      _phoneController.text = normalizeKzLocalPhoneDigits(
        currentUser!.phoneNumber!,
      );
    } else if (widget.prefillPhone != null && widget.prefillPhone!.isNotEmpty) {
      _phoneController.text = normalizeKzLocalPhoneDigits(widget.prefillPhone!);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _normalizedPhone() => buildKzPhone(_phoneController.text);

  void _snack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.surface2,
      ),
    );
  }

  bool _validatePhoneOnly() {
    return _phoneFormKey.currentState?.validate() ?? false;
  }

  Future<bool> _startPhoneAuth(String phone) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      _snack('Алдымен аккаунтпен кіріңіз.');
      return false;
    }

    final authPhone = authUser.phoneNumber;
    if (authPhone == null || authPhone.trim().isEmpty) {
      final authEmail = (authUser.email ?? '').trim();
      if (authEmail.isNotEmpty) {
        return true;
      }
      _snack('Алдымен OTP немесе Email арқылы жүйеге кіріңіз.');
      return false;
    }

    final authDigits = normalizeKzLocalPhoneDigits(authPhone);
    final formDigits = normalizeKzLocalPhoneDigits(phone);
    if (authDigits != formDigits) {
      _snack('Кірген телефон нөмірі мен формадағы нөмір сәйкес емес.');
      return false;
    }

    return true;
  }

  Future<AuthResult?> _persistProfileIfPossible(
    Map<String, dynamic> userData,
  ) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return AuthResult.fail('Алдымен аккаунтпен кіріңіз.');
    }
    return _authService.upsertClientProfile(userData: userData);
  }

  Map<String, dynamic> _buildClientPayload(String normalizedPhone) {
    final age = int.tryParse(_ageController.text.trim()) ?? 0;

    controller.setName(
      _nameController.text.trim().isEmpty
          ? 'Клиент'
          : _nameController.text.trim(),
    );
    controller.setPhone(normalizedPhone);
    controller.setLocation(_selectedLocation);
    controller.setCity(_selectedLocation?.shortLabel ?? '');
    controller.setAddress(_addressController.text.trim());
    controller.setAge(age);
    controller.setInterests(_selectedInterests);

    return controller.model.toMap();
  }

  void _openClientMain(Map<String, dynamic> userData) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => ClientMainNavigation(userData: userData),
      ),
      (route) => false,
    );
  }

  Future<void> _submit() async {
    if (!_validatePhoneOnly()) return;
    if (_selectedLocation == null) {
      _snack('Сіздің мекен жайыңызды таңдаңыз.');
      return;
    }

    setState(() => _isLoading = true);

    final normalizedPhone = _normalizedPhone();
    final authStarted = await _startPhoneAuth(normalizedPhone);
    if (!authStarted) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final userData = _buildClientPayload(normalizedPhone);
    final result = await _persistProfileIfPossible(userData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null && result.success) {
      controller.logData();
      _openClientMain(userData);
    } else {
      _snack(result?.message ?? 'Профиль сақтау сәтсіз аяқталды');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.clientDark(),
      child: OfflineFullScreenGate(
        child: Scaffold(
          appBar: AppBar(
            leading: appBarBackButton(context),
            title: const Text('Тіркелу'),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    24 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth > 620
                            ? 560
                            : constraints.maxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Телефон нөмірі', style: AppTypography.h3),
                          const SizedBox(height: 12),
                          _buildPhoneSection(),
                          const SizedBox(height: 24),
                          Text(
                            'Қосымша деректер (міндетті емес)',
                            style: AppTypography.h3,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Аты-жөні',
                            hint: 'Мысалы, Асқар',
                            controller: _nameController,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Жас',
                            hint: '25',
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: const InputDecorationTheme(
                                filled: true,
                                fillColor: AppColors.surface2,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.gold,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            child: LocationPicker(
                              mode: LocationPickerMode.registration,
                              enableSearch: false,
                              showHeader: true,
                              title: 'Сіздің мекен жайыңыз',
                              initialValue: _selectedLocation,
                              onChanged: (value) {
                                setState(() => _selectedLocation = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Мекенжай (міндетті емес)',
                            hint: 'Көше, үй',
                            controller: _addressController,
                          ),
                          const SizedBox(height: 24),
                          Text('Қажетті қызметтер', style: AppTypography.h3),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: ServiceCategories.interests.map((cat) {
                              final selected = _selectedInterests.contains(cat);
                              return AppChoiceChip(
                                label: cat,
                                selected: selected,
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      _selectedInterests.remove(cat);
                                    } else {
                                      _selectedInterests.add(cat);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 28),
                          AppPrimaryButton(
                            label: 'Жалғастыру',
                            onPressed: _submit,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneSection() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhoneNumberField(
            controller: _phoneController,
            textInputAction: TextInputAction.done,
            validator: validateKzPhone,
          ),
          const SizedBox(height: 8),
          const Text(
            'Телефон нөмірі OTP арқылы расталған аккаунтпен сәйкес болуы керек.',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
