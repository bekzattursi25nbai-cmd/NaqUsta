import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/core/widgets/app_loading.dart';
import 'package:kuryl_kz/core/widgets/safe_button_text.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';
import 'package:kuryl_kz/features/auth/services/role_selection_cache.dart';
import 'package:kuryl_kz/features/categories/data/category_repository.dart';
import 'package:kuryl_kz/features/categories/ui/category_picker.dart';
import 'package:kuryl_kz/features/categories/utils/category_locale.dart';
import 'package:kuryl_kz/features/worker/profile/models/worker_profile_data.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'worker_settings_screen.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final CategoryRepository _categoryRepository = CategoryRepository.instance;

  Map<String, dynamic> _rawData = <String, dynamic>{};
  WorkerProfileData? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _categoryRepository.init().then((_) {
      if (mounted) setState(() {});
    });
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final currentUser = _currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = 'Қолданушы табылмады.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(currentUser.uid)
          .get();

      final fetched = userDoc.data() ?? _seedDataFromAuth();

      setState(() {
        _rawData = Map<String, dynamic>.from(fetched);
        _profile = WorkerProfileData.fromMap(_rawData, currentUser.uid);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Профиль жүктеу қатесі: $e';
      });
    }
  }

  Map<String, dynamic> _seedDataFromAuth() {
    final user = _currentUser;
    if (user == null) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{
      'fullName': user.displayName ?? 'Шебер',
      'email': user.email ?? '',
      'phone': user.phoneNumber ?? '',
      'specialty': 'Маман',
      'city': 'Қала көрсетілмеген',
      'about': '',
      'experience': '1 жыл',
      'rating': 5.0,
      'completedOrders': 0,
      'reviewCount': 0,
      'showPhone': false,
      'showEmail': false,
      'isPromoted': true,
      'primaryCategoryIds': <String>[],
      'canDoCategoryIds': <String>[],
      'skills': <String>[],
      'services': <Map<String, dynamic>>[],
      'portfolio': <Map<String, dynamic>>[],
      'experiences': <Map<String, dynamic>>[],
      'educations': <Map<String, dynamic>>[],
      'certificates': <Map<String, dynamic>>[],
      'reviews': <Map<String, dynamic>>[],
      'availabilityStatus': 'available',
      'availabilitySlots': <String>[],
      'hourlyRate': 'Келісім бойынша',
    };
  }

  Future<void> _saveUpdates(
    Map<String, dynamic> updates, {
    String? successMessage,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    final previous = Map<String, dynamic>.from(_rawData);
    final next = Map<String, dynamic>.from(_rawData)..addAll(updates);

    setState(() {
      _isSaving = true;
      _rawData = next;
      _profile = WorkerProfileData.fromMap(_rawData, user.uid);
    });

    try {
      await FirebaseFirestore.instance.collection('workers').doc(user.uid).set(
        <String, dynamic>{
          ...updates,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      if (successMessage != null && successMessage.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      setState(() {
        _rawData = previous;
        _profile = WorkerProfileData.fromMap(_rawData, user.uid);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Сақтау қатесі: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _togglePromotion(bool value) {
    return _saveUpdates(
      <String, dynamic>{'isPromoted': value},
      successMessage: value
          ? 'Сіз енді клиенттерге жарнамаланасыз.'
          : 'Жарнамалау өшірілді.',
    );
  }

  Future<void> _editBasicInfo() async {
    final profile = _profile;
    if (profile == null) return;

    final result = await _showFormDialog(
      title: 'Профильді өзгерту',
      fields: const <_EditorField>[
        _EditorField(key: 'fullName', label: 'Аты-жөні'),
        _EditorField(key: 'specialty', label: 'Мамандық'),
        _EditorField(key: 'city', label: 'Қала'),
        _EditorField(key: 'hourlyRate', label: 'Баға / ставка'),
        _EditorField(key: 'bio', label: 'Қысқаша био', maxLines: 3),
      ],
      initialValues: <String, String>{
        'fullName': profile.fullName,
        'specialty': profile.specialty,
        'city': profile.city,
        'hourlyRate': profile.hourlyRate,
        'bio': profile.bio,
      },
    );

    if (result == null) return;

    final name = result['fullName']?.trim() ?? '';
    if (name.length < 2) {
      _showSnack('Аты-жөні кемінде 2 таңба болу керек.');
      return;
    }

    await _saveUpdates(<String, dynamic>{
      'fullName': name,
      'specialty': result['specialty']?.trim() ?? '',
      'city': result['city']?.trim() ?? '',
      'hourlyRate': result['hourlyRate']?.trim() ?? '',
      'about': result['bio']?.trim() ?? '',
    }, successMessage: 'Негізгі ақпарат сақталды.');
  }

  String _categoryLabel(String categoryId) {
    if (!_categoryRepository.isInitialized) return categoryId;
    final node = _categoryRepository.byId[categoryId];
    if (node == null) return categoryId;
    final localeCode = resolveCategoryLocaleCode(
      Localizations.localeOf(context),
    );
    return node.localizedName(localeCode);
  }

  List<String> _dedupe(List<String> values) {
    return values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _persistWorkerCategories({
    required List<String> primaryIds,
    required List<String> canDoIds,
    String? successMessage,
  }) async {
    await _categoryRepository.init();
    final normalizedPrimary = _dedupe(primaryIds).take(3).toList();
    final normalizedCanDo = _dedupe(
      canDoIds,
    ).where((id) => !normalizedPrimary.contains(id)).take(20).toList();
    final primaryLabels = normalizedPrimary.map(_categoryLabel).toList();

    await _saveUpdates(<String, dynamic>{
      'primaryCategoryIds': normalizedPrimary,
      'canDoCategoryIds': normalizedCanDo,
      'categories': <String>{...normalizedPrimary, ...normalizedCanDo}.toList(),
      'specialties': primaryLabels,
      'skills': primaryLabels,
      'tags': primaryLabels,
      if (primaryLabels.isNotEmpty) 'specialty': primaryLabels.first,
    }, successMessage: successMessage);
  }

  Future<void> _editPrimaryCategories() async {
    final profile = _profile;
    if (profile == null) return;
    await _categoryRepository.init();
    if (!mounted) return;

    final picked = await CategoryPicker.pickMultiLeaf(
      context: context,
      title: 'Негізгі мамандықтар',
      role: CategoryPickerRole.worker,
      selectionLimit: 3,
      initialLeafIds: profile.primaryCategoryIds,
      repository: _categoryRepository,
    );
    if (picked == null) return;

    await _persistWorkerCategories(
      primaryIds: picked,
      canDoIds: profile.canDoCategoryIds,
      successMessage: 'Негізгі категориялар жаңартылды.',
    );
  }

  Future<void> _editCanDoCategories() async {
    final profile = _profile;
    if (profile == null) return;
    await _categoryRepository.init();
    if (!mounted) return;

    final picked = await CategoryPicker.pickMultiLeaf(
      context: context,
      title: 'Қосымша дағдылар',
      role: CategoryPickerRole.worker,
      selectionLimit: 20,
      initialLeafIds: profile.canDoCategoryIds,
      repository: _categoryRepository,
    );
    if (picked == null) return;

    await _persistWorkerCategories(
      primaryIds: profile.primaryCategoryIds,
      canDoIds: picked,
      successMessage: 'Қосымша категориялар жаңартылды.',
    );
  }

  Future<void> _removePrimaryCategory(String categoryId) async {
    final profile = _profile;
    if (profile == null) return;
    final next = List<String>.from(profile.primaryCategoryIds)
      ..remove(categoryId);
    await _persistWorkerCategories(
      primaryIds: next,
      canDoIds: profile.canDoCategoryIds,
      successMessage: 'Категория өшірілді.',
    );
  }

  Future<void> _removeCanDoCategory(String categoryId) async {
    final profile = _profile;
    if (profile == null) return;
    final next = List<String>.from(profile.canDoCategoryIds)
      ..remove(categoryId);
    await _persistWorkerCategories(
      primaryIds: profile.primaryCategoryIds,
      canDoIds: next,
      successMessage: 'Категория өшірілді.',
    );
  }

  Future<void> _editSkills() async {
    final value = await _showSingleInputDialog(
      title: 'Дағды қосу',
      label: 'Дағды атауы',
    );

    if (value == null || value.trim().isEmpty) return;

    final profile = _profile;
    if (profile == null) return;

    final next = <String>{...profile.skills, value.trim()}.toList();
    await _saveUpdates(<String, dynamic>{
      'skills': next,
    }, successMessage: 'Дағды қосылды.');
  }

  Future<void> _renameSkill(int index) async {
    final profile = _profile;
    if (profile == null || index >= profile.skills.length) return;

    final current = profile.skills[index];
    final nextValue = await _showSingleInputDialog(
      title: 'Дағдыны өзгерту',
      label: 'Дағды атауы',
      initialValue: current,
    );

    if (nextValue == null || nextValue.trim().isEmpty) return;

    final next = List<String>.from(profile.skills);
    next[index] = nextValue.trim();

    await _saveUpdates(<String, dynamic>{
      'skills': next.toSet().toList(),
    }, successMessage: 'Дағды жаңартылды.');
  }

  Future<void> _removeSkill(int index) async {
    final profile = _profile;
    if (profile == null || index >= profile.skills.length) return;

    final next = List<String>.from(profile.skills)..removeAt(index);
    await _saveUpdates(<String, dynamic>{
      'skills': next,
    }, successMessage: 'Дағды өшірілді.');
  }

  Future<void> _editPortfolioItem({int? index}) async {
    final profile = _profile;
    if (profile == null) return;

    final item = (index != null && index < profile.portfolio.length)
        ? profile.portfolio[index]
        : null;

    final result = await _showFormDialog(
      title: index == null ? 'Портфолио қосу' : 'Портфолионы өзгерту',
      fields: const <_EditorField>[
        _EditorField(key: 'title', label: 'Жоба атауы'),
        _EditorField(key: 'description', label: 'Сипаттама', maxLines: 3),
        _EditorField(
          key: 'images',
          label: 'Сурет сілтемелері (үтірмен)',
          maxLines: 2,
        ),
      ],
      initialValues: <String, String>{
        'title': item?.title ?? '',
        'description': item?.description ?? '',
        'images': item?.images.join(', ') ?? '',
      },
    );

    if (result == null) return;

    final title = result['title']?.trim() ?? '';
    if (title.isEmpty) {
      _showSnack('Жоба атауы бос болмауы керек.');
      return;
    }

    final images = (result['images'] ?? '')
        .split(RegExp(r'[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final entry = WorkerPortfolioItem(
      title: title,
      description: result['description']?.trim() ?? '',
      images: images,
    );

    final next = List<WorkerPortfolioItem>.from(profile.portfolio);
    if (index != null && index < next.length) {
      next[index] = entry;
    } else {
      next.add(entry);
    }

    await _saveUpdates(<String, dynamic>{
      'portfolio': next.map((e) => e.toMap()).toList(),
    }, successMessage: 'Портфолио жаңартылды.');
  }

  Future<void> _removePortfolioItem(int index) async {
    final profile = _profile;
    if (profile == null || index >= profile.portfolio.length) return;

    final next = List<WorkerPortfolioItem>.from(profile.portfolio)
      ..removeAt(index);
    await _saveUpdates(<String, dynamic>{
      'portfolio': next.map((e) => e.toMap()).toList(),
    }, successMessage: 'Портфолио жобасы өшірілді.');
  }

  Future<void> _editExperience({int? index}) async {
    final profile = _profile;
    if (profile == null) return;

    final item = (index != null && index < profile.experiences.length)
        ? profile.experiences[index]
        : null;

    final result = await _showFormDialog(
      title: index == null ? 'Тәжірибе қосу' : 'Тәжірибені өзгерту',
      fields: const <_EditorField>[
        _EditorField(key: 'company', label: 'Компания'),
        _EditorField(key: 'role', label: 'Қызмет/роль'),
        _EditorField(key: 'years', label: 'Жылдар'),
        _EditorField(key: 'description', label: 'Сипаттама', maxLines: 2),
      ],
      initialValues: <String, String>{
        'company': item?.company ?? '',
        'role': item?.role ?? '',
        'years': item?.years ?? '',
        'description': item?.description ?? '',
      },
    );

    if (result == null) return;

    final company = result['company']?.trim() ?? '';
    if (company.isEmpty) {
      _showSnack('Компания атауын толтырыңыз.');
      return;
    }

    final entry = WorkerExperienceItem(
      company: company,
      role: result['role']?.trim() ?? '',
      years: result['years']?.trim() ?? '',
      description: result['description']?.trim() ?? '',
    );

    final next = List<WorkerExperienceItem>.from(profile.experiences);
    if (index != null && index < next.length) {
      next[index] = entry;
    } else {
      next.add(entry);
    }

    await _saveUpdates(<String, dynamic>{
      'experiences': next.map((e) => e.toMap()).toList(),
    }, successMessage: 'Тәжірибе сақталды.');
  }

  Future<void> _removeExperience(int index) async {
    final profile = _profile;
    if (profile == null || index >= profile.experiences.length) return;

    final next = List<WorkerExperienceItem>.from(profile.experiences)
      ..removeAt(index);
    await _saveUpdates(<String, dynamic>{
      'experiences': next.map((e) => e.toMap()).toList(),
    }, successMessage: 'Тәжірибе өшірілді.');
  }

  Future<void> _editEducation({int? index}) async {
    final profile = _profile;
    if (profile == null) return;

    final item = (index != null && index < profile.educations.length)
        ? profile.educations[index]
        : null;

    final result = await _showFormDialog(
      title: index == null ? 'Білім қосу' : 'Білімді өзгерту',
      fields: const <_EditorField>[
        _EditorField(key: 'institution', label: 'Оқу орны'),
        _EditorField(key: 'degree', label: 'Мамандық/дәрежe'),
        _EditorField(key: 'years', label: 'Жылдар'),
        _EditorField(key: 'description', label: 'Сипаттама', maxLines: 2),
      ],
      initialValues: <String, String>{
        'institution': item?.institution ?? '',
        'degree': item?.degree ?? '',
        'years': item?.years ?? '',
        'description': item?.description ?? '',
      },
    );

    if (result == null) return;

    final institution = result['institution']?.trim() ?? '';
    if (institution.isEmpty) {
      _showSnack('Оқу орнын толтырыңыз.');
      return;
    }

    final entry = WorkerEducationItem(
      institution: institution,
      degree: result['degree']?.trim() ?? '',
      years: result['years']?.trim() ?? '',
      description: result['description']?.trim() ?? '',
    );

    final next = List<WorkerEducationItem>.from(profile.educations);
    if (index != null && index < next.length) {
      next[index] = entry;
    } else {
      next.add(entry);
    }

    await _saveUpdates(<String, dynamic>{
      'educations': next.map((e) => e.toMap()).toList(),
    }, successMessage: 'Білім бөлімі сақталды.');
  }

  Future<void> _removeEducation(int index) async {
    final profile = _profile;
    if (profile == null || index >= profile.educations.length) return;

    final next = List<WorkerEducationItem>.from(profile.educations)
      ..removeAt(index);
    await _saveUpdates(<String, dynamic>{
      'educations': next.map((e) => e.toMap()).toList(),
    }, successMessage: 'Білім жазбасы өшірілді.');
  }

  Future<void> _editCertificate({int? index}) async {
    final profile = _profile;
    if (profile == null) return;

    final item = (index != null && index < profile.certificates.length)
        ? profile.certificates[index]
        : null;

    final result = await _showFormDialog(
      title: index == null ? 'Сертификат қосу' : 'Сертификатты өзгерту',
      fields: const <_EditorField>[
        _EditorField(key: 'title', label: 'Атауы'),
        _EditorField(key: 'issuer', label: 'Ұйым/беруші'),
        _EditorField(key: 'year', label: 'Жылы'),
        _EditorField(key: 'description', label: 'Ескертпе', maxLines: 2),
      ],
      initialValues: <String, String>{
        'title': item?.title ?? '',
        'issuer': item?.issuer ?? '',
        'year': item?.year ?? '',
        'description': item?.description ?? '',
      },
    );

    if (result == null) return;

    final title = result['title']?.trim() ?? '';
    if (title.isEmpty) {
      _showSnack('Сертификат атауын толтырыңыз.');
      return;
    }

    final entry = WorkerCertificateItem(
      title: title,
      issuer: result['issuer']?.trim() ?? '',
      year: result['year']?.trim() ?? '',
      description: result['description']?.trim() ?? '',
    );

    final next = List<WorkerCertificateItem>.from(profile.certificates);
    if (index != null && index < next.length) {
      next[index] = entry;
    } else {
      next.add(entry);
    }

    await _saveUpdates(<String, dynamic>{
      'certificates': next.map((e) => e.toMap()).toList(),
    }, successMessage: 'Сертификат бөлімі сақталды.');
  }

  Future<void> _removeCertificate(int index) async {
    final profile = _profile;
    if (profile == null || index >= profile.certificates.length) return;

    final next = List<WorkerCertificateItem>.from(profile.certificates)
      ..removeAt(index);
    await _saveUpdates(<String, dynamic>{
      'certificates': next.map((e) => e.toMap()).toList(),
    }, successMessage: 'Сертификат өшірілді.');
  }

  Future<void> _editService({int? index}) async {
    final profile = _profile;
    if (profile == null) return;

    final item = (index != null && index < profile.services.length)
        ? profile.services[index]
        : null;

    final result = await _showFormDialog(
      title: index == null ? 'Қызмет қосу' : 'Қызметті өзгерту',
      fields: const <_EditorField>[
        _EditorField(key: 'name', label: 'Қызмет атауы'),
        _EditorField(key: 'description', label: 'Сипаттама', maxLines: 2),
        _EditorField(key: 'rate', label: 'Баға/ставка'),
      ],
      initialValues: <String, String>{
        'name': item?.name ?? '',
        'description': item?.description ?? '',
        'rate': item?.rate ?? '',
      },
    );

    if (result == null) return;

    final name = result['name']?.trim() ?? '';
    if (name.isEmpty) {
      _showSnack('Қызмет атауын толтырыңыз.');
      return;
    }

    final entry = WorkerServiceItem(
      name: name,
      description: result['description']?.trim() ?? '',
      rate: result['rate']?.trim() ?? '',
    );

    final next = List<WorkerServiceItem>.from(profile.services);
    if (index != null && index < next.length) {
      next[index] = entry;
    } else {
      next.add(entry);
    }

    await _saveUpdates(<String, dynamic>{
      'services': next.map((e) => e.toMap()).toList(),
    }, successMessage: 'Қызмет бөлімі сақталды.');
  }

  Future<void> _removeService(int index) async {
    final profile = _profile;
    if (profile == null || index >= profile.services.length) return;

    final next = List<WorkerServiceItem>.from(profile.services)
      ..removeAt(index);
    await _saveUpdates(<String, dynamic>{
      'services': next.map((e) => e.toMap()).toList(),
    }, successMessage: 'Қызмет өшірілді.');
  }

  Future<void> _addAvailabilitySlot() async {
    final profile = _profile;
    if (profile == null) return;

    final value = await _showSingleInputDialog(
      title: 'Уақыт қосу',
      label: 'Мысалы: Дс-Жм 09:00-18:00',
    );

    if (value == null || value.trim().isEmpty) return;

    final next = <String>{...profile.availabilitySlots, value.trim()}.toList();
    await _saveUpdates(<String, dynamic>{
      'availabilitySlots': next,
    }, successMessage: 'Кесте жаңартылды.');
  }

  Future<void> _removeAvailabilitySlot(int index) async {
    final profile = _profile;
    if (profile == null || index >= profile.availabilitySlots.length) return;

    final next = List<String>.from(profile.availabilitySlots)..removeAt(index);
    await _saveUpdates(<String, dynamic>{
      'availabilitySlots': next,
    }, successMessage: 'Уақыт слоты өшірілді.');
  }

  Future<void> _updateAvailabilityStatus(String status) async {
    await _saveUpdates(<String, dynamic>{
      'availabilityStatus': status,
    }, successMessage: 'Қолжетімділік статусы сақталды.');
  }

  Future<void> _updateContactVisibility({bool? showPhone, bool? showEmail}) {
    return _saveUpdates(<String, dynamic>{
      if (showPhone != null) 'showPhone': showPhone,
      if (showEmail != null) 'showEmail': showEmail,
    }, successMessage: 'Байланыс баптаулары сақталды.');
  }

  Future<void> _changePassword() async {
    final user = _currentUser;
    if (user == null) return;

    if (user.email == null || user.email!.trim().isEmpty) {
      _showSnack(
        'Email тіркелмеген, парольді осы аккаунт үшін өзгерту мүмкін емес.',
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: user.email!.trim(),
      );
      if (!mounted) return;
      _showSnack(
        'Парольді өзгерту сілтемесі email-ге жіберілді.',
        isError: false,
      );
    } catch (e) {
      _showSnack('Сілтеме жіберу қатесі: $e');
    }
  }

  Future<void> _deleteAccount() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .delete();
      await user.delete();

      if (!mounted) return;
      RoleSelectionCache.instance.clear();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Өшіру қатесі: $e');
    }
  }

  void _showDeleteConfirmDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Өшіру'),
        content: const Text('Аккаунтты толық өшіресіз бе?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const SafeButtonText('Бас тарту'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const SafeButtonText(
              'Өшіру',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Шығу'),
        content: const Text('Аккаунттан шығасыз ба?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const SafeButtonText('Жоқ'),
          ),
          ElevatedButton(
            onPressed: () async {
              RoleSelectionCache.instance.clear();
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const SafeButtonText('Иә'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showSingleInputDialog({
    required String title,
    required String label,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Бас тарту'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Сақтау'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<Map<String, String>?> _showFormDialog({
    required String title,
    required List<_EditorField> fields,
    required Map<String, String> initialValues,
  }) async {
    final controllers = <String, TextEditingController>{
      for (final field in fields)
        field.key: TextEditingController(text: initialValues[field.key] ?? ''),
    };

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final field in fields) ...[
                    TextField(
                      controller: controllers[field.key],
                      maxLines: field.maxLines,
                      decoration: InputDecoration(labelText: field.label),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Бас тарту'),
            ),
            ElevatedButton(
              onPressed: () {
                final values = <String, String>{
                  for (final field in fields)
                    field.key: controllers[field.key]?.text ?? '',
                };
                Navigator.pop(context, values);
              },
              child: const Text('Сақтау'),
            ),
          ],
        );
      },
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }
    return result;
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        body: Center(
          child: AppLoadingIndicator(
            size: 28,
            strokeWidth: 2.5,
            color: Colors.black,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: appBarBackButton(context),
          title: const Text(
            'Менің аккаунтым',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.red),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _fetchUserData,
                  child: const Text('Қайта жүктеу'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: appBarBackButton(context),
        title: const Text(
          'Менің аккаунтым',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.settings, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkerSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchUserData,
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
                _buildHeader(profile),
                const SizedBox(height: 16),
                _buildPromotionCard(profile),
                const SizedBox(height: 16),
                _buildStatisticsCard(profile),
                const SizedBox(height: 16),
                _buildContactSection(profile),
                const SizedBox(height: 16),
                _buildCategorySpecializationSection(profile),
                const SizedBox(height: 16),
                _buildSkillsSection(profile),
                const SizedBox(height: 16),
                _buildServicesSection(profile),
                const SizedBox(height: 16),
                _buildPortfolioSection(profile),
                const SizedBox(height: 16),
                _buildExperienceSection(profile),
                const SizedBox(height: 16),
                _buildEducationSection(profile),
                const SizedBox(height: 16),
                _buildCertificatesSection(profile),
                const SizedBox(height: 16),
                _buildAvailabilitySection(profile),
                const SizedBox(height: 16),
                _buildReviewsSection(profile),
                const SizedBox(height: 16),
                _buildActionsSection(),
                const SizedBox(height: 16),
                _buildLogoutButton(),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _showDeleteConfirmDialog,
                  child: SafeButtonText(
                    'Аккаунтты өшіру',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (_isSaving)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.08),
                child: const Center(
                  child: AppLoadingIndicator(
                    size: 26,
                    strokeWidth: 2.4,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(WorkerProfileData profile) {
    final avatarUrl = profile.avatarUrl.trim();
    final hasAvatar = avatarUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: ClipOval(
                  child: hasAvatar
                      ? SafeNetworkImage(url: avatarUrl, fit: BoxFit.cover)
                      : const Icon(Icons.person, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.specialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 13,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            profile.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (profile.isPromoted) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFD700)),
                        ),
                        child: const Text(
                          'PRO Аккаунт',
                          style: TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (profile.bio.isEmpty)
            Text(
              'Профиль био әлі толтырылмаған.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            )
          else
            Text(
              profile.bio,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _editBasicInfo,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Өзгерту'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(WorkerProfileData profile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: profile.isPromoted
              ? [Colors.blue.shade600, Colors.blue.shade400]
              : [Colors.white, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: profile.isPromoted
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.megaphone,
              color: profile.isPromoted ? Colors.white : Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Мені жарнамалау',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: profile.isPromoted ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  profile.isPromoted
                      ? 'Сіз клиенттерге көрініп тұрсыз.'
                      : 'Тапсырыс алу үшін функцияны қосыңыз.',
                  style: TextStyle(
                    fontSize: 12,
                    color: profile.isPromoted ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: profile.isPromoted, onChanged: _togglePromotion),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(WorkerProfileData profile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(
            profile.rating.toStringAsFixed(1),
            'Рейтинг',
            Icons.star,
            Colors.amber,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _statItem(
            profile.completedOrders.toString(),
            'Жұмыс',
            LucideIcons.briefcase,
            Colors.white,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _statItem(
            profile.experience,
            'Тәжірибе',
            LucideIcons.clock,
            Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildContactSection(WorkerProfileData profile) {
    return _sectionCard(
      title: 'Байланыс және көріну',
      subtitle: 'Клиентке қандай контакт ашық болатынын таңдаңыз.',
      child: Column(
        children: [
          _contactRow(
            icon: Icons.phone_outlined,
            label: 'Телефон',
            value: profile.phone.isEmpty
                ? 'Көрсетілмеген'
                : (profile.showPhone
                      ? profile.phone
                      : _maskPhone(profile.phone)),
            trailing: Switch(
              value: profile.showPhone,
              onChanged: (value) => _updateContactVisibility(showPhone: value),
            ),
          ),
          const Divider(height: 16),
          _contactRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: profile.email.isEmpty
                ? 'Көрсетілмеген'
                : (profile.showEmail ? profile.email : 'hidden@***'),
            trailing: Switch(
              value: profile.showEmail,
              onChanged: (value) => _updateContactVisibility(showEmail: value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.black87, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildCategorySpecializationSection(WorkerProfileData profile) {
    return _sectionCard(
      title: 'Категориялар',
      subtitle: 'Негізгі (max 3) және Қосымша (max 20).',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Негізгі мамандықтар',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: _editPrimaryCategories,
                child: const Text('Басқару'),
              ),
            ],
          ),
          if (profile.primaryCategoryIds.isEmpty)
            _emptyHint('Негізгі категория таңдалмаған.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.primaryCategoryIds
                  .map(
                    (id) => InputChip(
                      label: Text(_categoryLabel(id)),
                      onDeleted: () => _removePrimaryCategory(id),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Қосымша дағдылар',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: _editCanDoCategories,
                child: const Text('Басқару'),
              ),
            ],
          ),
          if (profile.canDoCategoryIds.isEmpty)
            _emptyHint('Қосымша категория жоқ.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.canDoCategoryIds
                  .map(
                    (id) => InputChip(
                      label: Text(_categoryLabel(id)),
                      onDeleted: () => _removeCanDoCategory(id),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(WorkerProfileData profile) {
    return _sectionCard(
      title: 'Дағдылар / Tags',
      onAdd: _editSkills,
      child: profile.skills.isEmpty
          ? _emptyHint('Дағды әлі қосылмаған.')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < profile.skills.length; i++)
                  InputChip(
                    label: Text(profile.skills[i]),
                    onPressed: () => _renameSkill(i),
                    onDeleted: () => _removeSkill(i),
                  ),
              ],
            ),
    );
  }

  Widget _buildServicesSection(WorkerProfileData profile) {
    return _sectionCard(
      title: 'Қызметтер / What I offer',
      onAdd: () => _editService(),
      child: profile.services.isEmpty
          ? _emptyHint('Қызметтер көрсетілмеген.')
          : Column(
              children: [
                for (int i = 0; i < profile.services.length; i++)
                  _editableListTile(
                    title: profile.services[i].name,
                    subtitle: [
                      profile.services[i].description,
                      if (profile.services[i].rate.trim().isNotEmpty)
                        'Бағасы: ${profile.services[i].rate}',
                    ].where((e) => e.trim().isNotEmpty).join('\n'),
                    onEdit: () => _editService(index: i),
                    onDelete: () => _removeService(i),
                  ),
              ],
            ),
    );
  }

  Widget _buildPortfolioSection(WorkerProfileData profile) {
    return _sectionCard(
      title: 'Портфолио',
      subtitle: 'Клиенттерге көрінетін басты бөлім.',
      onAdd: () => _editPortfolioItem(),
      child: profile.portfolio.isEmpty
          ? _emptyHint('Портфолио әлі жоқ.')
          : Column(
              children: [
                for (int i = 0; i < profile.portfolio.length; i++)
                  _editableListTile(
                    title: profile.portfolio[i].title,
                    subtitle: [
                      profile.portfolio[i].description,
                      if (profile.portfolio[i].images.isNotEmpty)
                        'Суреттер: ${profile.portfolio[i].images.length}',
                    ].where((e) => e.trim().isNotEmpty).join('\n'),
                    onEdit: () => _editPortfolioItem(index: i),
                    onDelete: () => _removePortfolioItem(i),
                    extra: profile.portfolio[i].images.isEmpty
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              height: 70,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (_, imageIndex) {
                                  final imageUrl =
                                      profile.portfolio[i].images[imageIndex];
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 90,
                                      child: SafeNetworkImage(
                                        url: imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 8),
                                itemCount: profile.portfolio[i].images.length,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
    );
  }

  Widget _buildExperienceSection(WorkerProfileData profile) {
    return _sectionCard(
      title: 'Тәжірибе',
      onAdd: () => _editExperience(),
      child: profile.experiences.isEmpty
          ? _emptyHint('Тәжірибе әлі толтырылмаған.')
          : Column(
              children: [
                for (int i = 0; i < profile.experiences.length; i++)
                  _editableListTile(
                    title:
                        "${profile.experiences[i].role} ${profile.experiences[i].company.isNotEmpty ? '• ${profile.experiences[i].company}' : ''}",
                    subtitle: [
                      profile.experiences[i].years,
                      profile.experiences[i].description,
                    ].where((e) => e.trim().isNotEmpty).join('\n'),
                    onEdit: () => _editExperience(index: i),
                    onDelete: () => _removeExperience(i),
                  ),
              ],
            ),
    );
  }

  Widget _buildEducationSection(WorkerProfileData profile) {
    return _sectionCard(
      title: 'Білім',
      onAdd: () => _editEducation(),
      child: profile.educations.isEmpty
          ? _emptyHint('Білім деректері жоқ.')
          : Column(
              children: [
                for (int i = 0; i < profile.educations.length; i++)
                  _editableListTile(
                    title:
                        "${profile.educations[i].degree} ${profile.educations[i].institution.isNotEmpty ? '• ${profile.educations[i].institution}' : ''}",
                    subtitle: [
                      profile.educations[i].years,
                      profile.educations[i].description,
                    ].where((e) => e.trim().isNotEmpty).join('\n'),
                    onEdit: () => _editEducation(index: i),
                    onDelete: () => _removeEducation(i),
                  ),
              ],
            ),
    );
  }

  Widget _buildCertificatesSection(WorkerProfileData profile) {
    return _sectionCard(
      title: 'Сертификаттар / Марапаттар',
      onAdd: () => _editCertificate(),
      child: profile.certificates.isEmpty
          ? _emptyHint('Сертификаттар әзірге жоқ.')
          : Column(
              children: [
                for (int i = 0; i < profile.certificates.length; i++)
                  _editableListTile(
                    title: profile.certificates[i].title,
                    subtitle: [
                      profile.certificates[i].issuer,
                      profile.certificates[i].year,
                      profile.certificates[i].description,
                    ].where((e) => e.trim().isNotEmpty).join('\n'),
                    onEdit: () => _editCertificate(index: i),
                    onDelete: () => _removeCertificate(i),
                  ),
              ],
            ),
    );
  }

  Widget _buildAvailabilitySection(WorkerProfileData profile) {
    final statusItems = const <DropdownMenuItem<String>>[
      DropdownMenuItem(value: 'available', child: Text('Қолжетімді')),
      DropdownMenuItem(value: 'busy', child: Text('Бос емес')),
      DropdownMenuItem(value: 'offline', child: Text('Қазір жұмыс істемеймін')),
    ];

    return _sectionCard(
      title: 'Қолжетімділік / Кесте',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue:
                const <String>{
                  'available',
                  'busy',
                  'offline',
                }.contains(profile.availabilityStatus)
                ? profile.availabilityStatus
                : 'available',
            items: statusItems,
            decoration: const InputDecoration(
              labelText: 'Статус',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value == null) return;
              _updateAvailabilityStatus(value);
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < profile.availabilitySlots.length; i++)
                InputChip(
                  label: Text(profile.availabilitySlots[i]),
                  onDeleted: () => _removeAvailabilitySlot(i),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Уақыт қосу'),
                onPressed: _addAvailabilitySlot,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(CupertinoIcons.location, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Сіздің мекен жайыңыз: ${profile.location}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(WorkerProfileData profile) {
    return _sectionCard(
      title: 'Пікірлер мен рейтинг',
      subtitle: 'Клиенттер осы бөлімді көреді.',
      child: profile.reviews.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      '${profile.rating.toStringAsFixed(1)} (${profile.reviewCount})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _emptyHint(
                  'Әзірге пікір жоқ. Бұл бөлім backend review моделімен интеграцияға дайын.',
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      '${profile.rating.toStringAsFixed(1)} (${profile.reviewCount})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final review in profile.reviews)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                review.author,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              review.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(review.text),
                        if (review.date.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            review.date,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildActionsSection() {
    return _sectionCard(
      title: 'Баптаулар',
      child: Column(
        children: [
          _actionTile(
            icon: Icons.edit_outlined,
            title: 'Профильді өзгерту',
            subtitle: 'Негізгі ақпаратты жаңарту',
            onTap: _editBasicInfo,
          ),
          _actionTile(
            icon: Icons.lock_outline,
            title: 'Пароль өзгерту',
            subtitle: 'Email арқылы сілтеме жіберу',
            onTap: _changePassword,
          ),
          _actionTile(
            icon: CupertinoIcons.settings,
            title: 'Қосымша баптаулар',
            subtitle: 'Хабарлама және жүйе',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkerSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: _showLogoutDialog,
      style: TextButton.styleFrom(
        foregroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: Colors.red.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.logOut, size: 18),
          SizedBox(width: 8),
          Flexible(
            child: SafeButtonText(
              'Аккаунттан шығу',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
    VoidCallback? onAdd,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onAdd != null)
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Қосу'),
                ),
            ],
          ),
          if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _emptyHint(String text) {
    return Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13));
  }

  Widget _editableListTile({
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    Widget? extra,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.trim().isEmpty ? 'Атауы жоқ' : title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          if (subtitle.trim().isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          if (extra != null) extra,
        ],
      ),
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
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _maskPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 7) return '***';
    return '${digits.substring(0, 4)}***${digits.substring(digits.length - 2)}';
  }
}

class _EditorField {
  final String key;
  final String label;
  final int maxLines;

  const _EditorField({
    required this.key,
    required this.label,
    this.maxLines = 1,
  });
}
