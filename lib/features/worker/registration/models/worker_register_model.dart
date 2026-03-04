import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kuryl_kz/features/location/models/kato_models.dart';

class WorkerRegisterModel {
  String phoneDigits;
  String fullName;
  String bio;
  String avatarLocalPath;

  String city;
  String district;
  String village;
  String addressNote;
  LocationBreakdown? locationBreakdown;
  WorkerCoverageMode coverageMode;

  List<String> primaryCategoryIds;
  List<String> canDoCategoryIds;
  List<String> primaryCategoryLabels;
  List<String> canDoCategoryLabels;

  List<String> specialties;
  List<String> services;

  bool hasBrigade;
  String brigadeName;
  int? brigadeSize;
  String brigadeRole;

  WorkerRegisterModel({
    this.phoneDigits = '',
    this.fullName = '',
    this.bio = '',
    this.avatarLocalPath = '',
    this.city = '',
    this.district = '',
    this.village = '',
    this.addressNote = '',
    this.locationBreakdown,
    this.coverageMode = WorkerCoverageMode.exact,
    this.primaryCategoryIds = const <String>[],
    this.canDoCategoryIds = const <String>[],
    this.primaryCategoryLabels = const <String>[],
    this.canDoCategoryLabels = const <String>[],
    this.specialties = const <String>[],
    this.services = const <String>[],
    this.hasBrigade = false,
    this.brigadeName = '',
    this.brigadeSize,
    this.brigadeRole = '',
  });

  String get locationLabel {
    final fromBreakdown = locationBreakdown?.shortLabel ?? '';
    if (fromBreakdown.isNotEmpty) return fromBreakdown;

    final parts = <String>[
      city,
      district,
      village,
    ].map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

    if (parts.isEmpty) return 'Not specified';
    return parts.join(', ');
  }

  Map<String, dynamic> toFirestorePayload({
    required String phone,
    required String avatarUrl,
  }) {
    final normalizedPrimaryIds = _normalizeList(
      primaryCategoryIds,
    ).take(3).toList();
    final normalizedCanDoIds = _normalizeList(
      canDoCategoryIds,
    ).where((id) => !normalizedPrimaryIds.contains(id)).take(20).toList();
    final normalizedPrimaryLabels = _normalizeList(primaryCategoryLabels);
    final normalizedCanDoLabels = _normalizeList(canDoCategoryLabels);
    final normalizedSpecialties = normalizedPrimaryLabels.isNotEmpty
        ? normalizedPrimaryLabels
        : _normalizeList(specialties);
    final normalizedServices = normalizedCanDoLabels.isNotEmpty
        ? normalizedCanDoLabels
        : _normalizeList(services);
    final primarySpecialty = normalizedSpecialties.isNotEmpty
        ? normalizedSpecialties.first
        : 'Маман';
    final allCategoryIds = <String>{
      ...normalizedPrimaryIds,
      ...normalizedCanDoIds,
    }.toList(growable: false);

    final selectedLocation = locationBreakdown;
    final locationCity = selectedLocation?.shortLabel ?? city.trim();
    final locationDistrict = selectedLocation?.districtLabel ?? district.trim();
    final locationVillage = selectedLocation?.localityLabel ?? village.trim();

    final payload = <String, dynamic>{
      'role': 'worker',
      'phone': phone,
      'fullName': fullName.trim(),
      'firstName': fullName.trim(),
      'about': bio.trim(),
      'bio': bio.trim(),
      'avatarUrl': avatarUrl.trim(),
      'city': locationCity,
      'district': locationDistrict,
      'village': locationVillage,
      'addressNote': addressNote.trim(),
      'location': locationLabel,
      'coverageMode': coverageMode.wire,
      'specialty': primarySpecialty,
      'primaryCategoryIds': normalizedPrimaryIds,
      'canDoCategoryIds': normalizedCanDoIds,
      'categories': allCategoryIds,
      'specialties': normalizedSpecialties,
      'skills': normalizedSpecialties,
      'tags': normalizedSpecialties,
      'services': normalizedServices,
      'hasBrigade': hasBrigade,
      'brigadeName': brigadeName.trim(),
      'brigadeSize': hasBrigade ? brigadeSize : null,
      'brigadeRole': hasBrigade ? brigadeRole.trim() : '',
      'hourlyRate': 'Келісім бойынша',
      'rating': 5.0,
      'completedOrders': 0,
      'reviewCount': 0,
      'isPromoted': true,
      'createdAt': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    };

    if (selectedLocation != null && selectedLocation.isValid) {
      payload['location'] = selectedLocation.toFirestoreMap(
        coverageMode: coverageMode,
      );
      payload.addAll(
        selectedLocation.toDenormalizedFields(coverageMode: coverageMode),
      );
      payload['locationShort'] = selectedLocation.shortLabel;
      payload['locationLabel'] = selectedLocation.shortLabel;
      payload['locationFullLabel'] = selectedLocation.fullLabel;
      payload['city'] = selectedLocation.shortLabel;
      payload['district'] = selectedLocation.districtLabel;
      payload['village'] =
          selectedLocation.localityLabel ?? selectedLocation.shortLabel;
    }

    if (payload['avatarUrl'].toString().isEmpty) {
      payload['avatarUrl'] =
          'https://img.freepik.com/free-photo/portrait-smiling-manual-worker-with-helmet_329181-3745.jpg';
    }

    return payload;
  }

  List<String> _normalizeList(List<String> source) {
    return source
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }
}
