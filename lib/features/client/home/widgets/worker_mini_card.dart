import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';
import 'package:kuryl_kz/features/client/home/models/worker_model.dart';

class WorkerMiniCard extends StatelessWidget {
  final WorkerModel worker;
  final String? matchBadge;

  const WorkerMiniCard({super.key, required this.worker, this.matchBadge});

  @override
  Widget build(BuildContext context) {
    final heroTag = worker.id.trim().isEmpty
        ? null
        : 'worker-avatar-${worker.id.trim()}';

    final avatar = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: SafeNetworkImage(url: worker.avatarUrl, fit: BoxFit.cover),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          if (heroTag == null) avatar else Hero(tag: heroTag, child: avatar),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (matchBadge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          matchBadge!,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          worker.specialty.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    const Icon(Icons.star, color: AppColors.gold, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      worker.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  worker.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        worker.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMuted.copyWith(fontSize: 12),
                      ),
                    ),
                    Text(
                      worker.price,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
