import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final Widget? placeholder;
  final Widget? fallback;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    this.placeholder,
    this.fallback,
  });

  static const _failureTtl = Duration(minutes: 10);
  static const _failureCacheMax = 200;
  static final Map<String, DateTime> _recentFailures = <String, DateTime>{};

  static String? sanitizeUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final cleaned = trimmed.replaceAll(RegExp(r'\s'), '%20');
    final uri = Uri.tryParse(cleaned);
    if (uri == null) return null;
    if (!uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return cleaned;
  }

  static bool _isRecentlyFailed(String url) {
    final lastFailure = _recentFailures[url];
    if (lastFailure == null) return false;
    if (DateTime.now().difference(lastFailure) > _failureTtl) {
      _recentFailures.remove(url);
      return false;
    }
    return true;
  }

  static void _markFailed(String url) {
    _recentFailures[url] = DateTime.now();
    if (_recentFailures.length <= _failureCacheMax) return;
    final entries = _recentFailures.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final overflow = _recentFailures.length - _failureCacheMax;
    for (var i = 0; i < overflow; i++) {
      _recentFailures.remove(entries[i].key);
    }
  }

  Widget _wrapSize(Widget child) {
    if (width == null && height == null) return child;
    return SizedBox(width: width, height: height, child: child);
  }

  Widget _defaultFallback() {
    return Container(
      color: AppColors.surface2,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        color: AppColors.textMuted,
        size: (width ?? height ?? 48) * 0.5,
      ),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(color: AppColors.surface2);
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = sanitizeUrl(url);
    final fallbackWidget = fallback ?? _defaultFallback();

    if (cleanUrl == null || _isRecentlyFailed(cleanUrl)) {
      return _wrapSize(fallbackWidget);
    }

    return CachedNetworkImage(
      imageUrl: cleanUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: const Duration(milliseconds: 120),
      placeholder: (context, _) {
        if (placeholder != null) return _wrapSize(placeholder!);
        return _wrapSize(_defaultPlaceholder());
      },
      errorWidget: (context, error, stackTrace) {
        _markFailed(cleanUrl);
        return _wrapSize(fallbackWidget);
      },
    );
  }
}
