import 'dart:ui';

String resolveCategoryLocaleCode(Locale locale) {
  // Product requirement: category taxonomy is displayed in Kazakh first.
  final code = locale.languageCode.trim().toLowerCase();
  if (code == 'kk') return 'kk';
  return 'kk';
}
