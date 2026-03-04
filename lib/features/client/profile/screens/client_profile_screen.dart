import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kuryl_kz/core/services/auth_service.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_loading.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';
import 'package:kuryl_kz/features/auth/services/role_selection_cache.dart';
import 'package:kuryl_kz/features/client/home/models/worker_model.dart';
import 'package:kuryl_kz/features/client/home/screens/worker_detail_screen.dart';
import 'package:kuryl_kz/features/client/my_request/screens/my_requests_screen.dart';
import 'package:kuryl_kz/features/client/profile/screens/client_about_screen.dart';
import 'package:kuryl_kz/features/client/profile/screens/client_edit_profile_screen.dart';
import 'package:kuryl_kz/features/client/profile/screens/client_support_screen.dart';
import 'package:kuryl_kz/features/client/profile/widgets/client_identity_header_card.dart';
import 'package:kuryl_kz/features/client/settings/client_settings_screen.dart';
import 'package:path_provider/path_provider.dart';

import '../../registration/models/client_register_model.dart';

class ClientProfileScreen extends StatefulWidget {
  final ClientRegisterModel? userData;

  const ClientProfileScreen({super.key, this.userData});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Map<String, dynamic> _profileData = <String, dynamic>{};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAvatarBusy = false;
  String? _error;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _orders =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  bool _ordersLoading = false;
  String? _ordersError;

  List<WorkerModel> _favoriteWorkers = <WorkerModel>[];
  bool _favoritesLoading = false;
  String? _favoritesError;
  bool get _hasAuthorizedUser => _currentUser != null;

  @override
  void initState() {
    super.initState();
    _seedProfileFromInitialData();
    _loadProfile();
  }

  void _seedProfileFromInitialData() {
    final initial = widget.userData;
    if (initial == null) return;

    _profileData = <String, dynamic>{
      ..._profileData,
      'name': initial.name,
      'fullName': initial.name,
      'phone': initial.phone,
      'city': initial.city,
      'address': initial.address,
      'address_type': initial.addressType,
      'floor': initial.floor,
      'age': initial.age,
      'interests': initial.interests,
      'bio': _asString(_profileData['bio']),
      'favoriteWorkerIds': _asStringList(_profileData['favoriteWorkerIds']),
      'showPhone': _asBool(_profileData['showPhone'], fallback: true),
      'showEmail': _asBool(_profileData['showEmail'], fallback: true),
      'showOnlineStatus': _asBool(
        _profileData['showOnlineStatus'],
        fallback: true,
      ),
      'notificationsPush': _asBool(
        _profileData['notificationsPush'],
        fallback: true,
      ),
      'notificationsEmail': _asBool(
        _profileData['notificationsEmail'],
        fallback: false,
      ),
      'appLanguage': _asString(_profileData['appLanguage'], fallback: 'kz'),
      'themeMode': _asString(_profileData['themeMode'], fallback: 'dark'),
    };
  }

