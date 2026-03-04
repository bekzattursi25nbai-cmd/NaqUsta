import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/services/app_loading_controller.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.size = 24,
    this.strokeWidth = 2,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? AppColors.gold;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
      ),
    );
  }
}

class AppLoadingOverlay extends StatelessWidget {
  final Widget child;
  final Color barrierColor;

  const AppLoadingOverlay({
    super.key,
    required this.child,
    this.barrierColor = const Color(0xB0000000),
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLoadingState>(
      valueListenable: AppLoadingController.instance.state,
      builder: (context, state, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: child),
            if (state.isLoading)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: Container(
                    color: barrierColor,
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppLoadingIndicator(
                            size: 32,
                            strokeWidth: 3,
                            color: AppColors.gold,
                          ),
                          if (state.message != null && state.message!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              state.message!,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body,
                            ),
                          ],
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
