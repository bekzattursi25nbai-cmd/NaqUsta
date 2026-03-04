import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/data/city_repository.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_chips.dart';
import 'package:kuryl_kz/core/widgets/app_skeleton.dart';
import 'package:kuryl_kz/core/widgets/app_text_field.dart';
import 'package:kuryl_kz/core/widgets/empty_state.dart';
import 'package:kuryl_kz/core/widgets/city_picker_sheet.dart';
import 'package:kuryl_kz/features/categories/data/category_repository.dart';
import 'package:kuryl_kz/features/categories/models/category_match.dart';
import 'package:kuryl_kz/features/categories/ui/category_node_filter_picker.dart';
import 'package:kuryl_kz/features/categories/ui/category_picker.dart';
import 'package:kuryl_kz/features/categories/utils/category_locale.dart';
import 'package:kuryl_kz/features/client/home/models/worker_model.dart';
import 'package:kuryl_kz/features/client/home/screens/worker_detail_screen.dart';
import 'package:kuryl_kz/features/client/home/widgets/worker_mini_card.dart';

enum SortOption { bestMatch, ratingDesc }

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  static const int _pageSize = 12;

  final CategoryRepository _categoryRepository = CategoryRepository.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  String _searchQuery = '';
  String? _selectedCity;
  String? _selectedCategoryNodeId;
  bool _showAllWorkers = true;
  SortOption _sortOption = SortOption.bestMatch;

  List<WorkerModel> _workers = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String _orderByField = 'createdAt';

  @override
  void initState() {
    super.initState();
    _categoryRepository.init().then((_) {
      if (mounted) setState(() {});
    });
    _fetchInitial();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedCity != null && _selectedCity!.isNotEmpty) count++;
    if (_selectedCategoryNodeId != null) count++;
    if (_sortOption != SortOption.bestMatch) count++;
    if (!_showAllWorkers) count++;
    return count;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'workers',
    );

    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      query = query.where('city', isEqualTo: _selectedCity);
    }

    query = query.orderBy(_orderByField, descending: true);

    return query;
  }

  bool _shouldFallbackToLegacyOrder(FirebaseException e) {
    final message = (e.message ?? '').toLowerCase();
    if (e.code == 'failed-precondition' || e.code == 'invalid-argument') {
      return true;
    }
    return message.contains('createdat') || message.contains('order by');
  }

  Future<void> _fetchInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _workers = [];
      _lastDoc = null;
      _hasMore = true;
      _orderByField = 'createdAt';
    });

    await _fetchPage(loadMore: false);
  }

  Future<void> _fetchMore() async {
    if (_isLoadingMore || _isLoading || !_hasMore) return;
    await _fetchPage(loadMore: true);
  }

  Future<void> _fetchPage({required bool loadMore}) async {
    try {
      setState(() => _isLoadingMore = loadMore);

      Query<Map<String, dynamic>> query = _buildQuery();
      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      query = query.limit(_pageSize);

      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await query.get();
      } on FirebaseException catch (e) {
        final canFallbackToLegacyField =
            !loadMore &&
            _lastDoc == null &&
            _orderByField == 'createdAt' &&
            _shouldFallbackToLegacyOrder(e);
        if (!canFallbackToLegacyField) rethrow;

        _orderByField = 'created_at';
        snapshot = await _buildQuery().limit(_pageSize).get();
      }
      final docs = snapshot.docs;

      if (!mounted) return;

      if (docs.isNotEmpty) {
        _lastDoc = docs.last;
      }

      final items = docs.map((doc) {
        final data = doc.data();
        return WorkerModel.fromMap(data, doc.id);
      }).toList();

      setState(() {
        if (loadMore) {
          _workers.addAll(items);
        } else {
          _workers = items;
        }
        _hasMore = items.length == _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message ?? e.code;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Set<String>? _selectedLeafIds() {
    final nodeId = _selectedCategoryNodeId;
    if (nodeId == null || !_categoryRepository.isInitialized) return null;
    final node = _categoryRepository.byId[nodeId];
    if (node == null) return null;
    return node.isLeaf
        ? <String>{node.id}
        : _categoryRepository.leafIdsUnderNode(node.id);
  }

  CategoryMatchType _workerMatchType(
    WorkerModel worker,
    Set<String>? selectedLeafIds,
  ) {
    if (selectedLeafIds == null || selectedLeafIds.isEmpty) {
      return CategoryMatchType.other;
    }
    final primaryHit = worker.primaryCategoryIds.any(selectedLeafIds.contains);
    if (primaryHit) return CategoryMatchType.primary;
    final canDoHit = worker.canDoCategoryIds.any(selectedLeafIds.contains);
    if (canDoHit) return CategoryMatchType.canDo;
    return CategoryMatchType.other;
  }

  List<WorkerModel> get _visibleWorkers {
    List<WorkerModel> items = List<WorkerModel>.from(_workers);
    final selectedLeafIds = _selectedLeafIds();

    if (_searchQuery.isNotEmpty) {
      items = items
          .where((w) => w.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (selectedLeafIds != null &&
        selectedLeafIds.isNotEmpty &&
        !_showAllWorkers) {
      items = items
          .where(
            (worker) =>
                worker.primaryCategoryIds.any(selectedLeafIds.contains) ||
                worker.canDoCategoryIds.any(selectedLeafIds.contains),
          )
          .toList();
    } else if (!_showAllWorkers &&
        (selectedLeafIds == null || selectedLeafIds.isEmpty)) {
      items = items
          .where(
            (worker) =>
                worker.primaryCategoryIds.isNotEmpty ||
                worker.canDoCategoryIds.isNotEmpty,
          )
          .toList();
    }

    if (!_showAllWorkers &&
        selectedLeafIds != null &&
        selectedLeafIds.isNotEmpty) {
      items = items.where((worker) {
        final match = _workerMatchType(worker, selectedLeafIds);
        return match == CategoryMatchType.primary ||
            match == CategoryMatchType.canDo;
      }).toList();
    }

    switch (_sortOption) {
      case SortOption.bestMatch:
        items.sort((a, b) {
          final rankA = _workerMatchType(a, selectedLeafIds).rank;
          final rankB = _workerMatchType(b, selectedLeafIds).rank;
          if (rankA != rankB) return rankA.compareTo(rankB);
          return b.rating.compareTo(a.rating);
        });
        break;
      case SortOption.ratingDesc:
        items.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    return items;
  }

  Future<void> _refresh() async {
    await _fetchInitial();
  }

  String _selectedNodeLabel(String localeCode) {
    final nodeId = _selectedCategoryNodeId;
    if (nodeId == null || !_categoryRepository.isInitialized) {
      return 'Барлық санаттар';
    }
    final node = _categoryRepository.byId[nodeId];
    if (node == null) return 'Барлық санаттар';
    return node.localizedName(localeCode);
  }

  void _openFilters() {
    final searchCtrl = TextEditingController();
    List<String> filteredCities = CityRepository.all();
    String? tempCity = _selectedCity;
    String? tempCategoryNodeId = _selectedCategoryNodeId;
    SortOption tempSort = _sortOption;
    bool tempShowAllWorkers = _showAllWorkers;
    final localeCode = resolveCategoryLocaleCode(
      Localizations.localeOf(context),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Сүзгілер', style: AppTypography.h3),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (value) {
                      setModalState(() {
                        filteredCities = CityRepository.search(value);
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Қаланы іздеу',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final city in filteredCities.take(12))
                        AppChoiceChip(
                          label: city,
                          selected: tempCity == city,
                          onTap: () => setModalState(() => tempCity = city),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Категория', style: AppTypography.caption),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tempCategoryNodeId == null
                              ? 'Барлық санаттар'
                              : (_categoryRepository.byId[tempCategoryNodeId]
                                        ?.localizedName(localeCode) ??
                                    'Барлық санаттар'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _categoryRepository.init();
                          if (!context.mounted) return;
                          final picked =
                              await CategoryNodeFilterPicker.pickNode(
                                context: context,
                                title: 'Санат бойынша сүзгі',
                                role: CategoryPickerRole.client,
                                initialNodeId: tempCategoryNodeId,
                                repository: _categoryRepository,
                              );
                          if (!context.mounted) return;
                          setModalState(() => tempCategoryNodeId = picked);
                        },
                        icon: const Icon(Icons.category_outlined, size: 16),
                        label: const Text('Select'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    title: const Text('Барлық шеберді көрсету'),
                    subtitle: const Text(
                      'Өшірілсе, тек Негізгі және Қосымша сәйкестік көрсетіледі.',
                    ),
                    value: tempShowAllWorkers,
                    onChanged: (value) {
                      setModalState(() => tempShowAllWorkers = value);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Text('Сұрыптау', style: AppTypography.caption),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      AppChoiceChip(
                        label: 'Ең жақсы сәйкестік',
                        selected: tempSort == SortOption.bestMatch,
                        onTap: () => setModalState(
                          () => tempSort = SortOption.bestMatch,
                        ),
                      ),
                      AppChoiceChip(
                        label: 'Рейтинг ↑',
                        selected: tempSort == SortOption.ratingDesc,
                        onTap: () => setModalState(
                          () => tempSort = SortOption.ratingDesc,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempCity = null;
                              tempCategoryNodeId = null;
                              tempSort = SortOption.bestMatch;
                              tempShowAllWorkers = true;
                            });
                          },
                          child: const Text('Тазалау'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final previousCity = _selectedCity;
                            setState(() {
                              _selectedCity = tempCity;
                              _selectedCategoryNodeId = tempCategoryNodeId;
                              _sortOption = tempSort;
                              _showAllWorkers = tempShowAllWorkers;
                            });
                            Navigator.pop(context);
                            if (previousCity != _selectedCity) {
                              _fetchInitial();
                            }
                          },
                          child: const Text('Қолдану'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openCityQuickPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return CityPickerSheet(
          selectedCity: _selectedCity,
          onSelect: (city) {
            setState(() => _selectedCity = city);
            Navigator.pop(context);
            _fetchInitial();
          },
        );
      },
    );
  }

  Future<void> _openCategoryQuickPicker() async {
    await _categoryRepository.init();
    if (!mounted) return;
    final selected = await CategoryNodeFilterPicker.pickNode(
      context: context,
      title: 'Санат бойынша сүзгі',
      role: CategoryPickerRole.client,
      initialNodeId: _selectedCategoryNodeId,
      repository: _categoryRepository,
    );
    if (!mounted) return;
    setState(() => _selectedCategoryNodeId = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.gold,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSearch()),
              SliverToBoxAdapter(child: _buildCategories()),
              if (_isLoading)
                _buildSkeletons()
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    title: 'Қате орын алды',
                    message: _error!,
                    actionLabel: 'Қайта көру',
                    onAction: _fetchInitial,
                  ),
                )
              else if (_visibleWorkers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    title: 'Нәтиже табылмады',
                    message: 'Сүзгілерді өзгертіп көріңіз',
                    actionLabel: 'Сүзгілерді тазалау',
                    onAction: () {
                      setState(() {
                        _selectedCity = null;
                        _selectedCategoryNodeId = null;
                        _sortOption = SortOption.bestMatch;
                        _showAllWorkers = true;
                        _searchController.clear();
                        _searchQuery = '';
                      });
                      _fetchInitial();
                    },
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final worker = _visibleWorkers[index];
                    final matchType = _workerMatchType(
                      worker,
                      _selectedLeafIds(),
                    );
                    final badge = _selectedCategoryNodeId == null
                        ? null
                        : matchType.badgeLabel;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkerDetailScreen(worker: worker),
                        ),
                      ),
                      child: WorkerMiniCard(worker: worker, matchBadge: badge),
                    );
                  }, childCount: _visibleWorkers.length),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isLoadingMore
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                          ),
                        )
                      : const SizedBox(height: 100),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _openCityQuickPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.location_solid,
                      color: AppColors.gold,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedCity ?? 'Барлық қала',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.person, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: AppSearchField(
        controller: _searchController,
        hint: 'Шебер іздеу...',
        onChanged: _onSearchChanged,
        onFilterTap: _openFilters,
        activeFilterCount: _activeFiltersCount,
      ),
    );
  }

  Widget _buildCategories() {
    final localeCode = resolveCategoryLocaleCode(
      Localizations.localeOf(context),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: AppChoiceChip(
              label: _selectedNodeLabel(localeCode),
              selected: _selectedCategoryNodeId != null,
              onTap: _openCategoryQuickPicker,
            ),
          ),
          const SizedBox(width: 10),
          if (_selectedCategoryNodeId != null)
            IconButton(
              onPressed: () => setState(() => _selectedCategoryNodeId = null),
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }

  SliverList _buildSkeletons() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              const SkeletonBox(width: 72, height: 72, radius: AppRadii.md),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 120, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 180, height: 16),
                    SizedBox(height: 8),
                    SkeletonBox(width: 90, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      }, childCount: 6),
    );
  }
}