  Future<void> _loadProfile() async {
    final user = _currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _profileData = <String, dynamic>{
          ..._buildGuestProfileSeed(),
          ..._profileData,
        };
        _orders = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        _favoriteWorkers = <WorkerModel>[];
        _ordersLoading = false;
        _favoritesLoading = false;
        _ordersError = null;
        _favoritesError = null;
        _isLoading = false;
        _error = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final map = doc.data() ?? <String, dynamic>{};
      final merged = <String, dynamic>{
        ..._profileData,
        ...map,
        'showPhone': _asBool(map['showPhone'], fallback: true),
        'showEmail': _asBool(map['showEmail'], fallback: true),
        'showOnlineStatus': _asBool(map['showOnlineStatus'], fallback: true),
        'notificationsPush': _asBool(map['notificationsPush'], fallback: true),
        'notificationsEmail': _asBool(
          map['notificationsEmail'],
          fallback: false,
        ),
        'appLanguage': _asString(map['appLanguage'], fallback: 'kz'),
        'themeMode': _asString(map['themeMode'], fallback: 'dark'),
      };

      if (!mounted) return;
      setState(() {
        _profileData = merged;
        _isLoading = false;
      });

      await Future.wait([_loadOrders(user.uid), _loadFavorites(merged)]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Профиль жүктелмеді: $e';
      });
    }
  }

  Future<void> _loadOrders(String uid) async {
    setState(() {
      _ordersLoading = true;
      _ordersError = null;
    });

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('clientId', isEqualTo: uid)
            .limit(30)
            .get();
      } on FirebaseException {
        snapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('clientId', isEqualTo: uid)
            .limit(30)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        try {
          snapshot = await FirebaseFirestore.instance
              .collection('requests')
              .where('client_uid', isEqualTo: uid)
              .limit(30)
              .get();
        } catch (_) {
          // Keep current snapshot if legacy read fails.
        }
      }

      if (!mounted) return;
      setState(() {
        _orders = snapshot.docs;
        _ordersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ordersLoading = false;
        _ordersError = 'Тапсырыстар жүктелмеді: $e';
      });
    }
  }

  Future<void> _loadFavorites(Map<String, dynamic> profileMap) async {
    final ids = _asStringList(
      profileMap['favoriteWorkerIds'] ?? profileMap['favorites'],
    );

    if (ids.isEmpty) {
      if (!mounted) return;
      setState(() {
        _favoriteWorkers = <WorkerModel>[];
        _favoritesError = null;
        _favoritesLoading = false;
      });
      return;
    }

    setState(() {
      _favoritesLoading = true;
      _favoritesError = null;
    });

    try {
      final workers = <WorkerModel>[];
      final chunks = <List<String>>[];

      for (int i = 0; i < ids.length; i += 10) {
        final chunk = ids.sublist(i, math.min(i + 10, ids.length));
        chunks.add(chunk);
      }

      for (final chunk in chunks) {
        final snap = await FirebaseFirestore.instance
            .collection('workers')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snap.docs) {
          workers.add(WorkerModel.fromMap(doc.data(), doc.id));
        }
      }

      if (!mounted) return;
      setState(() {
        _favoriteWorkers = workers;
        _favoritesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _favoritesLoading = false;
        _favoritesError = 'Сақталған шеберлерді жүктеу қатесі: $e';
      });
    }
  }

  Future<void> _saveProfile(
    Map<String, dynamic> updates, {
    bool showSuccess = true,
  }) async {
    final previous = Map<String, dynamic>.from(_profileData);
    final next = <String, dynamic>{..._profileData, ...updates};

    setState(() {
      _isSaving = true;
      _profileData = next;
    });

    if (!_hasAuthorizedUser) {
      setState(() => _isSaving = false);
      if (showSuccess) {
        _showSnack(
          'Профиль локалды сақталды. Серверге сақтау үшін аккаунтпен кіріңіз.',
          isError: false,
        );
      }
      return;
    }

    final result = await _authService.upsertClientProfile(userData: next);

    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _profileData = previous;
        _isSaving = false;
      });
      _showSnack(result.message);
      return;
    }

    setState(() => _isSaving = false);
    if (showSuccess) {
      _showSnack('Профиль сақталды.', isError: false);
    }

    final favoritesChanged =
        updates.containsKey('favoriteWorkerIds') ||
        updates.containsKey('favorites');
    if (favoritesChanged) {
      _loadFavorites(_profileData);
    }
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientEditProfileScreen(
          initialData: _profileData,
          isPhoneReadOnly: _isPhoneLockedByAuth,
        ),
      ),
    );

    if (result == null) return;

    final name = _asString(result['name']).trim();
    if (name.length < 2) {
      _showSnack('Аты-жөні кемінде 2 таңба болу керек.');
      return;
    }

    final updates = <String, dynamic>{
      'name': name,
      'fullName': name,
      'city': _asString(result['city']),
      'address': _asString(result['address']),
      'bio': _asString(result['bio']),
    };
    if (!_isPhoneLockedByAuth) {
      updates['phone'] = _asString(result['phone']);
    }

    await _saveProfile(updates);
  }

  Future<void> _pickAvatar() async {
    final user = _currentUser;

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 84,
      );
      if (picked == null) return;

      setState(() => _isAvatarBusy = true);

      final file = File(picked.path);
      final uploadedUrl = user == null
          ? null
          : await _tryUploadAvatar(user.uid, file);
      final storageKey = user?.uid ?? 'guest';

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        await _saveProfile(<String, dynamic>{
          'avatarUrl': uploadedUrl,
          'avatarLocalPath': '',
        }, showSuccess: false);
        if (!mounted) return;
        _showSnack('Фото жаңартылды.', isError: false);
      } else {
        final localPath = await _persistAvatarLocally(storageKey, file);
        if (localPath == null || localPath.isEmpty) {
          _showSnack('Фотоны сақтау мүмкін болмады.');
        } else {
          await _saveProfile(<String, dynamic>{
            'avatarUrl': '',
            'avatarLocalPath': localPath,
          }, showSuccess: false);
          if (!mounted) return;
          final message = user == null
              ? 'Фото локалды сақталды. Аккаунтпен кірген соң серверге жүктей аласыз.'
              : 'Фото локалды сақталды. Backend upload әзірге қолжетімсіз.';
          _showSnack(message, isError: false);
        }
      }
    } catch (e) {
      _showSnack('Фотоны таңдау қатесі: $e');
    } finally {
      if (mounted) {
        setState(() => _isAvatarBusy = false);
      }
    }
  }

  Future<String?> _tryUploadAvatar(String uid, File file) async {
    try {
      final ext = _fileExtension(file.path);
      final ref = FirebaseStorage.instance.ref().child(
        'uploads/$uid/images/avatars/client_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );

      await ref.putFile(file, SettableMetadata(contentType: 'image/$ext'));
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _persistAvatarLocally(String uid, File source) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${dir.path}/client_avatars');
      if (!avatarDir.existsSync()) {
        await avatarDir.create(recursive: true);
      }

      final ext = _fileExtension(source.path);
      final target = File(
        '${avatarDir.path}/$uid-${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      final saved = await source.copy(target.path);
      return saved.path;
    } catch (_) {
      return null;
    }
  }

  String _fileExtension(String path) {
    final normalized = path.trim().toLowerCase();
    if (normalized.endsWith('.png')) return 'png';
    if (normalized.endsWith('.webp')) return 'webp';
    return 'jpeg';
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientSettingsScreen(
          initialProfileData: Map<String, dynamic>.from(_profileData),
        ),
      ),
    );
    await _loadProfile();
  }

  Future<void> _changePassword() async {
    final user = _currentUser;
    if (user == null) {
      _showSnack('Пароль өзгерту үшін аккаунтпен кіріңіз.');
      return;
    }

    if (user.email == null || user.email!.trim().isEmpty) {
      _showSnack(
        'Email тіркелмеген аккаунтта парольді осы жерден өзгерту мүмкін емес.',
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: user.email!.trim(),
      );
      if (!mounted) return;
      _showSnack('Парольді өзгерту сілтемесі жіберілді.', isError: false);
    } catch (e) {
      _showSnack('Сілтеме жіберу қатесі: $e');
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Шығу'),
        content: const Text('Аккаунттан шығасыз ба?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Жоқ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Иә'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    await _logout();
  }

  Future<void> _logout() async {
    RoleSelectionCache.instance.clear();
    if (_hasAuthorizedUser) {
      await _authService.signOut();
    }
    if (!mounted) return;
    _returnToAuthGateRoot();
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await _showDeleteAccountConfirmDialog();
    if (confirmed != true) return;

    if (!_hasAuthorizedUser) {
      _showSnack(
        'Аккаунт backend-де табылмады. Локалды сессия жабылды.',
        isError: false,
      );
      _returnToAuthGateRoot();
      return;
    }

    setState(() => _isSaving = true);

    final result = await _authService.deleteClientAccount();

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      RoleSelectionCache.instance.clear();
      _returnToAuthGateRoot();
      return;
    }

    _showSnack(result.message);

    // Backend/account delete мүмкін болмаса да user-ды қауіпсіз logout жасаймыз.
    RoleSelectionCache.instance.clear();
    await _authService.signOut();
    if (!mounted) return;
    _returnToAuthGateRoot();
  }

  Future<bool?> _showDeleteAccountConfirmDialog() {
    final controller = TextEditingController();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isReady = controller.text.trim().toUpperCase() == 'DELETE';
            return AlertDialog(
              title: const Text('Аккаунтты өшіру'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Бұл әрекет қайтарылмайды. Жалғастыру үшін төменге DELETE деп жазыңыз.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(hintText: 'DELETE'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Бас тарту'),
                ),
                TextButton(
                  onPressed: isReady
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: const Text(
                    'Өшіру',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _returnToAuthGateRoot() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openSupportContacts() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Байланыс'),
        content: const Text(
          'Email: support@kuryl.kz\nЖұмыс уақыты: 09:00 - 18:00',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Жабу'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  String get _displayName {
    final full = _asString(_profileData['fullName']);
    if (full.isNotEmpty) return full;
    final name = _asString(_profileData['name']);
    if (name.isNotEmpty) return name;
    return 'Қонақ';
  }

  String get _displayCity {
    final locationMap = _asMap(_profileData['location']);
    return _firstNonEmpty(<String?>[
      _asString(_profileData['locationShort']),
      _asString(_profileData['locationLabel']),
      _asString(locationMap['shortLabel']),
      _asString(_profileData['city']),
    ], fallback: 'Мекен жай таңдалмады');
  }

  String get _displayPhone {
    final fromProfile = _asString(_profileData['phone']);
    if (fromProfile.isNotEmpty) return fromProfile;
    return _asString(_currentUser?.phoneNumber, fallback: 'Телефон жоқ');
  }

  String get _displayBio {
    return _asString(_profileData['bio']);
  }

  String get _avatarUrl {
    return _asString(_profileData['avatarUrl']);
  }

  String get _avatarLocalPath {
    return _asString(_profileData['avatarLocalPath']);
  }

  bool get _isPhoneLockedByAuth {
    final authPhone = _asString(_currentUser?.phoneNumber);
    return authPhone.isNotEmpty;
  }

  Map<String, dynamic> _buildGuestProfileSeed() {
    final initial = widget.userData;
    final seededName = _firstNonEmpty(<String?>[
      _asString(_profileData['fullName']),
      _asString(_profileData['name']),
      initial?.name,
    ], fallback: 'Қонақ');
    final seededPhone = _firstNonEmpty(<String?>[
      _asString(_profileData['phone']),
      initial?.phone,
    ], fallback: 'Телефон жоқ');
    final seededCity = _firstNonEmpty(<String?>[
      _asString(_profileData['city']),
      initial?.city,
    ], fallback: 'Қала таңдалмады');

    return <String, dynamic>{
      'name': seededName,
      'fullName': seededName,
      'phone': seededPhone,
      'city': seededCity,
      'address': _firstNonEmpty(<String?>[
        _asString(_profileData['address']),
        initial?.address,
      ]),
      'bio': _asString(_profileData['bio']),
      'showPhone': _asBool(_profileData['showPhone'], fallback: true),
      'showEmail': _asBool(_profileData['showEmail'], fallback: true),
      'showOnlineStatus': _asBool(
        _profileData['showOnlineStatus'],
        fallback: true,
      ),
      'notificationsPush': _asBool(
        _profileData['notificationsPush'],
        fallback: true,
      ),
      'notificationsEmail': _asBool(
        _profileData['notificationsEmail'],
        fallback: false,
      ),
      'appLanguage': _asString(_profileData['appLanguage'], fallback: 'kz'),
      'themeMode': _asString(_profileData['themeMode'], fallback: 'dark'),
      'favoriteWorkerIds': _asStringList(_profileData['favoriteWorkerIds']),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: AppLoadingIndicator(
            size: 28,
            strokeWidth: 2.5,
            color: AppColors.gold,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadProfile,
                    child: const Text('Қайта жүктеу'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final name = _displayName;
    final city = _displayCity;
    final phone = _displayPhone;
    final bio = _displayBio;
    final orderSummary = _buildOrderSummary();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    blurRadius: 120,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  120 + MediaQuery.of(context).padding.bottom,
                ),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Профиль', style: AppTypography.h2),
                      Row(
                        children: [
                          _roundIconButton(
                            icon: Icons.edit_outlined,
                            onTap: _openEditProfile,
                          ),
                          const SizedBox(width: 8),
                          _roundIconButton(
                            icon: CupertinoIcons.settings,
                            onTap: _openSettings,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClientIdentityHeaderCard(
                    name: name,
                    subtitle: phone,
                    city: city,
                    bio: bio,
                    avatarUrl: _avatarUrl,
                    avatarLocalPath: _avatarLocalPath,
                    onAvatarEdit: _pickAvatar,
                    avatarBusy: _isAvatarBusy,
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Байланыс',
                    child: Column(
                      children: [
                        _lineItem(
                          icon: CupertinoIcons.phone,
                          label: 'Телефон',
                          value:
                              _isVisible(
                                _profileData['showPhone'],
                                fallback: true,
                              )
                              ? phone
                              : 'Жасырылған',
                        ),
                        const SizedBox(height: 10),
                        _lineItem(
                          icon: CupertinoIcons.mail,
                          label: 'Email',
                          value:
                              _isVisible(
                                _profileData['showEmail'],
                                fallback: true,
                              )
                              ? _asString(
                                  _profileData['email'],
                                  fallback: 'Көрсетілмеген',
                                )
                              : 'Жасырылған',
                        ),
                        const SizedBox(height: 10),
                        _lineItem(
                          icon: CupertinoIcons.location_solid,
                          label: 'Сіздің мекен жайыңыз',
                          value: city,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Тапсырыстарым',
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyRequestScreen(),
                          ),
                        );
                      },
                      child: const Text('Барлығы'),
                    ),
                    child: _ordersLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: AppLoadingIndicator(
                                size: 22,
                                strokeWidth: 2.2,
                                color: AppColors.gold,
                              ),
                            ),
                          )
                        : _ordersError != null
                        ? _errorText(
                            _ordersError!,
                            onRetry: () {
                              final uid = _currentUser?.uid;
                              if (uid != null) {
                                _loadOrders(uid);
                              }
                            },
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _smallSummaryChip(
                                    label: 'Барлығы',
                                    value: orderSummary.total.toString(),
                                  ),
                                  _smallSummaryChip(
                                    label: 'Белсенді',
                                    value: orderSummary.active.toString(),
                                  ),
                                  _smallSummaryChip(
                                    label: 'Аяқталған',
                                    value: orderSummary.done.toString(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_orders.isEmpty)
                                const Text(
                                  'Әзірге тапсырыс жоқ.',
                                  style: AppTypography.caption,
                                )
                              else
                                ..._orders
                                    .take(3)
                                    .map((doc) => _orderTile(doc.data())),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Сақталған шеберлер',
                    trailing: TextButton(
                      onPressed: _favoritesLoading
                          ? null
                          : () => _loadFavorites(_profileData),
                      child: const Text('Жаңарту'),
                    ),
                    child: _favoritesLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: AppLoadingIndicator(
                                size: 22,
                                strokeWidth: 2.2,
                                color: AppColors.gold,
                              ),
                            ),
                          )
                        : _favoritesError != null
                        ? _errorText(
                            _favoritesError!,
                            onRetry: () => _loadFavorites(_profileData),
                          )
                        : _favoriteWorkers.isEmpty
                        ? const Text(
                            'Сақталған шеберлер жоқ.',
                            style: AppTypography.caption,
                          )
                        : Column(
                            children: _favoriteWorkers
                                .map((worker) => _favoriteWorkerTile(worker))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Төлем және биллинг',
                    child: _buildBillingSection(),
                  ),
                  const SizedBox(height: 16),
                  _settingsMenuCard(name: name),
                  const SizedBox(height: 16),
                  _dangerZoneCard(),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.14),
                child: const Center(
                  child: AppLoadingIndicator(
                    size: 24,
                    strokeWidth: 2.4,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _settingsMenuCard({required String name}) {
    return _sectionCard(
      title: 'Баптаулар',
      child: Column(
        children: [
          _menuGroupTitle('ACCOUNT'),
          _actionTile(
            icon: CupertinoIcons.person,
            title: 'Профильді өңдеу',
            subtitle: name,
            onTap: _openEditProfile,
          ),
          _actionTile(
            icon: CupertinoIcons.settings,
            title: 'Құпиялылық және көріну',
            subtitle: 'Телефон/email/online visibility',
            onTap: _openSettings,
          ),
          _actionTile(
            icon: CupertinoIcons.bell,
            title: 'Хабарлама баптаулары',
            subtitle: 'Push және email toggles',
            onTap: _openSettings,
          ),
          _actionTile(
            icon: CupertinoIcons.globe,
            title: 'Тіл',
            subtitle: _asString(_profileData['appLanguage'], fallback: 'kz'),
            onTap: _openSettings,
          ),
          _actionTile(
            icon: CupertinoIcons.moon,
            title: 'Тема',
            subtitle: _asString(_profileData['themeMode'], fallback: 'dark'),
            onTap: _openSettings,
          ),
          _actionTile(
            icon: CupertinoIcons.lock,
            title: 'Пароль өзгерту',
            subtitle: 'Email арқылы',
            onTap: _changePassword,
          ),
          const SizedBox(height: 6),
          _menuGroupTitle('ACTIVITY / DATA'),
          _actionTile(
            icon: CupertinoIcons.doc_text,
            title: 'Менің тапсырыстарым',
            subtitle: 'Барлық өтінімдер',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyRequestScreen()),
              );
            },
          ),
          _actionTile(
            icon: CupertinoIcons.heart,
            title: 'Favorites / Saved workers',
            subtitle: _favoriteWorkers.isEmpty
                ? 'Сақталғандар жоқ'
                : '${_favoriteWorkers.length} шебер сақталған',
            onTap: () {
              _showSnack(
                'Сақталған шеберлер тізімі осы беттегі "Сақталған шеберлер" бөлімінде.',
                isError: false,
              );
            },
          ),
          _actionTile(
            icon: CupertinoIcons.creditcard,
            title: 'Payment / Billing',
            subtitle: 'Backend дайын болғанда толық ашылады',
            onTap: () {
              _showSnack(
                'Төлем бөлімі әзірге preview режимде.',
                isError: false,
              );
            },
          ),
          const SizedBox(height: 6),
          _menuGroupTitle('SUPPORT'),
          _actionTile(
            icon: CupertinoIcons.question_circle,
            title: 'Help Center / FAQ',
            subtitle: 'Көмек орталығы',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientSupportScreen()),
              );
            },
          ),
          _actionTile(
            icon: CupertinoIcons.chat_bubble,
            title: 'Contact support',
            subtitle: 'support@kuryl.kz',
            onTap: _openSupportContacts,
          ),
          _actionTile(
            icon: CupertinoIcons.info,
            title: 'About app',
            subtitle: 'Version, terms, privacy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientAboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SECURITY',
            style: TextStyle(
              color: AppColors.danger,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _dangerActionTile(
            icon: Icons.logout,
            title: 'Шығу',
            subtitle: 'Сессияны аяқтау',
            onTap: _confirmLogout,
          ),
          const SizedBox(height: 8),
          _dangerActionTile(
            icon: Icons.delete_forever_outlined,
            title: 'Аккаунтты өшіру',
            subtitle: 'Қайтарылмайтын әрекет',
            onTap: _confirmDeleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _menuGroupTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 6),
        child: Text(
          title,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTypography.h3)),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _lineItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: AppTypography.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _smallSummaryChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _orderTile(Map<String, dynamic> map) {
    final category = _asString(
      map['categoryName'] ?? map['category'],
      fallback: 'Тапсырыс',
    );
    final description = _asString(
      map['description'],
      fallback: 'Сипаттама жоқ',
    );
    final status = _asString(map['status'], fallback: 'OPEN');
    final negotiable = _asBool(map['negotiable'], fallback: false);
    final budget = map['budgetPrice'] ?? map['price'];
    final parsedBudget = (budget is num)
        ? budget.toDouble()
        : double.tryParse('$budget');
    final price = negotiable || parsedBudget == null
        ? 'Келісімді'
        : '${parsedBudget.toStringAsFixed(0)} ₸';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyRequestScreen()),
        );
      },
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(category, style: AppTypography.caption)),
                Text(_statusLabel(status), style: AppTypography.caption),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(color: AppColors.gold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favoriteWorkerTile(WorkerModel worker) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WorkerDetailScreen(worker: worker)),
        );
      },
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: ClipOval(
                child: SafeNetworkImage(
                  url: worker.avatarUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(worker.name, style: AppTypography.body),
                  const SizedBox(height: 2),
                  Text(
                    '${worker.specialty} • ${worker.city}',
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: AppColors.gold),
                const SizedBox(width: 2),
                Text(
                  worker.rating.toStringAsFixed(1),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingSection() {
    final methods = _profileData['paymentMethods'];
    if (methods is List && methods.isNotEmpty) {
      return Column(
        children: methods
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _lineItem(
                  icon: CupertinoIcons.creditcard,
                  label: 'Карта',
                  value: item.toString(),
                ),
              ),
            )
            .toList()
            .cast<Widget>(),
      );
    }

    return const Text(
      'Төлем ақпараттары әлі қосылмаған. Payment backend дайын болғанда осы жерге қосылады.',
      style: AppTypography.caption,
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 6,
      visualDensity: const VisualDensity(vertical: 0),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Icon(icon, color: AppColors.gold, size: 18),
      ),
      title: Text(title, style: AppTypography.body),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: AppTypography.caption),
      trailing: const Icon(
        CupertinoIcons.chevron_right,
        color: AppColors.textMuted,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _dangerActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.danger, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }

  Widget _errorText(String text, {required VoidCallback onRetry}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(color: AppColors.danger, fontSize: 12),
        ),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('Қайта көру')),
      ],
    );
  }

  _OrderSummary _buildOrderSummary() {
    int active = 0;
    int done = 0;

    for (final doc in _orders) {
      final status = _asString(doc.data()['status']).toLowerCase();
      if (status == 'completed' ||
          status == 'done' ||
          status == 'finished' ||
          status == 'cancelled' ||
          status == 'canceled') {
        done += 1;
      } else {
        active += 1;
      }
    }

    return _OrderSummary(total: _orders.length, active: active, done: done);
  }

  String _statusLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'open':
      case 'pending':
        return 'OPEN';
      case 'in_progress':
      case 'active':
        return 'IN_PROGRESS';
      case 'done':
      case 'completed':
      case 'finished':
        return 'COMPLETED';
      case 'cancelled':
      case 'canceled':
        return 'CANCELLED';
      default:
        return raw.toUpperCase();
    }
  }

  bool _isVisible(dynamic raw, {required bool fallback}) {
    if (raw == null) return fallback;
    if (raw is bool) return raw;
    final text = raw.toString().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return fallback;
  }
}

class _OrderSummary {
  final int total;
  final int active;
  final int done;

  const _OrderSummary({
    required this.total,
    required this.active,
    required this.done,
  });
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

bool _asBool(dynamic value, {required bool fallback}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) return <String>[];
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  return <String>[];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, itemValue) => MapEntry(key.toString(), itemValue));
  }
  return <String, dynamic>{};
}

String _firstNonEmpty(List<String?> values, {String fallback = ''}) {
  for (final value in values) {
    final text = value?.trim() ?? '';
    if (text.isNotEmpty) {
      return text;
    }
  }
  return fallback;
}
