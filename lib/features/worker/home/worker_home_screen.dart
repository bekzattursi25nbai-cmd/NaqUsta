import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/app_loading.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';
import 'package:kuryl_kz/features/categories/data/category_repository.dart';
import 'package:kuryl_kz/features/categories/models/category_match.dart';
import 'package:kuryl_kz/features/categories/models/category_worker_profile.dart';
import 'package:kuryl_kz/features/categories/ui/category_node_filter_picker.dart';
import 'package:kuryl_kz/features/categories/ui/category_picker.dart';
import 'package:kuryl_kz/features/categories/utils/category_locale.dart';
import 'package:kuryl_kz/features/location/models/kato_models.dart';
import 'package:kuryl_kz/features/marketplace/models/order_model.dart';
import 'package:kuryl_kz/features/marketplace/services/order_service.dart';

import 'worker_job_detail_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  final String fallbackUserName;

  const WorkerHomeScreen({super.key, this.fallbackUserName = 'Шебер'});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

enum _WorkerFeedMode { forYou, all }

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final OrderService _orderService = OrderService();
  final CategoryRepository _categoryRepository = CategoryRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  bool isOnline = true;
  String _searchQuery = '';
  String _selectedCategory = 'Барлығы';
  String? _selectedCategoryNodeId;
  String _locationFilter = '';
  bool _withPhotoOnly = false;
  List<MarketplaceOrder> _latestOpenOrders = const <MarketplaceOrder>[];
  LocationBreakdown? _workerLocation;
  WorkerCoverageMode _coverageMode = WorkerCoverageMode.exact;
  String? _coverageHint;
  String _workerName = 'Шебер';
  _WorkerFeedMode _feedMode = _WorkerFeedMode.forYou;
  List<String> _primaryCategoryIds = const <String>[];
  List<String> _canDoCategoryIds = const <String>[];

  @override
  void initState() {
    super.initState();
    _categoryRepository.init().then((_) {
      if (mounted) setState(() {});
    });
    _loadWorkerCoverage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkerCoverage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _workerLocation = null;
        _workerName = widget.fallbackUserName;
        _coverageHint =
            'Профиль анықталмады. Барлық OPEN тапсырыстар көрсетілуде.';
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? <String, dynamic>{};
      final parsedLocation = LocationBreakdown.fromDocumentData(data);
      final parsedCoverage = WorkerCoverageModeX.fromWire(
        data['coverageMode']?.toString(),
      );
      final parsedName = _resolveWorkerName(data);
      final parsedPrimaryIds = _asStringList(data['primaryCategoryIds']);
      final parsedCanDoIds = _asStringList(
        data['canDoCategoryIds'],
      ).where((id) => !parsedPrimaryIds.contains(id)).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _workerLocation = parsedLocation;
        _coverageMode = parsedCoverage;
        _workerName = parsedName;
        _primaryCategoryIds = parsedPrimaryIds;
        _canDoCategoryIds = parsedCanDoIds;
        _coverageHint = parsedLocation == null
            ? 'Сіздің локацияңыз толтырылмаған. Барлық OPEN тапсырыстар көрсетілуде.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _workerLocation = null;
        _workerName = widget.fallbackUserName;
        _primaryCategoryIds = const <String>[];
        _canDoCategoryIds = const <String>[];
        _coverageHint = 'Локация бойынша сүзгі жүктелмеді: $e';
      });
    }
  }

  String _resolveWorkerName(Map<String, dynamic> data) {
    final fullName = (data['fullName'] ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName;

    final name = (data['name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;

    final firstName = (data['firstName'] ?? '').toString().trim();
    if (firstName.isNotEmpty) return firstName;

    return widget.fallbackUserName;
  }

  Stream<List<MarketplaceOrder>> _ordersStream() {
    final location = _workerLocation;
    if (location == null || !location.isValid) {
      return _orderService.streamOpenOrders();
    }

    return _orderService.streamOpenOrdersByCoverage(
      coverageMode: _coverageMode,
      workerLocation: location,
    );
  }

  int get _activeFilterCount {
    var count = 0;
    if (_searchQuery.trim().isNotEmpty) count++;
    if (_selectedCategory != 'Барлығы') count++;
    if (_selectedCategoryNodeId != null) count++;
    if (_locationFilter.trim().isNotEmpty) count++;
    if (_withPhotoOnly) count++;
    if (_feedMode != _WorkerFeedMode.forYou) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCategory = 'Барлығы';
      _selectedCategoryNodeId = null;
      _feedMode = _WorkerFeedMode.forYou;
      _locationFilter = '';
      _withPhotoOnly = false;
    });
  }

  Future<void> _openFilters() async {
    final localeCode = resolveCategoryLocaleCode(
      Localizations.localeOf(context),
    );
    final result = await showModalBottomSheet<_FilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (_) {
        return _WorkerFilterSheet(
          categories: _availableCategoryLabels(localeCode),
          categoryResolver: _categoryIcon,
          currentSearchQuery: _searchQuery,
          currentCategory: _selectedCategory,
          currentLocation: _locationFilter,
          currentWithPhotoOnly: _withPhotoOnly,
          sourceOrders: _latestOpenOrders,
          categoryLabelOfOrder: (order) =>
              _orderCategoryLeafName(order, localeCode),
        );
      },
    );

    if (result == null) return;
    setState(() {
      _searchQuery = result.searchQuery;
      _searchController
        ..text = _searchQuery
        ..selection = TextSelection.collapsed(offset: _searchQuery.length);
      _selectedCategory = result.category;
      _locationFilter = result.location;
      _withPhotoOnly = result.withPhotoOnly;
    });
  }

  CategoryWorkerProfile get _workerCategoryProfile => CategoryWorkerProfile(
    primaryCategoryIds: _primaryCategoryIds,
    canDoCategoryIds: _canDoCategoryIds,
  ).normalized();

  CategoryMatchType _resolveOrderMatchType(MarketplaceOrder order) {
    if (!_categoryRepository.isInitialized) return CategoryMatchType.other;
    // Match affects sort/badges only; workers can still apply to any order.
    return _categoryRepository.resolveMatchType(
      _workerCategoryProfile,
      order.categoryId,
    );
  }

  Future<void> _openCategoryNodeFilter() async {
    await _categoryRepository.init();
    if (!mounted) return;
    final selected = await CategoryNodeFilterPicker.pickNode(
      context: context,
      title: 'Санат бойынша сүзгі',
      role: CategoryPickerRole.worker,
      initialNodeId: _selectedCategoryNodeId,
      repository: _categoryRepository,
    );
    if (!mounted) return;
    setState(() => _selectedCategoryNodeId = selected);
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

  String _orderCategoryLeafName(MarketplaceOrder order, String localeCode) {
    if (!_categoryRepository.isInitialized) return order.categoryName;
    final leaf = _categoryRepository.getLeaf(order.categoryId);
    if (leaf == null) return order.categoryName;
    return leaf.localizedName(localeCode);
  }

  String _orderCategoryBreadcrumb(MarketplaceOrder order, String localeCode) {
    if (!_categoryRepository.isInitialized) return order.categoryName;
    final breadcrumb = _categoryRepository.getBreadcrumb(order.categoryId);
    if (breadcrumb.isEmpty) return order.categoryName;
    return breadcrumb.map((node) => node.localizedName(localeCode)).join(' > ');
  }

  List<String> _availableCategoryLabels(String localeCode) {
    final counts = <String, int>{};
    for (final order in _latestOpenOrders) {
      final label = _orderCategoryLeafName(order, localeCode).trim();
      if (label.isEmpty) continue;
      counts[label] = (counts[label] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return a.key.compareTo(b.key);
      });

    return <String>['Барлығы', ...sorted.map((entry) => entry.key)];
  }

  bool _matchesOrderSearch(
    MarketplaceOrder order,
    String query,
    String localeCode,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    final leafName = _orderCategoryLeafName(order, localeCode);
    final breadcrumb = _orderCategoryBreadcrumb(order, localeCode);

    final haystack =
        '${order.title} ${order.description} $leafName $breadcrumb ${order.locationShort}'
            .toLowerCase();
    return haystack.contains(normalizedQuery);
  }

  List<MarketplaceOrder> _applyFilters(
    List<MarketplaceOrder> source,
    String localeCode,
  ) {
    var list = List<MarketplaceOrder>.from(source);

    if (_searchQuery.trim().isNotEmpty) {
      list = list
          .where((item) => _matchesOrderSearch(item, _searchQuery, localeCode))
          .toList();
    }

    if (_selectedCategory != 'Барлығы') {
      list = list
          .where(
            (item) =>
                _orderCategoryLeafName(item, localeCode) == _selectedCategory,
          )
          .toList();
    }

    if (_locationFilter.trim().isNotEmpty) {
      final q = _locationFilter.trim().toLowerCase();
      list = list
          .where((item) => item.locationShort.toLowerCase().contains(q))
          .toList();
    }

    if (_withPhotoOnly) {
      list = list.where((item) => item.hasPhoto).toList();
    }

    final nodeId = _selectedCategoryNodeId;
    if (nodeId != null && _categoryRepository.isInitialized) {
      final selectedNode = _categoryRepository.byId[nodeId];
      if (selectedNode != null) {
        final allowedLeafIds = selectedNode.isLeaf
            ? <String>{selectedNode.id}
            : _categoryRepository.leafIdsUnderNode(selectedNode.id);
        list = list
            .where((item) => allowedLeafIds.contains(item.categoryId))
            .toList();
      }
    }

    if (_feedMode == _WorkerFeedMode.forYou) {
      list = list.where((item) {
        final matchType = _resolveOrderMatchType(item);
        return matchType == CategoryMatchType.primary ||
            matchType == CategoryMatchType.canDo;
      }).toList();
    }

    list.sort((a, b) {
      final matchDiff = _resolveOrderMatchType(
        a,
      ).rank.compareTo(_resolveOrderMatchType(b).rank);
      if (matchDiff != 0) return matchDiff;
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return list;
  }

  String _timeAgo(DateTime? value) {
    if (value == null) return 'Жаңа';

    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'Қазір';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин бұрын';
    if (diff.inHours < 24) return '${diff.inHours} сағ бұрын';
    if (diff.inDays < 7) return '${diff.inDays} күн бұрын';

    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    return '$dd.$mm';
  }

  String _categoryIcon(String categoryName) {
    final text = categoryName.toLowerCase();
    if (text.contains('электр') || text.contains('розетка')) return '⚡';
    if (text.contains('сантех') || text.contains('құбыр')) return '🚰';
    if (text.contains('боя') || text.contains('сыр')) return '🎨';
    if (text.contains('шатыр')) return '🏠';
    if (text.contains('есік') || text.contains('терезе')) return '🚪';
    if (text.contains('еден')) return '🧱';
    return '🛠️';
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = resolveCategoryLocaleCode(
      Localizations.localeOf(context),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SizedBox(
                  width: double.infinity,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'OPEN FEED',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _workerName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: isOnline,
                              activeThumbColor: Colors.amber,
                              onChanged: (v) => setState(() => isOnline = v),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Жаңа тапсырыстар',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    FilledButton.tonalIcon(
                                      onPressed: _openFilters,
                                      icon: const Icon(
                                        Icons.filter_alt_outlined,
                                        size: 18,
                                      ),
                                      label: Text(
                                        _activeFilterCount == 0
                                            ? 'Сүзгі'
                                            : 'Сүзгі ($_activeFilterCount)',
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFFF5D8,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF92400E,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 11,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  10,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFCF4),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFEEDCA2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.search_rounded,
                                        size: 20,
                                        color: Color(0xFFB45309),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          onChanged: (value) {
                                            setState(
                                              () => _searchQuery = value
                                                  .trimLeft(),
                                            );
                                          },
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Атауы бойынша іздеу (мысалы: розетка)',
                                            border: InputBorder.none,
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      if (_searchQuery.trim().isNotEmpty)
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              _searchQuery = '';
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      const SizedBox(width: 4),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  10,
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Сізге'),
                                      selected:
                                          _feedMode == _WorkerFeedMode.forYou,
                                      onSelected: (_) {
                                        setState(() {
                                          _feedMode = _WorkerFeedMode.forYou;
                                        });
                                      },
                                    ),
                                    ChoiceChip(
                                      label: const Text('Барлығы'),
                                      selected:
                                          _feedMode == _WorkerFeedMode.all,
                                      onSelected: (_) {
                                        setState(() {
                                          _feedMode = _WorkerFeedMode.all;
                                        });
                                      },
                                    ),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 220,
                                      ),
                                      child: OutlinedButton.icon(
                                        onPressed: _openCategoryNodeFilter,
                                        icon: const Icon(
                                          Icons.category_outlined,
                                          size: 16,
                                        ),
                                        label: Text(
                                          _selectedNodeLabel(localeCode),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_searchQuery.trim().isNotEmpty ||
                                  _selectedCategory != 'Барлығы' ||
                                  _selectedCategoryNodeId != null ||
                                  _feedMode != _WorkerFeedMode.forYou ||
                                  _locationFilter.isNotEmpty ||
                                  _withPhotoOnly)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    10,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      10,
                                      12,
                                      12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBF0),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFF4E4B0),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.tune_rounded,
                                              size: 16,
                                              color: Color(0xFFB45309),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Қолданылған сүзгілер',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFB45309),
                                              ),
                                            ),
                                            const Spacer(),
                                            TextButton(
                                              onPressed: _clearAllFilters,
                                              style: TextButton.styleFrom(
                                                minimumSize: Size.zero,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: const Text('Тазалау'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            if (_searchQuery.trim().isNotEmpty)
                                              _ActiveFilterChip(
                                                text: 'Іздеу: $_searchQuery',
                                                onRemove: () {
                                                  setState(() {
                                                    _searchQuery = '';
                                                    _searchController.clear();
                                                  });
                                                },
                                              ),
                                            if (_selectedCategory != 'Барлығы')
                                              _ActiveFilterChip(
                                                text: _selectedCategory,
                                                onRemove: () {
                                                  setState(() {
                                                    _selectedCategory =
                                                        'Барлығы';
                                                  });
                                                },
                                              ),
                                            if (_selectedCategoryNodeId != null)
                                              _ActiveFilterChip(
                                                text: _selectedNodeLabel(
                                                  localeCode,
                                                ),
                                                onRemove: () {
                                                  setState(() {
                                                    _selectedCategoryNodeId =
                                                        null;
                                                  });
                                                },
                                              ),
                                            if (_feedMode !=
                                                _WorkerFeedMode.forYou)
                                              _ActiveFilterChip(
                                                text: 'Барлық нәтиже',
                                                onRemove: () {
                                                  setState(() {
                                                    _feedMode =
                                                        _WorkerFeedMode.forYou;
                                                  });
                                                },
                                              ),
                                            if (_locationFilter.isNotEmpty)
                                              _ActiveFilterChip(
                                                text: _locationFilter,
                                                onRemove: () {
                                                  setState(() {
                                                    _locationFilter = '';
                                                  });
                                                },
                                              ),
                                            if (_withPhotoOnly)
                                              _ActiveFilterChip(
                                                text: 'Тек фотомен',
                                                onRemove: () {
                                                  setState(() {
                                                    _withPhotoOnly = false;
                                                  });
                                                },
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (_workerLocation != null ||
                                  _coverageHint != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    10,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F8FF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFD0DFF8),
                                      ),
                                    ),
                                    child: Text(
                                      _coverageHint ??
                                          'Көріну аймағы: ${_coverageMode.kzLabel}',
                                      style: const TextStyle(
                                        color: Color(0xFF1E3A8A),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: StreamBuilder<List<MarketplaceOrder>>(
                                  stream: _ordersStream(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Text(
                                            'Қате: ${snapshot.error}',
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    if (!snapshot.hasData) {
                                      return const Center(
                                        child: AppLoadingIndicator(
                                          size: 26,
                                          strokeWidth: 2.5,
                                          color: Colors.amber,
                                        ),
                                      );
                                    }

                                    _latestOpenOrders = snapshot.data!;
                                    final orders = _applyFilters(
                                      _latestOpenOrders,
                                      localeCode,
                                    );
                                    if (orders.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          'Ашық тапсырыс табылмады',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      itemCount: orders.length,
                                      itemBuilder: (context, index) {
                                        final order = orders[index];
                                        final imageUrl = order.photos.isNotEmpty
                                            ? order.photos.first
                                            : null;
                                        final matchType =
                                            _resolveOrderMatchType(order);
                                        final leafName = _orderCategoryLeafName(
                                          order,
                                          localeCode,
                                        );
                                        final breadcrumb =
                                            _orderCategoryBreadcrumb(
                                              order,
                                              localeCode,
                                            );

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    WorkerJobDetailScreen(
                                                      orderId: order.id,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: _OpenOrderCard(
                                            imageUrl: imageUrl,
                                            title: order.title,
                                            category: leafName,
                                            breadcrumb: breadcrumb,
                                            matchType: matchType,
                                            categoryIcon: _categoryIcon(
                                              leafName,
                                            ),
                                            price: order.budgetLabel,
                                            locationShort: order.locationShort,
                                            postedAgo: _timeAgo(
                                              order.createdAt,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.text, required this.onRemove});

  final String text;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onRemove,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6DB),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFEAC86F)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.close_rounded, size: 14, color: Color(0xFFB45309)),
          ],
        ),
      ),
    );
  }
}

class _FilterSelection {
  const _FilterSelection({
    required this.searchQuery,
    required this.category,
    required this.location,
    required this.withPhotoOnly,
  });

  final String searchQuery;
  final String category;
  final String location;
  final bool withPhotoOnly;
}

class _WorkerFilterSheet extends StatefulWidget {
  const _WorkerFilterSheet({
    required this.categories,
    required this.categoryResolver,
    required this.currentSearchQuery,
    required this.currentCategory,
    required this.currentLocation,
    required this.currentWithPhotoOnly,
    required this.sourceOrders,
    required this.categoryLabelOfOrder,
  });

  final List<String> categories;
  final String Function(String categoryName) categoryResolver;
  final String currentSearchQuery;
  final String currentCategory;
  final String currentLocation;
  final bool currentWithPhotoOnly;
  final List<MarketplaceOrder> sourceOrders;
  final String Function(MarketplaceOrder order) categoryLabelOfOrder;

  @override
  State<_WorkerFilterSheet> createState() => _WorkerFilterSheetState();
}

class _WorkerFilterSheetState extends State<_WorkerFilterSheet> {
  late String _tempSearchQuery;
  late String _tempCategory;
  late String _tempLocation;
  late bool _tempWithPhotoOnly;
  late final TextEditingController _searchController;
  late final TextEditingController _categoryController;
  String _categoryQuery = '';
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _tempSearchQuery = widget.currentSearchQuery.trimLeft();
    _tempCategory = widget.currentCategory;
    _tempLocation = widget.currentLocation.trim();
    _tempWithPhotoOnly = widget.currentWithPhotoOnly;
    _searchController = TextEditingController(text: _tempSearchQuery);
    _categoryController = TextEditingController();
    _locationController = TextEditingController(text: _tempLocation);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  List<MarketplaceOrder> _applyLocalFilters(List<MarketplaceOrder> source) {
    var list = List<MarketplaceOrder>.from(source);

    if (_tempSearchQuery.trim().isNotEmpty) {
      final query = _tempSearchQuery.trim().toLowerCase();
      list = list.where((item) {
        final categoryLabel = widget.categoryLabelOfOrder(item);
        final text =
            '${item.title} ${item.description} ${item.locationShort} $categoryLabel'
                .toLowerCase();
        return text.contains(query);
      }).toList();
    }

    if (_tempCategory != 'Барлығы') {
      list = list
          .where((item) => widget.categoryLabelOfOrder(item) == _tempCategory)
          .toList();
    }

    if (_tempLocation.trim().isNotEmpty) {
      final query = _tempLocation.trim().toLowerCase();
      list = list
          .where((item) => item.locationShort.toLowerCase().contains(query))
          .toList();
    }

    if (_tempWithPhotoOnly) {
      list = list.where((item) => item.hasPhoto).toList();
    }

    return list;
  }

  int get _previewCount => _applyLocalFilters(widget.sourceOrders).length;

  List<String> get _filteredCategories {
    final query = _categoryQuery.trim().toLowerCase();
    if (query.isEmpty) return widget.categories;
    return widget.categories
        .where((category) => category.toLowerCase().contains(query))
        .toList(growable: false);
  }

  List<String> get _locationSuggestions {
    final counts = <String, int>{};
    for (final order in widget.sourceOrders) {
      final value = order.locationShort.trim();
      if (value.isEmpty) continue;
      counts[value] = (counts[value] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(8).map((item) => item.key).toList();
  }

  void _resetFilters() {
    setState(() {
      _tempSearchQuery = '';
      _tempCategory = 'Барлығы';
      _categoryQuery = '';
      _tempLocation = '';
      _tempWithPhotoOnly = false;
      _searchController.clear();
      _categoryController.clear();
      _locationController.clear();
    });
  }

  void _applyAndClose() {
    Navigator.of(context).pop(
      _FilterSelection(
        searchQuery: _tempSearchQuery.trim(),
        category: _tempCategory,
        location: _tempLocation.trim(),
        withPhotoOnly: _tempWithPhotoOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewCount = _previewCount;
    final suggestions = _locationSuggestions;
    final filteredCategories = _filteredCategories;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFEFEFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4D4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Сүзгілеу',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Тапсырысты тез табу үшін параметр таңдаңыз',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6DB),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFEAC86F)),
                          ),
                          child: Text(
                            '$previewCount нәтиже',
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      children: [
                        const Text(
                          'Іздеу',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _tempSearchQuery = value.trimLeft());
                          },
                          decoration: InputDecoration(
                            hintText: 'Тапсырыс атауы немесе сипаттамасы',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF9CA3AF),
                            ),
                            suffixIcon: _tempSearchQuery.trim().isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _tempSearchQuery = '';
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                  ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFF59E0B),
                                width: 1.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Категория',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _categoryController,
                          onChanged: (value) {
                            setState(() => _categoryQuery = value.trimLeft());
                          },
                          decoration: InputDecoration(
                            hintText: 'Категория іздеу',
                            prefixIcon: const Icon(
                              Icons.category_outlined,
                              color: Color(0xFF9CA3AF),
                            ),
                            suffixIcon: _categoryQuery.trim().isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _categoryController.clear();
                                        _categoryQuery = '';
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                  ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFF59E0B),
                                width: 1.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (filteredCategories.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              'Категория табылмады',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: filteredCategories.take(20).map((
                              category,
                            ) {
                              final selected = _tempCategory == category;
                              return _CategoryFilterChip(
                                icon: category == 'Барлығы'
                                    ? '✨'
                                    : widget.categoryResolver(category),
                                label: category,
                                selected: selected,
                                onTap: () {
                                  setState(() => _tempCategory = category);
                                },
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 18),
                        const Text(
                          'Қала / аудан',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _locationController,
                          onChanged: (value) {
                            setState(() => _tempLocation = value.trimLeft());
                          },
                          decoration: InputDecoration(
                            hintText: 'Мысалы: Алматы, Бостандық',
                            prefixIcon: const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF9CA3AF),
                            ),
                            suffixIcon: _tempLocation.trim().isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _locationController.clear();
                                        _tempLocation = '';
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                  ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFF59E0B),
                                width: 1.3,
                              ),
                            ),
                          ),
                        ),
                        if (suggestions.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: suggestions.map((city) {
                              final selected = _tempLocation.trim() == city;
                              return ChoiceChip(
                                label: Text(city),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    _tempLocation = city;
                                    _locationController.text = city;
                                  });
                                },
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? const Color(0xFF92400E)
                                      : const Color(0xFF4B5563),
                                  fontWeight: FontWeight.w600,
                                ),
                                selectedColor: const Color(0xFFFFF0C5),
                                backgroundColor: const Color(0xFFF3F4F6),
                                side: BorderSide(
                                  color: selected
                                      ? const Color(0xFFF4C74F)
                                      : const Color(0xFFE5E7EB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF5D8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.image_outlined,
                                  size: 20,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Тек фотомен',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Фотосы бар тапсырыстар ғана көрсетіледі',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _tempWithPhotoOnly,
                                onChanged: (value) {
                                  setState(() => _tempWithPhotoOnly = value);
                                },
                                activeThumbColor: const Color(0xFFFFD700),
                                activeTrackColor: const Color(0xFFFDE68A),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetFilters,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                            child: const Text('Тазалау'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyAndClose,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text('Қолдану ($previewCount)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1C3) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFF4C74F) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? const Color(0xFF92400E)
                    : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenOrderCard extends StatelessWidget {
  const _OpenOrderCard({
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.breadcrumb,
    required this.matchType,
    required this.categoryIcon,
    required this.price,
    required this.locationShort,
    required this.postedAgo,
  });

  final String? imageUrl;
  final String title;
  final String category;
  final String breadcrumb;
  final CategoryMatchType matchType;
  final String categoryIcon;
  final String price;
  final String locationShort;
  final String postedAgo;

  Color get _badgeColor {
    switch (matchType) {
      case CategoryMatchType.primary:
        return const Color(0xFFB45309);
      case CategoryMatchType.canDo:
        return const Color(0xFF1D4ED8);
      case CategoryMatchType.other:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 86,
              height: 86,
              child: imageUrl == null
                  ? Container(
                      color: const Color(0xFFF3F4F6),
                      alignment: Alignment.center,
                      child: Text(
                        categoryIcon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    )
                  : SafeNetworkImage(url: imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        matchType.badgeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      postedAgo,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  breadcrumb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationShort,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (matchType == CategoryMatchType.other) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Мамандығыңызға кірмейді, бірақ бәрібір өтінім бере аласыз.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);
}
