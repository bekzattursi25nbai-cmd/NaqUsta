import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  ConnectivityService._() {
    _init();
    _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  Future<void> _init() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }

  void _updateStatus(Object result) {
    final online = _hasConnection(result);
    if (isOnline.value != online) {
      isOnline.value = online;
    }
  }

  bool _hasConnection(Object result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    if (result is List<ConnectivityResult>) {
      return result.any((item) => item != ConnectivityResult.none);
    }
    return true;
  }

  Future<void> refresh() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }
}
