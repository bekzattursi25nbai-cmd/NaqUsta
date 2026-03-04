import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';

class ClientIdentityAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? localImagePath;
  final String displayName;
  final double size;
  final VoidCallback? onEditTap;
  final bool isBusy;

  const ClientIdentityAvatar({
    super.key,
    required this.avatarUrl,
    required this.localImagePath,
    required this.displayName,
    this.size = 96,
    this.onEditTap,
    this.isBusy = false,
  });

  String get _firstLetter {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'Q';
    return trimmed[0].toUpperCase();
  }

  bool get _hasNetworkAvatar {
    final value = (avatarUrl ?? '').trim();
    return value.isNotEmpty && SafeNetworkImage.sanitizeUrl(value) != null;
  }

  bool get _hasLocalAvatar {
    final value = (localImagePath ?? '').trim();
    return value.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.36),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(child: _buildAvatarContent()),
            ),
          ),
          if (onEditTap != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: _EditAvatarButton(onTap: onEditTap!, isBusy: isBusy),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_hasLocalAvatar) {
      final file = File(localImagePath!.trim());
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallback(),
        );
      }
    }

    if (_hasNetworkAvatar) {
      return SafeNetworkImage(
        url: avatarUrl,
        fit: BoxFit.cover,
        fallback: _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: AppColors.surface2,
      alignment: Alignment.center,
      child: Text(
        _firstLetter,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: AppColors.gold,
        ),
      ),
    );
  }
}

class _EditAvatarButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isBusy;

  const _EditAvatarButton({required this.onTap, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.bg, width: 2),
          ),
          child: Center(
            child: isBusy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: Colors.black,
                    ),
                  )
                : const Icon(
                    Icons.camera_alt_outlined,
                    size: 16,
                    color: Colors.black,
                  ),
          ),
        ),
      ),
    );
  }
}
