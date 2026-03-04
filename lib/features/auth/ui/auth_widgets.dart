import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/features/auth/ui/auth_theme.dart';

class AuthScaffold extends StatelessWidget {
  final AuthThemeData theme;
  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;

  const AuthScaffold({
    super.key,
    required this.theme,
    required this.child,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          Positioned(top: -120, right: -80, child: _AccentBlob(theme: theme)),
          Positioned(
            bottom: -140,
            left: -100,
            child: _AccentBlob(theme: theme),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showBack)
                        AppBackButton(
                          onPressed: onBack,
                          showIfCannotPop: true,
                        ),
                      if (showBack) const SizedBox(height: 12),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentBlob extends StatelessWidget {
  final AuthThemeData theme;

  const _AccentBlob({required this.theme});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.accentGradient.first.withValues(alpha: 0.55),
              theme.accentGradient.last.withValues(alpha: 0.18),
            ],
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  final AuthThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: theme.border),
          ),
          child: Icon(icon, color: theme.iconPrimary, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 15,
            height: 1.35,
            color: theme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class AuthCard extends StatelessWidget {
  final AuthThemeData theme;
  final Widget child;

  const AuthCard({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final AuthThemeData theme;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.theme,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: disabled
              ? theme.buttonPrimaryBg.withValues(alpha: 0.55)
              : theme.buttonPrimaryBg,
          foregroundColor: disabled
              ? theme.buttonPrimaryFg.withValues(alpha: 0.75)
              : theme.buttonPrimaryFg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.buttonPrimaryFg,
                  ),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  final AuthThemeData theme;
  final String label;
  final VoidCallback? onPressed;

  const AuthSecondaryButton({
    super.key,
    required this.theme,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: theme.buttonSecondaryFg,
        backgroundColor: theme.buttonSecondaryBg.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: theme.border),
        ),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class AuthTextField extends StatelessWidget {
  final AuthThemeData theme;
  final TextEditingController controller;
  final String hint;
  final String? label;
  final bool enabled;
  final TextInputType keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;
  final String? prefixText;

  const AuthTextField({
    super.key,
    required this.theme,
    required this.controller,
    required this.hint,
    this.label,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.onChanged,
    this.validator,
    this.inputFormatters,
    this.textInputAction = TextInputAction.next,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
      inputFormatters: inputFormatters,
      style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: theme.textSecondary),
        prefixText: prefixText,
        prefixStyle: TextStyle(
          color: theme.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: theme.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: theme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: theme.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: theme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: theme.error, width: 1.2),
        ),
      ),
    );
  }
}
