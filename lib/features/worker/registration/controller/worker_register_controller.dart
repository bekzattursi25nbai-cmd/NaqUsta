import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/services/auth_service.dart';
import 'package:kuryl_kz/features/auth/widgets/phone_number_field.dart';
import 'package:kuryl_kz/features/location/models/kato_models.dart';

import '../models/worker_register_model.dart';
import '../services/worker_auth_service.dart';

class WorkerRegisterController extends ChangeNotifier {
  final WorkerRegisterModel _model = WorkerRegisterModel();
  final AuthService _authService;
  final WorkerAuthService _workerAuthService;

  WorkerRegisterController({
    AuthService? authService,
    WorkerAuthService? workerAuthService,
  }) : _authService = authService ?? AuthService(),
       _workerAuthService = workerAuthService ?? WorkerAuthService();

  bool _isLoading = false;
  String? _lastError;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  WorkerRegisterModel get workerData => _model;

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  void updatePhoneDigits(String localDigits) {
    _model.phoneDigits = normalizeKzLocalPhoneDigits(localDigits);
    notifyListeners();
  }

  void updateBasicProfile({
    required String fullName,
    required String bio,
    required String avatarLocalPath,
  }) {
    _model.fullName = fullName.trim();
    _model.bio = bio.trim();
    _model.avatarLocalPath = avatarLocalPath.trim();
    notifyListeners();
  }

  void updateLocation({
    required LocationBreakdown location,
    required WorkerCoverageMode coverageMode,
    required String addressNote,
  }) {
    _model.locationBreakdown = location;
    _model.coverageMode = coverageMode;
    _model.city = location.shortLabel.trim();
    _model.district = location.districtLabel.trim();
    _model.village = (location.localityLabel ?? location.shortLabel).trim();
    _model.addressNote = addressNote.trim();
    notifyListeners();
  }

  void updateSpecialties(List<String> specialties) {
    updatePrimaryCategories(
      categoryIds: specialties,
      categoryLabels: specialties,
    );
  }

  void updatePrimaryCategories({
    required List<String> categoryIds,
    required List<String> categoryLabels,
  }) {
    _model.primaryCategoryIds = categoryIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .take(3)
        .toList();
    _model.primaryCategoryLabels = categoryLabels
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .take(3)
        .toList();
    _model.specialties = _model.primaryCategoryLabels;

    _model.canDoCategoryIds = _model.canDoCategoryIds
        .where((id) => !_model.primaryCategoryIds.contains(id))
        .toList();
    _model.canDoCategoryLabels = _model.canDoCategoryLabels
        .where((label) => !_model.primaryCategoryLabels.contains(label))
        .toList();
    _model.services = _model.canDoCategoryLabels;
    notifyListeners();
  }

  void updateServices(List<String> services) {
    updateCanDoCategories(categoryIds: services, categoryLabels: services);
  }

  void updateCanDoCategories({
    required List<String> categoryIds,
    required List<String> categoryLabels,
  }) {
    final normalizedPrimary = _model.primaryCategoryIds.toSet();
    _model.canDoCategoryIds = categoryIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .where((id) => !normalizedPrimary.contains(id))
        .toSet()
        .take(20)
        .toList();
    _model.canDoCategoryLabels = categoryLabels
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .take(20)
        .toList();
    _model.services = _model.canDoCategoryLabels;
    notifyListeners();
  }

  void updateBrigadeInfo({
    required bool hasBrigade,
    required String brigadeName,
    required int? brigadeSize,
    required String brigadeRole,
  }) {
    _model.hasBrigade = hasBrigade;
    _model.brigadeName = brigadeName.trim();
    _model.brigadeSize = hasBrigade ? brigadeSize : null;
    _model.brigadeRole = hasBrigade ? brigadeRole.trim() : '';
    notifyListeners();
  }

  Future<bool> startPhoneAuth(String localDigits) async {
    final normalized = normalizeKzLocalPhoneDigits(localDigits);
    var length = normalized.length;
    var length2 = length;
    if (kKzPhoneDigitsCount != length2) {
      _lastError = 'Телефон нөмірі қате форматта';
      return false;
    }

    final phone = buildKzPhone(normalized);
    final started = await _workerAuthService.startPhoneAuth(phone);
    if (!started) {
      _lastError = 'Телефон верификациясын бастау сәтсіз аяқталды.';
      return false;
    }

    _model.phoneDigits = normalized;
    _lastError = null;
    return true;
  }

  Future<bool> registerWorker() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      if (_model.phoneDigits.length != kKzPhoneDigitsCount) {
        _lastError = 'Телефон нөмірі міндетті';
        return false;
      }
      if (_model.fullName.trim().isEmpty) {
        _lastError = 'Аты-жөні міндетті';
        return false;
      }
      final selectedLocation = _model.locationBreakdown;
      if (selectedLocation == null || !selectedLocation.isValid) {
        _lastError = 'Мекен жайды таңдаңыз';
        return false;
      }
      if (_model.coverageMode == WorkerCoverageMode.exact &&
          selectedLocation.katoCode.trim().isEmpty) {
        _lastError = 'Дәл мекен жай таңдалмаған';
        return false;
      }
      if (_model.coverageMode == WorkerCoverageMode.district &&
          selectedLocation.districtKatoCode.trim().isEmpty) {
        _lastError = 'Аудан коды жоқ, басқа локация таңдаңыз';
        return false;
      }
      if (_model.coverageMode == WorkerCoverageMode.region &&
          selectedLocation.regionKatoCode.trim().isEmpty) {
        _lastError = 'Өңір коды жоқ, басқа локация таңдаңыз';
        return false;
      }
      if (_model.primaryCategoryIds.isEmpty ||
          _model.primaryCategoryIds.length > 3) {
        _lastError = 'Негізгі мамандық саны 1 мен 3 аралығында болуы керек';
        return false;
      }
      if (_model.canDoCategoryIds.length > 20) {
        _lastError = 'Қосымша дағдылар 20-дан аспауы керек';
        return false;
      }
      if (_model.hasBrigade) {
        final size = _model.brigadeSize;
        if (size == null || size <= 0) {
          _lastError = 'Бригада саны дұрыс емес';
          return false;
        }
        if (_model.brigadeRole.trim().isEmpty) {
          _lastError = 'Бригададағы рөліңізді таңдаңыз';
          return false;
        }
      }

      final normalizedPhone = normalizeKzLocalPhoneDigits(_model.phoneDigits);
      final phone = buildKzPhone(normalizedPhone);

      final authStarted = await _workerAuthService.startPhoneAuth(phone);
      if (!authStarted) {
        _lastError = 'Телефон авторизациясын бастау мүмкін болмады';
        return false;
      }

      final sessionResult = await _workerAuthService.ensureWorkerSession(
        phoneDigits: normalizedPhone,
      );
      if (!sessionResult.success || sessionResult.uid == null) {
        _lastError = sessionResult.message;
        return false;
      }
      final uid = sessionResult.uid!;

      final uploadedAvatarUrl = await _workerAuthService.uploadAvatar(
        uid: uid,
        localPath: _model.avatarLocalPath,
      );

      final payload = _model.toFirestorePayload(
        phone: phone,
        avatarUrl: uploadedAvatarUrl ?? '',
      );

      final persistResult = await _authService.upsertWorkerProfile(
        uid: uid,
        workerData: payload,
      );

      if (!persistResult.success) {
        _lastError = persistResult.message;
        return false;
      }

      return true;
    } catch (e) {
      _lastError = 'Тіркелу қатесі: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
