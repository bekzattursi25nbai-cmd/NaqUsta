import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kuryl_kz/core/theme/app_theme.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/core/widgets/app_buttons.dart';
import 'package:kuryl_kz/core/widgets/app_chips.dart';
import 'package:kuryl_kz/core/widgets/app_text_field.dart';
import 'package:kuryl_kz/core/widgets/offline_overlay.dart';
import 'package:kuryl_kz/features/auth/widgets/phone_number_field.dart';
import 'package:kuryl_kz/features/categories/data/category_repository.dart';
import 'package:kuryl_kz/features/categories/ui/category_picker.dart';
import 'package:kuryl_kz/features/categories/utils/category_locale.dart';
import 'package:kuryl_kz/features/location/models/kato_models.dart';
import 'package:kuryl_kz/features/location/widgets/location_picker.dart';
import 'package:kuryl_kz/features/worker/navigation/worker_main_navigation.dart';
import 'package:provider/provider.dart';

import '../controller/worker_register_controller.dart';

class WorkerRegistrationSteps extends StatelessWidget {
  const WorkerRegistrationSteps({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WorkerRegisterController>(
      create: (_) => WorkerRegisterController(),
      child: const _WorkerRegistrationContent(),
    );
  }
}

class _WorkerRegistrationContent extends StatefulWidget {
  const _WorkerRegistrationContent();

