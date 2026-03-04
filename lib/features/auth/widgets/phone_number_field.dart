import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';

const int kKzPhoneDigitsCount = 10;
const int kKzPhoneInputMaxDigits = 11;

String phoneDigitsOnly(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

String normalizeKzLocalPhoneDigits(String raw) {
  final digits = phoneDigitsOnly(raw);
  if (digits.length == 11 &&
      (digits.startsWith('7') || digits.startsWith('8'))) {
    return digits.substring(1);
  }
  return digits;
}

String buildKzPhone(String localDigits) =>
    '+7${normalizeKzLocalPhoneDigits(localDigits)}';

String? validateKzPhone(String? value) {
  final digits = normalizeKzLocalPhoneDigits(value ?? '');
  if (digits.isEmpty) {
    return 'Нөмірді енгізіңіз';
  }
  if (digits.length != kKzPhoneDigitsCount) {
    return 'Нөмір дұрыс емес';
  }
  return null;
}

class PhoneNumberField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final AutovalidateMode autovalidateMode;
  final String label;
  final String hint;

  const PhoneNumberField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.onChanged,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.label = 'Телефон нөмірі',
    this.hint = '700 000 00 00',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: false,
          ),
          textInputAction: textInputAction,
          autocorrect: false,
          enableSuggestions: false,
          textAlignVertical: TextAlignVertical.center,
          autovalidateMode: autovalidateMode,
          validator: validator ?? validateKzPhone,
          maxLength: kKzPhoneInputMaxDigits,
          buildCounter:
              (
                BuildContext context, {
                required int currentLength,
                required bool isFocused,
                required int? maxLength,
              }) {
                return null;
              },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(kKzPhoneInputMaxDigits),
          ],
          style: AppTypography.body.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
          cursorColor: AppColors.gold,
          cursorWidth: 1.5,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMuted.copyWith(
              fontSize: 15,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surface2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 12, right: 6),
              child: _PrefixChip(),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrefixChip extends StatelessWidget {
  const _PrefixChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        '+7',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
