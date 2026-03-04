import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/services/connectivity_service.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_buttons.dart';

class OfflineBannerOverlay extends StatelessWidget {
  final Widget child;

  const OfflineBannerOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, isOnline, _) {
        final showBanner = !isOnline;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: RepaintBoundary(child: child)),
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: IgnorePointer(
                  ignoring: !showBanner,
                  child: AnimatedSwitcher(
                    duration: AppMotion.normal,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0, -1),
                        end: Offset.zero,
                      ).animate(animation);
                      return SlideTransition(
                        position: slide,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: showBanner
                        ? OfflineBanner(
                            key: const ValueKey('offline_banner'),
                            onRetry: ConnectivityService.instance.refresh,
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('offline_banner_empty'),
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class OfflineBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineBanner({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: AppColors.gold),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Интернет жоқ. Қосылыңызды тексеріңіз.",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  "Қайта көру",
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class OfflineFullScreenGate extends StatelessWidget {
  final Widget child;
  final String title;
  final String message;

  const OfflineFullScreenGate({
    super.key,
    required this.child,
    this.title = "Интернет жоқ",
    this.message = "Қайта қосылып көріңіз немесе желіңізді тексеріңіз.",
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, isOnline, _) {
        if (isOnline) return child;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: RepaintBoundary(child: child)),
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.bg,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadii.xl),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.wifi_off,
                            size: 44,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(title, style: AppTypography.h3),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMuted,
                        ),
                        const SizedBox(height: 20),
                        AppSecondaryButton(
                          label: "Қайта көру",
                          onPressed: ConnectivityService.instance.refresh,
                          icon: Icons.refresh,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