  @override
  State<_WorkerRegistrationContent> createState() =>
      _WorkerRegistrationContentState();
}

class _WorkerRegistrationContentState
    extends State<_WorkerRegistrationContent> {
  static const int _totalSteps = 7;

  final PageController _pageController = PageController();
  final ImagePicker _imagePicker = ImagePicker();

  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _addressNoteController = TextEditingController();
  final TextEditingController _brigadeNameController = TextEditingController();
  final TextEditingController _brigadeSizeController = TextEditingController();

  final CategoryRepository _categoryRepository = CategoryRepository.instance;
  late final Future<void> _categoryInitFuture;

  int _currentStep = 0;
  bool _isPhoneStepLoading = false;

  LocationBreakdown? _selectedLocation;
  WorkerCoverageMode _coverageMode = WorkerCoverageMode.exact;

  final List<String> _selectedSpecialties = <String>[];
  final List<String> _services = <String>[];

  bool _hasBrigade = false;
  String _brigadeRole = '';

  XFile? _avatarFile;

  @override
  void initState() {
    super.initState();
    _categoryInitFuture = _categoryRepository.init();
  }

  @override
  void dispose() {
    _pageController.dispose();

    _phoneController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _addressNoteController.dispose();
    _brigadeNameController.dispose();
    _brigadeSizeController.dispose();

    super.dispose();
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep >= _totalSteps - 1) return;

    _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : _panelColor,
      ),
    );
  }

  bool get _isBasicProfileValid => _nameController.text.trim().isNotEmpty;

  bool get _isLocationValid => _selectedLocation != null;

  bool get _isBrigadeValid {
    if (!_hasBrigade) return true;
    final size = int.tryParse(_brigadeSizeController.text.trim()) ?? 0;
    return size > 0 && _brigadeRole.isNotEmpty;
  }

  bool get _isDarkTheme => Theme.of(context).brightness == Brightness.dark;

  TextStyle _h2TextStyle(BuildContext context) {
    return AppTypography.h2.copyWith(
      color: _isDarkTheme ? AppColors.textPrimary : const Color(0xFF1B1B1B),
    );
  }

  TextStyle _bodyTextStyle(BuildContext context) {
    return AppTypography.body.copyWith(
      color: _isDarkTheme ? AppColors.textPrimary : const Color(0xFF1B1B1B),
    );
  }

  TextStyle _bodyMutedTextStyle(BuildContext context) {
    return AppTypography.bodyMuted.copyWith(
      color: _isDarkTheme ? AppColors.textMuted : const Color(0xFF6E6557),
    );
  }

  TextStyle _captionTextStyle(BuildContext context) {
    return AppTypography.caption.copyWith(
      color: _isDarkTheme ? AppColors.textMuted : const Color(0xFF6E6557),
    );
  }

  Color get _panelColor =>
      _isDarkTheme ? AppColors.surface2 : const Color(0xFFFFFBED);

  Color get _panelBorderColor =>
      _isDarkTheme ? AppColors.border : const Color(0xFFE6E1D8);

  Color get _mutedIconColor =>
      _isDarkTheme ? AppColors.textMuted : const Color(0xFF6E6557);

  Future<void> _pickAvatar() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 84,
      );
      if (!mounted || picked == null) return;
      setState(() => _avatarFile = picked);
    } catch (e) {
      _showSnack('Фото таңдау қатесі: $e');
    }
  }

  String _categoryLabel(String categoryId) {
    if (!_categoryRepository.isInitialized) return categoryId;
    final localeCode = resolveCategoryLocaleCode(
      Localizations.localeOf(context),
    );
    final node = _categoryRepository.byId[categoryId];
    if (node == null) return categoryId;
    return node.localizedName(localeCode);
  }

  List<String> _categoryLabels(Iterable<String> categoryIds) {
    return categoryIds.map(_categoryLabel).toList(growable: false);
  }

  Future<void> _openPrimaryCategoryPicker() async {
    await _categoryInitFuture;
    if (!mounted) return;

    final picked = await CategoryPicker.pickMultiLeaf(
      context: context,
      title: 'Негізгі мамандықтар',
      role: CategoryPickerRole.worker,
      selectionLimit: 3,
      initialLeafIds: _selectedSpecialties,
      repository: _categoryRepository,
    );
    if (!mounted || picked == null) return;

    setState(() {
      _selectedSpecialties
        ..clear()
        ..addAll(picked.take(3));
      _services.removeWhere((id) => _selectedSpecialties.contains(id));
    });
  }

  Future<void> _openCanDoCategoryPicker() async {
    await _categoryInitFuture;
    if (!mounted) return;

    final picked = await CategoryPicker.pickMultiLeaf(
      context: context,
      title: 'Қосымша дағдылар',
      role: CategoryPickerRole.worker,
      selectionLimit: 20,
      initialLeafIds: _services,
      repository: _categoryRepository,
    );
    if (!mounted || picked == null) return;

    setState(() {
      _services
        ..clear()
        ..addAll(
          picked.where((id) => !_selectedSpecialties.contains(id)).take(20),
        );
    });
  }

  Future<void> _handlePhoneContinue() async {
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;

    final controller = context.read<WorkerRegisterController>();
    setState(() => _isPhoneStepLoading = true);

    final started = await controller.startPhoneAuth(_phoneController.text);

    if (!mounted) return;
    setState(() => _isPhoneStepLoading = false);

    if (!started) {
      _showSnack(controller.lastError ?? 'Телефон авторизациясы сәтсіз.');
      return;
    }

    controller.updatePhoneDigits(_phoneController.text);
    _nextStep();
  }

  void _handleBasicContinue() {
    if (!_isBasicProfileValid) return;

    context.read<WorkerRegisterController>().updateBasicProfile(
      fullName: _nameController.text,
      bio: _bioController.text,
      avatarLocalPath: _avatarFile?.path ?? '',
    );

    _nextStep();
  }

  void _handleLocationContinue() {
    final selectedLocation = _selectedLocation;
    if (!_isLocationValid || selectedLocation == null) return;

    context.read<WorkerRegisterController>().updateLocation(
      location: selectedLocation,
      coverageMode: _coverageMode,
      addressNote: _addressNoteController.text,
    );

    _nextStep();
  }

  void _handleSpecialtiesContinue() {
    if (_selectedSpecialties.isEmpty) {
      _showSnack('Кемінде 1 мамандық таңдаңыз');
      return;
    }

    context.read<WorkerRegisterController>().updatePrimaryCategories(
      categoryIds: _selectedSpecialties,
      categoryLabels: _categoryLabels(_selectedSpecialties),
    );

    _nextStep();
  }

  void _handleServicesContinue() {
    context.read<WorkerRegisterController>().updateCanDoCategories(
      categoryIds: _services,
      categoryLabels: _categoryLabels(_services),
    );
    _nextStep();
  }

  void _handleBrigadeContinue() {
    if (!_isBrigadeValid) {
      _showSnack('Бригада үшін сан және рөл міндетті');
      return;
    }

    context.read<WorkerRegisterController>().updateBrigadeInfo(
      hasBrigade: _hasBrigade,
      brigadeName: _brigadeNameController.text,
      brigadeSize: int.tryParse(_brigadeSizeController.text.trim()),
      brigadeRole: _brigadeRole,
    );

    _nextStep();
  }

  void _syncController(WorkerRegisterController controller) {
    controller.updatePhoneDigits(_phoneController.text);
    controller.updateBasicProfile(
      fullName: _nameController.text,
      bio: _bioController.text,
      avatarLocalPath: _avatarFile?.path ?? '',
    );
    final selectedLocation = _selectedLocation;
    if (selectedLocation != null) {
      controller.updateLocation(
        location: selectedLocation,
        coverageMode: _coverageMode,
        addressNote: _addressNoteController.text,
      );
    }
    controller.updatePrimaryCategories(
      categoryIds: _selectedSpecialties,
      categoryLabels: _categoryLabels(_selectedSpecialties),
    );
    controller.updateCanDoCategories(
      categoryIds: _services,
      categoryLabels: _categoryLabels(_services),
    );
    controller.updateBrigadeInfo(
      hasBrigade: _hasBrigade,
      brigadeName: _brigadeNameController.text,
      brigadeSize: int.tryParse(_brigadeSizeController.text.trim()),
      brigadeRole: _brigadeRole,
    );
  }

  Future<void> _finishRegistration(WorkerRegisterController controller) async {
    _syncController(controller);

    final success = await controller.registerWorker();
    if (!mounted) return;

    if (!success) {
      _showSnack(controller.lastError ?? 'Тіркелу сәтсіз аяқталды');
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WorkerMainNavigation()),
      (route) => false,
    );
  }

  Widget _buildStepScaffold({required List<Widget> children}) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return _buildStepScaffold(
      children: [
        Text('Телефон нөмірі', style: _h2TextStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Тіркелім тек OTP арқылы кірген телефон нөмірімен жалғасады.',
          style: _bodyMutedTextStyle(context),
        ),
        const SizedBox(height: 16),
        Form(
          key: _phoneFormKey,
          child: PhoneNumberField(
            controller: _phoneController,
            textInputAction: TextInputAction.done,
            validator: validateKzPhone,
          ),
        ),
        const SizedBox(height: 24),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _phoneController,
          builder: (context, value, _) {
            final isPhoneValid =
                normalizeKzLocalPhoneDigits(value.text).length ==
                kKzPhoneDigitsCount;
            return AppPrimaryButton(
              label: 'Жалғастыру',
              onPressed: isPhoneValid && !_isPhoneStepLoading
                  ? _handlePhoneContinue
                  : null,
              isLoading: _isPhoneStepLoading,
            );
          },
        ),
      ],
    );
  }

  Widget _buildBasicProfileStep() {
    return _buildStepScaffold(
      children: [
        Text('Жеке профиль', style: _h2TextStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Аты-жөніңіз міндетті. Фото мен қысқаша био қоссаңыз, профиль тартымдырақ болады.',
          style: _bodyMutedTextStyle(context),
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _panelColor,
                  border: Border.all(color: _panelBorderColor),
                ),
                child: ClipOval(
                  child: _avatarFile == null
                      ? Icon(Icons.person, color: _mutedIconColor, size: 40)
                      : Image.file(File(_avatarFile!.path), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              AppSecondaryButton(
                label: _avatarFile == null ? 'Фото таңдау' : 'Фото өзгерту',
                onPressed: _pickAvatar,
                icon: Icons.photo_library_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Аты-жөні *',
          hint: 'Мысалы: Бекзат Тургинбай',
          controller: _nameController,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Өзіңіз туралы (міндетті емес)',
          hint: 'Қысқаша таныстыру',
          controller: _bioController,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        AppPrimaryButton(
          label: 'Сақтау және жалғастыру',
          onPressed: _isBasicProfileValid ? _handleBasicContinue : null,
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return _buildStepScaffold(
      children: [
        Text('Орналасу аймағы', style: _h2TextStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Қала/өңір → Аудан → Елді мекен тізбегін таңдаңыз.',
          style: _bodyMutedTextStyle(context),
        ),
        const SizedBox(height: 16),
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: _panelColor,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Color(0xFFE6E1D8)),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Color(0xFFE6E1D8)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: AppColors.gold, width: 1.2),
              ),
            ),
          ),
          child: LocationPicker(
            mode: LocationPickerMode.registration,
            enableSearch: false,
            showHeader: true,
            title: 'Сіздің мекен жайыңыз',
            initialValue: _selectedLocation,
            onChanged: (value) {
              setState(() => _selectedLocation = value);
            },
          ),
        ),
        const SizedBox(height: 20),
        Text('Тапсырыс қамту аймағы', style: _captionTextStyle(context)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: WorkerCoverageMode.values
              .map(
                (mode) => AppChoiceChip(
                  label: mode.kzLabel,
                  selected: _coverageMode == mode,
                  onTap: () => setState(() => _coverageMode = mode),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Қосымша адрес (міндетті емес)',
          hint: 'Көше, бағдар немесе түсіндірме',
          controller: _addressNoteController,
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        AppPrimaryButton(
          label: 'Жалғастыру',
          onPressed: _isLocationValid ? _handleLocationContinue : null,
        ),
      ],
    );
  }

  Widget _buildSpecialtiesStep() {
    return _buildStepScaffold(
      children: [
        Text('Негізгі мамандықтар', style: _h2TextStyle(context)),
        const SizedBox(height: 8),
        Text(
          '1-3 нақты санат таңдаңыз. Негізгі мамандық сәйкестікке көбірек әсер етеді және профиліңізде көрсетіледі.',
          style: _bodyMutedTextStyle(context),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openPrimaryCategoryPicker,
            icon: const Icon(Icons.tune_rounded),
            label: Text('Таңдау (${_selectedSpecialties.length}/3)'),
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedSpecialties.isEmpty)
          Text(
            'Негізгі категория таңдалмаған',
            style: _bodyMutedTextStyle(context),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSpecialties
                .map(
                  (item) => InputChip(
                    label: Text(_categoryLabel(item)),
                    onDeleted: () {
                      setState(() {
                        _selectedSpecialties.remove(item);
                        _services.remove(item);
                      });
                    },
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 16),
        AppPrimaryButton(
          label: 'Сақтау және жалғастыру',
          onPressed: _selectedSpecialties.isNotEmpty
              ? _handleSpecialtiesContinue
              : null,
        ),
      ],
    );
  }

  Widget _buildServicesStep() {
    return _buildStepScaffold(
      children: [
        Text('Қосымша дағдылар', style: _h2TextStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Қосымша 20 санатқа дейін таңдаңыз (міндетті емес). Бұл санаттар "Қосымша жасай алады" белгісіне әсер етеді.',
          style: _bodyMutedTextStyle(context),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openCanDoCategoryPicker,
            icon: const Icon(Icons.add_task_rounded),
            label: Text('Таңдау (${_services.length}/20)'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ескерту: негізгі мамандыққа ауыстырылған санат қосымша тізімнен автоматты түрде өшіріледі.',
          style: _captionTextStyle(context),
        ),
        const SizedBox(height: 12),
        if (_services.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _panelColor,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: _panelBorderColor),
            ),
            child: Text(
              'Қосымша дағды таңдалмаған',
              style: _bodyMutedTextStyle(context),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _services
                .map(
                  (item) => InputChip(
                    label: Text(_categoryLabel(item)),
                    onDeleted: () => setState(() => _services.remove(item)),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 24),
        AppPrimaryButton(
          label: 'Жалғастыру',
          onPressed: _handleServicesContinue,
        ),
      ],
    );
  }

  Widget _buildBrigadeStep() {
    return _buildStepScaffold(
      children: [
        Text('Бригада / Команда', style: _h2TextStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Егер командамен жұмыс істесеңіз, бригада мәліметтерін толтырыңыз.',
          style: _bodyMutedTextStyle(context),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: _panelColor,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: _panelBorderColor),
          ),
          child: SwitchListTile(
            title: Text('Бригада бар', style: _bodyTextStyle(context)),
            value: _hasBrigade,
            onChanged: (value) {
              setState(() {
                _hasBrigade = value;
                if (!_hasBrigade) {
                  _brigadeRole = '';
                  _brigadeSizeController.clear();
                }
              });
            },
          ),
        ),
        if (_hasBrigade) ...[
          const SizedBox(height: 16),
          AppTextField(
            label: 'Бригада атауы (міндетті емес)',
            hint: 'Мысалы: Amanat Team',
            controller: _brigadeNameController,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Бригада саны *',
            hint: 'Мысалы: 4',
            controller: _brigadeSizeController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('Рөліңіз *', style: _captionTextStyle(context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppChoiceChip(
                label: 'Жетекші',
                selected: _brigadeRole == 'Жетекші',
                onTap: () => setState(() => _brigadeRole = 'Жетекші'),
              ),
              AppChoiceChip(
                label: 'Мүше',
                selected: _brigadeRole == 'Мүше',
                onTap: () => setState(() => _brigadeRole = 'Мүше'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        AppPrimaryButton(
          label: 'Жалғастыру',
          onPressed: _isBrigadeValid ? _handleBrigadeContinue : null,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: _panelBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _captionTextStyle(context)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildReviewStep(WorkerRegisterController controller) {
    final phone = '+7${normalizeKzLocalPhoneDigits(_phoneController.text)}';

    final locationText = _selectedLocation?.fullLabel ?? '';

    final brigadeText = !_hasBrigade
        ? 'Көрсетілмеген'
        : [
            if (_brigadeNameController.text.trim().isNotEmpty)
              _brigadeNameController.text.trim(),
            'Саны: ${_brigadeSizeController.text.trim()}',
            'Рөлі: $_brigadeRole',
          ].join(' • ');

    return _buildStepScaffold(
      children: [
        Text('Тексеру және аяқтау', style: _h2TextStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Ақпаратты қарап шығып, тіркелуді аяқтаңыз.',
          style: _bodyMutedTextStyle(context),
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          title: 'Телефон',
          child: Text(phone, style: _bodyTextStyle(context)),
        ),
        _buildSummaryCard(
          title: 'Аты-жөні',
          child: Text(
            _nameController.text.trim().isEmpty
                ? 'Көрсетілмеген'
                : _nameController.text.trim(),
            style: _bodyTextStyle(context),
          ),
        ),
        _buildSummaryCard(
          title: 'Локация',
          child: Text(
            locationText.isEmpty ? 'Көрсетілмеген' : locationText,
            style: _bodyTextStyle(context),
          ),
        ),
        _buildSummaryCard(
          title: 'Қамту режимі',
          child: Text(_coverageMode.kzLabel, style: _bodyTextStyle(context)),
        ),
        _buildSummaryCard(
          title: 'Негізгі мамандықтар',
          child: _selectedSpecialties.isEmpty
              ? Text('Көрсетілмеген', style: _bodyMutedTextStyle(context))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedSpecialties
                      .map((item) => AppTagChip(label: _categoryLabel(item)))
                      .toList(),
                ),
        ),
        _buildSummaryCard(
          title: 'Қосымша дағдылар',
          child: _services.isEmpty
              ? Text('Көрсетілмеген', style: _bodyMutedTextStyle(context))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _services
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${_categoryLabel(item)}',
                            style: _bodyTextStyle(context),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        _buildSummaryCard(
          title: 'Бригада',
          child: Text(brigadeText, style: _bodyTextStyle(context)),
        ),
        if (_addressNoteController.text.trim().isNotEmpty)
          _buildSummaryCard(
            title: 'Қосымша адрес',
            child: Text(
              _addressNoteController.text.trim(),
              style: _bodyTextStyle(context),
            ),
          ),
        if (controller.lastError != null && controller.lastError!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              controller.lastError!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        AppPrimaryButton(
          label: 'Тіркелуді аяқтау',
          onPressed: controller.isLoading
              ? null
              : () => _finishRegistration(controller),
          isLoading: controller.isLoading,
        ),
      ],
    );
  }

  Widget _buildStepByIndex(int index, WorkerRegisterController controller) {
    switch (index) {
      case 0:
        return _buildPhoneStep();
      case 1:
        return _buildBasicProfileStep();
      case 2:
        return _buildLocationStep();
      case 3:
        return _buildSpecialtiesStep();
      case 4:
        return _buildServicesStep();
      case 5:
        return _buildBrigadeStep();
      case 6:
        return _buildReviewStep(controller);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WorkerRegisterController>();

    return Theme(
      data: AppTheme.workerLight(),
      child: OfflineFullScreenGate(
        child: Scaffold(
          appBar: AppBar(
            leading: appBarBackButton(context, onPressed: _previousStep),
            title: const Text('Шебер тіркелуі'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_currentStep + 1}/$_totalSteps',
                      style: _captionTextStyle(context),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / _totalSteps,
                        minHeight: 6,
                        backgroundColor: _panelColor,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                if (_currentStep == index || !mounted) return;
                setState(() => _currentStep = index);
              },
              itemCount: _totalSteps,
              itemBuilder: (context, index) {
                return _buildStepByIndex(index, controller);
              },
            ),
          ),
        ),
      ),
    );
  }
}
