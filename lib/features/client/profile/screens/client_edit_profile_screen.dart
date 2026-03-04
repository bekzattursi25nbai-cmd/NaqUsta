import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/core/widgets/app_buttons.dart';

class ClientEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final bool isPhoneReadOnly;

  const ClientEditProfileScreen({
    super.key,
    required this.initialData,
    required this.isPhoneReadOnly,
  });

  @override
  State<ClientEditProfileScreen> createState() =>
      _ClientEditProfileScreenState();
}

class _ClientEditProfileScreenState extends State<ClientEditProfileScreen> {
  static const int _nameMaxLength = 60;
  static const int _bioMaxLength = 300;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _stringValue(
      widget.initialData['fullName'] ?? widget.initialData['name'],
    );
    _cityController.text = _stringValue(widget.initialData['city']);
    _phoneController.text = _stringValue(widget.initialData['phone']);
    _addressController.text = _stringValue(widget.initialData['address']);
    _bioController.text = _stringValue(widget.initialData['bio']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String _stringValue(dynamic value) => value?.toString().trim() ?? '';

  String? _validateName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Аты-жөні міндетті';
    if (text.length < 2) return 'Кемінде 2 таңба енгізіңіз';
    if (text.length > _nameMaxLength) return 'Ең көбі $_nameMaxLength таңба';
    return null;
  }

  String? _validatePhone(String? value) {
    if (widget.isPhoneReadOnly) return null;
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Телефон міндетті';
    if (digits.length < 10) return 'Телефон нөмірі толық емес';
    return null;
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'fullName': _nameController.text.trim(),
      'city': _cityController.text.trim(),
      'address': _addressController.text.trim(),
      'bio': _bioController.text.trim(),
    };
    if (!widget.isPhoneReadOnly) {
      payload['phone'] = _phoneController.text.trim();
    }

    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: appBarBackButton(context),
        title: const Text('Профильді өңдеу'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + bottomInset),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  label: 'Аты-жөні',
                  hint: 'Мысалы, Айдос Серік',
                  controller: _nameController,
                  inputAction: TextInputAction.next,
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(_nameMaxLength),
                  ],
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: 'Қала',
                  hint: 'Мысалы, Алматы',
                  controller: _cityController,
                  inputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: widget.isPhoneReadOnly
                      ? 'Телефон (өзгертілмейді)'
                      : 'Телефон',
                  hint: '+7...',
                  controller: _phoneController,
                  inputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                  enabled: !widget.isPhoneReadOnly,
                ),
                if (widget.isPhoneReadOnly) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Бұл телефон Firebase Auth арқылы байланыстырылған.',
                    style: AppTypography.caption,
                  ),
                ],
                const SizedBox(height: 16),
                _buildField(
                  label: 'Мекенжай',
                  hint: 'Көше, үй, пәтер',
                  controller: _addressController,
                  inputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: 'Қысқаша био',
                  hint: 'Өзіңіз туралы қысқаша жазыңыз',
                  controller: _bioController,
                  inputAction: TextInputAction.done,
                  maxLines: 4,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(_bioMaxLength),
                  ],
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(label: 'Сақтау', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputAction inputAction = TextInputAction.next,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          textInputAction: inputAction,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTypography.body,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMuted,
          ),
        ),
      ],
    );
  }
}
