import 'package:flutter/foundation.dart';

class AppLoadingState {
  final bool isLoading;
  final String? message;

  const AppLoadingState({
    required this.isLoading,
    this.message,
  });
}

class AppLoadingController {
  AppLoadingController._();

  static final AppLoadingController instance = AppLoadingController._();

  final ValueNotifier<AppLoadingState> state =
      ValueNotifier(const AppLoadingState(isLoading: false));

  void show([String? message]) {
    state.value = AppLoadingState(isLoading: true, message: message);
  }

  void hide() {
    state.value = const AppLoadingState(isLoading: false);
  }
}
