import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/services/auth_service.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/core/widgets/app_loading.dart';
import 'package:kuryl_kz/features/auth/services/role_selection_cache.dart';
import 'package:kuryl_kz/features/client/my_request/screens/my_requests_screen.dart';
import 'package:kuryl_kz/features/client/profile/screens/client_about_screen.dart';
import 'package:kuryl_kz/features/client/profile/screens/client_edit_profile_screen.dart';
import 'package:kuryl_kz/features/client/profile/screens/client_support_screen.dart';
import 'package:kuryl_kz/features/client/profile/widgets/client_identity_header_card.dart';

class ClientSettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfileData;

  const ClientSettingsScreen({super.key, this.initialProfileData});

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen> {
  final AuthService _authService = AuthService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool get _hasAuthorizedUser => _currentUser != null;

  Map<String, dynamic> _profileData = <String, dynamic>{};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialProfileData != null) {
      _profileData = Map<String, dynamic>.from(widget.initialProfileData!);
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _currentUser;
    if (user == null) {
      setState(() {
        _profileData = <String, dynamic>{
          ..._buildGuestProfileSeed(),
          ..._profileData,
        };
        _isLoading = false;
        _error = null;
      });
      return;
    }

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

      setState(() {
        _profileData = <String, dynamic>{..._profileData, ...map};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Баптаулар жүктелмеді: $e';
      });
    }
  }

  Future<void> _saveUpdates(Map<String, dynamic> updates) async {
    final previous = Map<String, dynamic>.from(_profileData);
    final next = <String, dynamic>{..._profileData, ...updates};

    setState(() {
      _isSaving = true;
      _profileData = next;
    });

    if (!_hasAuthorizedUser) {
      setState(() => _isSaving = false);
      return;
    }

    final result = await _authService.upsertClientProfile(userData: next);

    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _isSaving = false;
        _profileData = previous;
      });
      _snack(result.message);
      return;
    }

    setState(() => _isSaving = false);
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

    final name = _asString(result['name']);
    if (name.length < 2) {
      _snack('Аты-жөні кемінде 2 таңба болу керек.');
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

    await _saveUpdates(updates);
    if (!mounted) return;
    _snack('Профиль жаңартылды.', isError: false);
  }

  Future<void> _changePassword() async {
    final user = _currentUser;
    if (user == null) {
      _snack('Пароль өзгерту үшін аккаунтпен кіріңіз.');
      return;
    }

    if (user.email == null || user.email!.trim().isEmpty) {
      _snack('Email тіркелмеген аккаунтта пароль өзгерту қолжетімсіз.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: user.email!.trim(),
      );
      if (!mounted) return;
      _snack('Парольді өзгерту сілтемесі жіберілді.', isError: false);
    } catch (e) {
      _snack('Сілтеме жіберу қатесі: $e');
    }
  }

  Future<void> _selectLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Қазақша'),
                onTap: () => Navigator.pop(context, 'kz'),
              ),
              ListTile(
                title: const Text('Русский'),
                onTap: () => Navigator.pop(context, 'ru'),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    await _saveUpdates(<String, dynamic>{'appLanguage': selected});
    if (!mounted) return;
    _snack(
      'Тіл параметрі сақталды. Локализация толық қосылғаннан кейін автоматты қолданылады.',
      isError: false,
    );
  }

  Future<void> _toggleTheme() async {
    final current = _asString(_profileData['themeMode'], fallback: 'dark');
    final next = current == 'dark' ? 'light' : 'dark';
    await _saveUpdates(<String, dynamic>{'themeMode': next});
    if (!mounted) return;
    _snack(
      'Тема параметрі сақталды. Dynamic theme global интеграциясы TODO.',
      isError: false,
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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

    if (ok != true) return;

    RoleSelectionCache.instance.clear();
    if (_hasAuthorizedUser) {
      await _authService.signOut();
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await _showDeleteConfirmDialog();
    if (!mounted) return;
    if (confirmed != true) return;

    if (!_hasAuthorizedUser) {
      _snack(
        'Аккаунт backend-де табылмады. Локалды сессия жабылды.',
        isError: false,
      );
      RoleSelectionCache.instance.clear();
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() => _isSaving = true);
    final result = await _authService.deleteClientAccount();
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      RoleSelectionCache.instance.clear();
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    _snack(result.message);
    RoleSelectionCache.instance.clear();
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<bool?> _showDeleteConfirmDialog() {
    final ctrl = TextEditingController();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canDelete = ctrl.text.trim().toUpperCase() == 'DELETE';
            return AlertDialog(
              title: const Text('Аккаунтты өшіру'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Жалғастыру үшін DELETE деп жазыңыз.'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ctrl,
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
                  onPressed: canDelete
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
    ).whenComplete(ctrl.dispose);
  }

  void _openSupportContacts() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Contact support'),
        content: const Text('support@kuryl.kz\nЖұмыс уақыты: 09:00 - 18:00'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Жабу'),
          ),
        ],
      ),
    );
  }

  void _snack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  bool get _isPhoneLockedByAuth {
    final authPhone = _asString(_currentUser?.phoneNumber);
    return authPhone.isNotEmpty;
  }

  String get _displayName {
    final full = _asString(_profileData['fullName']);
    if (full.isNotEmpty) return full;
    return _asString(_profileData['name'], fallback: 'Қонақ');
  }

  String get _displayPhone {
    final fromProfile = _asString(_profileData['phone']);
    if (fromProfile.isNotEmpty) return fromProfile;
    return _asString(_currentUser?.phoneNumber, fallback: 'Телефон жоқ');
  }

  Map<String, dynamic> _buildGuestProfileSeed() {
    final seededName = _firstNonEmpty(<String?>[
      _asString(_profileData['fullName']),
      _asString(_profileData['name']),
    ], fallback: 'Қонақ');
    return <String, dynamic>{
      'name': seededName,
      'fullName': seededName,
      'phone': _asString(_profileData['phone'], fallback: 'Телефон жоқ'),
      'city': _asString(_profileData['city'], fallback: 'Қала көрсетілмеген'),
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
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: AppLoadingIndicator(
            size: 26,
            strokeWidth: 2.3,
            color: AppColors.gold,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          leading: appBarBackButton(context),
          title: const Text('Баптаулар'),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
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

    final showPhone = _asBool(_profileData['showPhone'], fallback: true);
    final showEmail = _asBool(_profileData['showEmail'], fallback: true);
    final showOnline = _asBool(
      _profileData['showOnlineStatus'],
      fallback: true,
    );
    final pushEnabled = _asBool(
      _profileData['notificationsPush'],
      fallback: true,
    );
    final emailEnabled = _asBool(
      _profileData['notificationsEmail'],
      fallback: false,
    );
    final language = _asString(_profileData['appLanguage'], fallback: 'kz');
    final themeMode = _asString(_profileData['themeMode'], fallback: 'dark');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: appBarBackButton(context),
        title: const Text('Баптаулар'),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                20 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClientIdentityHeaderCard(
                    name: _displayName,
                    subtitle: _displayPhone,
                    city: _asString(
                      _profileData['city'],
                      fallback: 'Қала көрсетілмеген',
                    ),
                    bio: _asString(_profileData['bio']),
                    avatarUrl: _asString(_profileData['avatarUrl']),
                    avatarLocalPath: _asString(_profileData['avatarLocalPath']),
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    title: 'ACCOUNT',
                    children: [
                      _SettingsActionTile(
                        icon: CupertinoIcons.person,
                        title: 'Edit profile',
                        subtitle: 'Аты-жөні, қала, био',
                        onTap: _openEditProfile,
                      ),
                      _SettingsActionTile(
                        icon: CupertinoIcons.lock,
                        title: 'Change password',
                        subtitle: 'Email reset link',
                        onTap: _changePassword,
                      ),
                      _SettingsSwitchTile(
                        icon: CupertinoIcons.phone,
                        title: 'Show phone',
                        value: showPhone,
                        onChanged: (v) =>
                            _saveUpdates(<String, dynamic>{'showPhone': v}),
                      ),
                      _SettingsSwitchTile(
                        icon: CupertinoIcons.mail,
                        title: 'Show email',
                        value: showEmail,
                        onChanged: (v) =>
                            _saveUpdates(<String, dynamic>{'showEmail': v}),
                      ),
                      _SettingsSwitchTile(
                        icon: CupertinoIcons.dot_radiowaves_left_right,
                        title: 'Show online status',
                        value: showOnline,
                        onChanged: (v) => _saveUpdates(<String, dynamic>{
                          'showOnlineStatus': v,
                        }),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    title: 'NOTIFICATIONS',
                    children: [
                      _SettingsSwitchTile(
                        icon: CupertinoIcons.bell,
                        title: 'Push notifications',
                        value: pushEnabled,
                        onChanged: (v) => _saveUpdates(<String, dynamic>{
                          'notificationsPush': v,
                        }),
                      ),
                      _SettingsSwitchTile(
                        icon: CupertinoIcons.mail_solid,
                        title: 'Email notifications',
                        value: emailEnabled,
                        onChanged: (v) => _saveUpdates(<String, dynamic>{
                          'notificationsEmail': v,
                        }),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    title: 'PREFERENCES',
                    children: [
                      _SettingsActionTile(
                        icon: CupertinoIcons.globe,
                        title: 'Language',
                        subtitle: language,
                        onTap: _selectLanguage,
                      ),
                      _SettingsActionTile(
                        icon: CupertinoIcons.moon,
                        title: 'Theme',
                        subtitle: themeMode,
                        onTap: _toggleTheme,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    title: 'ACTIVITY / DATA',
                    children: [
                      _SettingsActionTile(
                        icon: CupertinoIcons.doc_text,
                        title: 'My orders / requests',
                        subtitle: 'Өтінімдер тізімі',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyRequestScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingsActionTile(
                        icon: CupertinoIcons.heart,
                        title: 'Favorites / saved workers',
                        subtitle: 'Профильдегі сақталғандар бөлімінде',
                        onTap: () => _snack(
                          'Сақталған шеберлерді профиль бетінен көре аласыз.',
                          isError: false,
                        ),
                      ),
                      _SettingsActionTile(
                        icon: CupertinoIcons.creditcard,
                        title: 'Payment / billing',
                        subtitle: 'TODO: billing backend integration',
                        onTap: () => _snack(
                          'Төлем интеграциясы әзірге қолжетімсіз.',
                          isError: false,
                        ),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    title: 'SUPPORT',
                    children: [
                      _SettingsActionTile(
                        icon: CupertinoIcons.question_circle,
                        title: 'Help Center / FAQ',
                        subtitle: 'Көмек орталығы',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ClientSupportScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingsActionTile(
                        icon: CupertinoIcons.chat_bubble,
                        title: 'Contact support',
                        subtitle: 'support@kuryl.kz',
                        onTap: _openSupportContacts,
                      ),
                      _SettingsActionTile(
                        icon: CupertinoIcons.info,
                        title: 'About app',
                        subtitle: 'Version, terms, privacy',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ClientAboutScreen(),
                            ),
                          );
                        },
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    title: 'SECURITY',
                    borderColor: AppColors.danger.withValues(alpha: 0.35),
                    children: [
                      _SettingsActionTile(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Сессияны аяқтау',
                        onTap: _confirmLogout,
                        color: AppColors.danger,
                      ),
                      _SettingsActionTile(
                        icon: Icons.delete_forever_outlined,
                        title: 'Delete account',
                        subtitle: 'Type DELETE confirmation',
                        onTap: _confirmDeleteAccount,
                        color: AppColors.danger,
                        isLast: true,
                      ),
                    ],
                  ),
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
                    strokeWidth: 2.2,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color borderColor;

  const _SettingsCard({
    required this.title,
    required this.children,
    this.borderColor = AppColors.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Text(
              title,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;
  final Color color;

  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
    this.color = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 18, color: AppColors.gold),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: AppTypography.body)),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.gold,
            activeTrackColor: AppColors.gold.withValues(alpha: 0.45),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
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

String _firstNonEmpty(List<String?> values, {String fallback = ''}) {
  for (final value in values) {
    final text = value?.trim() ?? '';
    if (text.isNotEmpty) {
      return text;
    }
  }
  return fallback;
}
