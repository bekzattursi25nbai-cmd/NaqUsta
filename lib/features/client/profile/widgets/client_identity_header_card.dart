import 'package:flutter/cupertino.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';

import 'client_identity_avatar.dart';

class ClientIdentityHeaderCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String city;
  final String bio;
  final String? avatarUrl;
  final String? avatarLocalPath;
  final VoidCallback? onAvatarEdit;
  final bool avatarBusy;

  const ClientIdentityHeaderCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.city,
    required this.bio,
    required this.avatarUrl,
    required this.avatarLocalPath,
    this.onAvatarEdit,
    this.avatarBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ClientIdentityAvatar(
            avatarUrl: avatarUrl,
            localImagePath: avatarLocalPath,
            displayName: name,
            size: 98,
            onEditTap: onAvatarEdit,
            isBusy: avatarBusy,
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: AppTypography.h2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              const Icon(
                CupertinoIcons.location_solid,
                size: 14,
                color: AppColors.textMuted,
              ),
              Text(city, style: AppTypography.caption),
              Text('• $subtitle', style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bio.trim().isEmpty ? 'Био әлі толтырылмаған.' : bio,
            style: AppTypography.bodyMuted,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
