import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.showIfCannotPop = false,
    this.size = 38,
  });

  final VoidCallback? onPressed;
  final bool showIfCannotPop;
  final double size;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    if (!canPop && !showIfCannotPop) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final background = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.08),
      scheme.surface,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        splashRadius: 18,
        padding: EdgeInsets.zero,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

Widget? appBarBackButton(
  BuildContext context, {
  VoidCallback? onPressed,
  bool forceShow = false,
}) {
  final canPop = Navigator.of(context).canPop();
  if (!canPop && !forceShow) {
    return null;
  }

  return Padding(
    padding: const EdgeInsets.only(left: 8),
    child: AppBackButton(
      onPressed: onPressed,
      showIfCannotPop: true,
    ),
  );
}
