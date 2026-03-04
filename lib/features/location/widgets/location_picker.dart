import 'package:flutter/material.dart';
import 'package:kuryl_kz/features/location/models/kato_models.dart';
import 'package:kuryl_kz/features/location/services/kato_location_service.dart';

enum LocationPickerMode { registration, order }

class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    required this.onChanged,
    this.initialValue,
    this.initialKatoCode,
    this.enableSearch = false,
    this.locale = 'kz',
    this.mode = LocationPickerMode.registration,
    this.title = 'Сіздің мекен жайыңыз',
    this.showHeader = true,
    this.showClearButton = true,
  });

  final ValueChanged<LocationBreakdown?> onChanged;
  final LocationBreakdown? initialValue;
  final String? initialKatoCode;
  final bool enableSearch;
  final String locale;
  final LocationPickerMode mode;
  final String title;
  final bool showHeader;
  final bool showClearButton;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final KatoLocationService _locationService = KatoLocationService.instance;

  final TextEditingController _districtSearchController =
      TextEditingController();
  final TextEditingController _localitySearchController =
      TextEditingController();
  final TextEditingController _settlementSearchController =
      TextEditingController();

  bool _isLoading = true;
  String? _errorText;

  List<KatoTreeNode> _topOptions = <KatoTreeNode>[];
  List<KatoTreeNode> _districtOptions = <KatoTreeNode>[];
  List<KatoTreeNode> _localityOptions = <KatoTreeNode>[];
  List<KatoTreeNode> _settlementOptions = <KatoTreeNode>[];

  int? _selectedTopId;
  int? _selectedDistrictId;
  int? _selectedLocalityId;
  int? _selectedSettlementId;

  LocationBreakdown? _resolved;
  LocationBreakdown? _lastEmitted;
  LocationBreakdown? _pendingEmission;
  bool _isEmissionQueued = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldInitial =
        oldWidget.initialValue?.katoCode ?? oldWidget.initialKatoCode ?? '';
    final newInitial =
        widget.initialValue?.katoCode ?? widget.initialKatoCode ?? '';

    if (oldInitial != newInitial && !_isLoading) {
      _restoreInitialSelection(newInitial);
      _emitSelection();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _districtSearchController.dispose();
    _localitySearchController.dispose();
    _settlementSearchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await _locationService.warmUp();

      final topOptions = _locationService.getTopLevelOptions(
        locale: widget.locale,
      );

      _topOptions = topOptions;
      _districtOptions = <KatoTreeNode>[];
      _localityOptions = <KatoTreeNode>[];
      _settlementOptions = <KatoTreeNode>[];

      final initialKatoCode =
          widget.initialValue?.katoCode ?? widget.initialKatoCode ?? '';
      _restoreInitialSelection(initialKatoCode);

      _emitSelection();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Локациялар жүктелмеді: $e';
      });
    }
  }

  void _restoreInitialSelection(String katoCode) {
    if (katoCode.trim().isEmpty) {
      _clearSelection(emit: false);
      return;
    }

    final finalItem = _locationService.findByKatoCode(katoCode);
    if (finalItem == null) {
      _clearSelection(emit: false);
      return;
    }

    final selectedId = finalItem.id;
    final top = _firstWhereOrNull(
      _topOptions,
      (node) => _locationService.isAncestor(
        ancestorId: node.id,
        descendantId: selectedId,
      ),
    );

    _selectedTopId = top?.id;
    _selectedDistrictId = null;
    _selectedLocalityId = null;
    _selectedSettlementId = null;
    _districtOptions = <KatoTreeNode>[];
    _localityOptions = <KatoTreeNode>[];
    _settlementOptions = <KatoTreeNode>[];

    if (_selectedTopId == null) {
      return;
    }

    _districtOptions = _locationService.getDistrictOptions(
      _selectedTopId!,
      locale: widget.locale,
    );

    final district = _firstWhereOrNull(
      _districtOptions,
      (node) => _locationService.isAncestor(
        ancestorId: node.id,
        descendantId: selectedId,
      ),
    );

    _selectedDistrictId = district?.id;
    if (_selectedDistrictId == null) {
      return;
    }

    _localityOptions = _locationService.getLocalityOptions(
      _selectedDistrictId!,
      locale: widget.locale,
    );

    final locality = _firstWhereOrNull(
      _localityOptions,
      (node) => _locationService.isAncestor(
        ancestorId: node.id,
        descendantId: selectedId,
      ),
    );

    _selectedLocalityId = locality?.id;
    if (_selectedLocalityId == null) {
      return;
    }

    _settlementOptions = _locationService.getSettlementOptions(
      _selectedLocalityId!,
      locale: widget.locale,
    );

    final settlement = _firstWhereOrNull(
      _settlementOptions,
      (node) => node.id == selectedId,
    );

    _selectedSettlementId = settlement?.id;
  }

  void _onTopChanged(int? id) {
    setState(() {
      _selectedTopId = id;
      _selectedDistrictId = null;
      _selectedLocalityId = null;
      _selectedSettlementId = null;

      _districtOptions = id == null
          ? <KatoTreeNode>[]
          : _locationService.getDistrictOptions(id, locale: widget.locale);
      _localityOptions = <KatoTreeNode>[];
      _settlementOptions = <KatoTreeNode>[];

      _districtSearchController.clear();
      _localitySearchController.clear();
      _settlementSearchController.clear();
    });

    _emitSelection();
  }

  void _onDistrictChanged(int? id) {
    setState(() {
      _selectedDistrictId = id;
      _selectedLocalityId = null;
      _selectedSettlementId = null;

      _localityOptions = id == null
          ? <KatoTreeNode>[]
          : _locationService.getLocalityOptions(id, locale: widget.locale);
      _settlementOptions = <KatoTreeNode>[];

      _localitySearchController.clear();
      _settlementSearchController.clear();
    });

    _emitSelection();
  }

  void _onLocalityChanged(int? id) {
    setState(() {
      _selectedLocalityId = id;
      _selectedSettlementId = null;

      _settlementOptions = id == null
          ? <KatoTreeNode>[]
          : _locationService.getSettlementOptions(id, locale: widget.locale);

      _settlementSearchController.clear();
    });

    _emitSelection();
  }

  void _onSettlementChanged(int? id) {
    setState(() {
      _selectedSettlementId = id;
    });

    _emitSelection();
  }

  void _clearSelection({bool emit = true}) {
    setState(() {
      _selectedTopId = null;
      _selectedDistrictId = null;
      _selectedLocalityId = null;
      _selectedSettlementId = null;
      _districtOptions = <KatoTreeNode>[];
      _localityOptions = <KatoTreeNode>[];
      _settlementOptions = <KatoTreeNode>[];
      _resolved = null;

      _districtSearchController.clear();
      _localitySearchController.clear();
      _settlementSearchController.clear();
    });

    if (emit) {
      _emitChanged(null);
    }
  }

  void _emitSelection() {
    if (_selectedTopId == null) {
      _resolved = null;
      _emitChanged(null);
      return;
    }

    final resolved = _locationService.resolveSelection(
      topLevelId: _selectedTopId,
      districtId: _selectedDistrictId,
      localityId: _selectedLocalityId,
      settlementId: _selectedSettlementId,
    );

    final breakdown = resolved.toBreakdown();
    _resolved = breakdown;
    _emitChanged(breakdown);
  }

  bool _isSameBreakdown(LocationBreakdown? left, LocationBreakdown? right) {
    if (identical(left, right)) return true;
    if (left == null || right == null) return false;

    final leftCode = left.katoCode.trim();
    final rightCode = right.katoCode.trim();
    if (leftCode.isNotEmpty || rightCode.isNotEmpty) {
      return leftCode == rightCode;
    }

    return left.id == right.id &&
        left.shortLabel.trim() == right.shortLabel.trim();
  }

  void _emitChanged(LocationBreakdown? value) {
    if (_isSameBreakdown(_lastEmitted, value) && !_isEmissionQueued) {
      return;
    }

    _pendingEmission = value;
    if (_isEmissionQueued) {
      return;
    }

    _isEmissionQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isEmissionQueued = false;
      if (!mounted) return;

      final pending = _pendingEmission;
      _pendingEmission = null;

      if (_isSameBreakdown(_lastEmitted, pending)) {
        return;
      }

      _lastEmitted = pending;
      widget.onChanged(pending);
    });
  }

  List<KatoTreeNode> _applySearch(List<KatoTreeNode> options, String query) {
    if (!widget.enableSearch) return options;

    final normalized = query.trim();
    if (normalized.isEmpty) {
      return options;
    }

    return _locationService.filterNodesByQuery(
      options,
      normalized,
      locale: widget.locale,
    );
  }

  List<KatoTreeNode> _ensureSelectedVisible(
    List<KatoTreeNode> filtered,
    List<KatoTreeNode> all,
    int? selectedId,
  ) {
    if (selectedId == null) return filtered;
    final exists = filtered.any((item) => item.id == selectedId);
    if (exists) return filtered;

    final selectedNode = _firstWhereOrNull(
      all,
      (node) => node.id == selectedId,
    );
    if (selectedNode == null) return filtered;
    return <KatoTreeNode>[selectedNode, ...filtered];
  }

  KatoTreeNode? _firstWhereOrNull(
    List<KatoTreeNode> source,
    bool Function(KatoTreeNode node) predicate,
  ) {
    for (final item in source) {
      if (predicate(item)) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = _LocationPickerPalette.resolve(context, mode: widget.mode);

    if (_isLoading) {
      return _buildLoadingState(palette);
    }

    if (_errorText != null) {
      return _buildErrorState(palette);
    }

    final hasDistrictLevel =
        _selectedTopId != null && _districtOptions.isNotEmpty;
    final hasLocalityLevel =
        _selectedDistrictId != null && _localityOptions.isNotEmpty;
    final hasSettlementLevel =
        _selectedLocalityId != null && _settlementOptions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) _buildHeader(palette),
        if (widget.showHeader) const SizedBox(height: 12),
        _buildLevelSection(
          palette: palette,
          step: '1',
          title: 'Қала / Өңір',
          subtitle: 'Алдымен негізгі өңірді таңдаңыз.',
          child: _buildLevelDropdown(
            palette: palette,
            label: 'Қала / Өңір',
            options: _topOptions,
            selectedId: _selectedTopId,
            onChanged: _onTopChanged,
            emptyHint: 'Қала/өңір тізімі бос',
            emptyTitle: 'Өңірлер табылмады',
          ),
        ),
        if (hasDistrictLevel)
          _buildLevelSection(
            palette: palette,
            step: '2',
            title: 'Аудан',
            subtitle: 'Тек таңдалған өңірге тиесілі аудандар көрсетіледі.',
            child: Column(
              children: [
                if (widget.enableSearch)
                  _buildSearchField(
                    palette: palette,
                    controller: _districtSearchController,
                    hint: 'Аудан іздеу',
                  ),
                if (widget.enableSearch) const SizedBox(height: 10),
                _buildLevelDropdown(
                  palette: palette,
                  label: 'Аудан',
                  options: _districtOptions,
                  selectedId: _selectedDistrictId,
                  onChanged: _onDistrictChanged,
                  emptyHint: 'Таңдалған өңірде аудан табылмады',
                  emptyTitle: 'Аудан жоқ',
                  searchController: _districtSearchController,
                ),
              ],
            ),
          )
        else if (_selectedTopId != null)
          _buildNoticeCard(
            palette: palette,
            title: 'Аудан деңгейі жоқ',
            message:
                'Бұл тармақта аудан деңгейі көрсетілмейді. Төменгі деңгейлер болса, бірден солар ашылады.',
            icon: Icons.info_outline_rounded,
            tone: _NoticeTone.info,
            bottomPadding: 12,
          ),
        if (hasLocalityLevel)
          _buildLevelSection(
            palette: palette,
            step: '3',
            title: 'Ауылдық округ / Елді мекен',
            subtitle: 'Ауданға қатысты нақты елді мекенді таңдаңыз.',
            child: Column(
              children: [
                if (widget.enableSearch)
                  _buildSearchField(
                    palette: palette,
                    controller: _localitySearchController,
                    hint: 'Елді мекен іздеу',
                  ),
                if (widget.enableSearch) const SizedBox(height: 10),
                _buildLevelDropdown(
                  palette: palette,
                  label: 'Ауылдық округ / Елді мекен',
                  options: _localityOptions,
                  selectedId: _selectedLocalityId,
                  onChanged: _onLocalityChanged,
                  emptyHint: 'Бұл ауданда елді мекен табылмады',
                  emptyTitle: 'Елді мекен жоқ',
                  searchController: _localitySearchController,
                ),
              ],
            ),
          )
        else if (_selectedDistrictId != null)
          _buildNoticeCard(
            palette: palette,
            title: 'Елді мекен деңгейі жоқ',
            message:
                'Бұл ауданда бөлек ауыл/елді мекен деңгейі жоқ. Қажет болса келесі деңгейді таңдаңыз.',
            icon: Icons.info_outline_rounded,
            tone: _NoticeTone.info,
            bottomPadding: 12,
          ),
        if (hasSettlementLevel)
          _buildLevelSection(
            palette: palette,
            step: '4',
            title: 'Кент / Төменгі елді мекен',
            subtitle: 'Қажет болса соңғы нақтылау деңгейін таңдаңыз.',
            child: Column(
              children: [
                if (widget.enableSearch)
                  _buildSearchField(
                    palette: palette,
                    controller: _settlementSearchController,
                    hint: 'Кент/елді мекен іздеу',
                  ),
                if (widget.enableSearch) const SizedBox(height: 10),
                _buildLevelDropdown(
                  palette: palette,
                  label: 'Кент / Төменгі елді мекен',
                  options: _settlementOptions,
                  selectedId: _selectedSettlementId,
                  onChanged: _onSettlementChanged,
                  emptyHint: 'Бұл тармақта кент/төменгі елді мекен жоқ',
                  emptyTitle: 'Кент деңгейі табылмады',
                  searchController: _settlementSearchController,
                ),
              ],
            ),
          )
        else if (_selectedLocalityId != null)
          _buildNoticeCard(
            palette: palette,
            title: 'Кент деңгейі жоқ',
            message: 'Қазіргі таңдау жарамды. Осы деңгеймен жалғастыра аласыз.',
            icon: Icons.check_circle_outline_rounded,
            tone: _NoticeTone.success,
            bottomPadding: 12,
          ),
        if (_resolved != null) _buildSelectedSummary(palette, _resolved!),
      ],
    );
  }

  Widget _buildHeader(_LocationPickerPalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: palette.headerBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.headerBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (widget.showClearButton && _selectedTopId != null)
            OutlinedButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Тазалау'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: BorderSide(color: palette.accent.withValues(alpha: 0.5)),
                foregroundColor: palette.accent,
                backgroundColor: palette.accent.withValues(alpha: 0.08),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(_LocationPickerPalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.sectionBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Локациялар дайындалып жатыр',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Күте тұрыңыз, КАТО деректері жүктелуде.',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(_LocationPickerPalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.danger.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, color: palette.danger, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorText ?? 'Қате орын алды',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _initialize,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Қайта жүктеу'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              backgroundColor: palette.danger.withValues(alpha: 0.2),
              foregroundColor: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSection({
    required _LocationPickerPalette palette,
    required String step,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: palette.sectionBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.accent.withValues(alpha: 0.34)),
                ),
                child: Text(
                  step,
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required _LocationPickerPalette palette,
    required TextEditingController controller,
    required String hint,
  }) {
    if (!widget.enableSearch) {
      return const SizedBox.shrink();
    }

    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: palette.textMuted,
          fontSize: 14,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: palette.textSecondary),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  setState(() {});
                },
                icon: Icon(Icons.close_rounded, color: palette.textSecondary),
                tooltip: 'Тазалау',
              ),
        filled: true,
        fillColor: palette.searchBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accent, width: 1.3),
        ),
      ),
    );
  }

  Widget _buildLevelDropdown({
    required _LocationPickerPalette palette,
    required String label,
    required List<KatoTreeNode> options,
    required int? selectedId,
    required ValueChanged<int?> onChanged,
    required String emptyHint,
    required String emptyTitle,
    TextEditingController? searchController,
  }) {
    final filtered = _applySearch(options, searchController?.text ?? '');
    final withSelected = _ensureSelectedVisible(filtered, options, selectedId);

    if (options.isEmpty) {
      return _buildNoticeCard(
        palette: palette,
        title: emptyTitle,
        message: emptyHint,
        icon: Icons.info_outline_rounded,
        tone: _NoticeTone.info,
      );
    }

    if (withSelected.isEmpty) {
      return _buildNoticeCard(
        palette: palette,
        title: 'Нәтиже табылмады',
        message: 'Іздеу шартын өзгертіңіз немесе тазалап көріңіз.',
        icon: Icons.search_off_rounded,
        tone: _NoticeTone.warning,
      );
    }

    final hasValue =
        selectedId != null && withSelected.any((item) => item.id == selectedId);

    final optionLabels = withSelected
        .map(
          (node) => _locationService.optionLabel(
            node,
            options,
            locale: widget.locale,
          ),
        )
        .toList();

    return DropdownButtonFormField<int>(
      key: ValueKey<String>('${label}_${selectedId ?? 'empty'}'),
      initialValue: hasValue ? selectedId : null,
      isExpanded: true,
      menuMaxHeight: 340,
      borderRadius: BorderRadius.circular(12),
      dropdownColor: palette.menuBackground,
      iconEnabledColor: palette.textSecondary,
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: palette.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintText: 'Таңдаңыз',
        hintStyle: TextStyle(
          color: palette.textMuted,
          fontSize: 14,
        ),
        filled: true,
        fillColor: palette.fieldBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accent, width: 1.3),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
      ),
      selectedItemBuilder: (context) {
        return optionLabels
            .map(
              (labelValue) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  labelValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList();
      },
      items: List<DropdownMenuItem<int>>.generate(withSelected.length, (index) {
        final node = withSelected[index];
        final labelValue = optionLabels[index];
        return DropdownMenuItem<int>(
          value: node.id,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              labelValue,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 14,
                height: 1.28,
              ),
            ),
          ),
        );
      }),
      onChanged: onChanged,
    );
  }

  Widget _buildNoticeCard({
    required _LocationPickerPalette palette,
    required String title,
    required String message,
    required IconData icon,
    required _NoticeTone tone,
    double bottomPadding = 0,
  }) {
    final style = palette.noticeStyleFor(tone);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: style.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: style.icon),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 13.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12.4,
                      height: 1.32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSummary(
    _LocationPickerPalette palette,
    LocationBreakdown value,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: palette.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.success.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: palette.success, size: 18),
              const SizedBox(width: 8),
              Text(
                'Таңдалған мекен жай',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value.shortLabel,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.24,
            ),
          ),
          if (value.fullLabel.trim().isNotEmpty &&
              value.fullLabel.trim() != value.shortLabel.trim()) ...[
            const SizedBox(height: 4),
            Text(
              value.fullLabel,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _NoticeTone { info, warning, error, success }

class _LocationPickerPalette {
  const _LocationPickerPalette({
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.headerBorder,
    required this.headerBackground,
    required this.sectionBackground,
    required this.fieldBackground,
    required this.searchBackground,
    required this.menuBackground,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color headerBorder;
  final Color headerBackground;
  final Color sectionBackground;
  final Color fieldBackground;
  final Color searchBackground;
  final Color menuBackground;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  factory _LocationPickerPalette.resolve(
    BuildContext context, {
    required LocationPickerMode mode,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (mode == LocationPickerMode.order) {
      const accent = Color(0xFFFFD700);
      return const _LocationPickerPalette(
        accent: accent,
        textPrimary: Color(0xFFF9FAFB),
        textSecondary: Color(0xFFE5E7EB),
        textMuted: Color(0xFFBFC6D4),
        border: Color(0xFF343741),
        headerBorder: Color(0xFF7A6112),
        headerBackground: Color(0xFF1B1B22),
        sectionBackground: Color(0xFF191A21),
        fieldBackground: Color(0xFF20222B),
        searchBackground: Color(0xFF242631),
        menuBackground: Color(0xFF17181F),
        success: Color(0xFF2ECC71),
        warning: Color(0xFFF5A524),
        danger: Color(0xFFFF5A5F),
        info: Color(0xFF4DA3FF),
      );
    }

    final accent = scheme.primary;

    final surface = scheme.surface;
    final textPrimary = scheme.onSurface;
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : Colors.black.withValues(alpha: 0.72);
    final textMuted = isDark
        ? Colors.white.withValues(alpha: 0.56)
        : Colors.black.withValues(alpha: 0.5);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.13)
        : Colors.black.withValues(alpha: 0.12);

    final headerBackground = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.08 : 0.06),
      surface,
    );
    final sectionBackground = Color.alphaBlend(
      (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.02 : 0.015),
      surface,
    );
    final fieldBackground = Color.alphaBlend(
      (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.03 : 0.025),
      surface,
    );
    final searchBackground = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.06 : 0.04),
      fieldBackground,
    );
    final menuBackground = Color.alphaBlend(
      (isDark ? Colors.black : Colors.white).withValues(alpha: isDark ? 0.06 : 0.0),
      surface,
    );

    return _LocationPickerPalette(
      accent: accent,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      border: border,
      headerBorder: accent.withValues(alpha: isDark ? 0.38 : 0.28),
      headerBackground: headerBackground,
      sectionBackground: sectionBackground,
      fieldBackground: fieldBackground,
      searchBackground: searchBackground,
      menuBackground: menuBackground,
      success: const Color(0xFF2ECC71),
      warning: const Color(0xFFF5A524),
      danger: const Color(0xFFFF5A5F),
      info: const Color(0xFF4DA3FF),
    );
  }

  _NoticeVisualStyle noticeStyleFor(_NoticeTone tone) {
    switch (tone) {
      case _NoticeTone.warning:
        return _NoticeVisualStyle(
          background: warning.withValues(alpha: 0.13),
          border: warning.withValues(alpha: 0.36),
          icon: warning,
        );
      case _NoticeTone.error:
        return _NoticeVisualStyle(
          background: danger.withValues(alpha: 0.14),
          border: danger.withValues(alpha: 0.4),
          icon: danger,
        );
      case _NoticeTone.success:
        return _NoticeVisualStyle(
          background: success.withValues(alpha: 0.13),
          border: success.withValues(alpha: 0.35),
          icon: success,
        );
      case _NoticeTone.info:
        return _NoticeVisualStyle(
          background: info.withValues(alpha: 0.12),
          border: info.withValues(alpha: 0.34),
          icon: info,
        );
    }
  }
}

class _NoticeVisualStyle {
  const _NoticeVisualStyle({
    required this.background,
    required this.border,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color icon;
}
