import 'package:flutter/material.dart';
import 'package:kuryl_kz/features/categories/data/category_repository.dart';
import 'package:kuryl_kz/features/categories/models/category_node.dart';
import 'package:kuryl_kz/features/categories/utils/category_locale.dart';

enum CategoryPickerMode { singleLeaf, multiLeaf }

enum CategoryPickerRole { client, worker }

class CategoryPicker {
  const CategoryPicker._();

  static Future<String?> pickSingleLeaf({
    required BuildContext context,
    required String title,
    required CategoryPickerRole role,
    String? initialLeafId,
    CategoryRepository? repository,
  }) async {
    final result = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (_) => _CategoryPickerScreen(
          title: title,
          role: role,
          mode: CategoryPickerMode.singleLeaf,
          initialSelectedIds: initialLeafId == null
              ? const <String>{}
              : <String>{initialLeafId},
          repository: repository ?? CategoryRepository.instance,
          selectionLimit: 1,
        ),
      ),
    );
    if (result == null || result.isEmpty) return null;
    return result.first;
  }

  static Future<List<String>?> pickMultiLeaf({
    required BuildContext context,
    required String title,
    required CategoryPickerRole role,
    required int selectionLimit,
    List<String> initialLeafIds = const <String>[],
    CategoryRepository? repository,
  }) async {
    final result = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (_) => _CategoryPickerScreen(
          title: title,
          role: role,
          mode: CategoryPickerMode.multiLeaf,
          initialSelectedIds: initialLeafIds.toSet(),
          repository: repository ?? CategoryRepository.instance,
          selectionLimit: selectionLimit,
        ),
      ),
    );
    if (result == null) return null;
    return result.toList(growable: false);
  }
}

class _CategoryPickerScreen extends StatefulWidget {
  const _CategoryPickerScreen({
    required this.title,
    required this.role,
    required this.mode,
    required this.initialSelectedIds,
    required this.selectionLimit,
    required this.repository,
  });

  final String title;
  final CategoryPickerRole role;
  final CategoryPickerMode mode;
  final Set<String> initialSelectedIds;
  final int selectionLimit;
  final CategoryRepository repository;

  @override
  State<_CategoryPickerScreen> createState() => _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends State<_CategoryPickerScreen> {
  final TextEditingController _searchController = TextEditingController();

  late final Set<String> _selectedIds;
  late Future<void> _initFuture;

  bool _isSearchMode = false;
  String _query = '';
  String? _currentNodeId;

  bool get _isSingle => widget.mode == CategoryPickerMode.singleLeaf;

  _CategoryPalette get _palette => _CategoryPalette.forRole(widget.role);

  @override
  void initState() {
    super.initState();
    _selectedIds = <String>{...widget.initialSelectedIds};
    _initFuture = widget.repository.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _query = '';
        _searchController.clear();
      }
    });
  }

  void _openNode(String nodeId) {
    setState(() => _currentNodeId = nodeId);
  }

  void _goToParent() {
    if (_currentNodeId == null) return;
    final current = widget.repository.byId[_currentNodeId!];
    setState(() => _currentNodeId = current?.parentId);
  }

  void _selectLeaf(String leafId) {
    final leaf = widget.repository.getLeaf(leafId);
    if (leaf == null) return;

    if (_isSingle) {
      Navigator.of(context).pop(<String>{leaf.id});
      return;
    }

    final exists = _selectedIds.contains(leaf.id);
    if (!exists && _selectedIds.length >= widget.selectionLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Лимитке жетті: ең көбі ${widget.selectionLimit} санат.',
          ),
        ),
      );
      return;
    }

    setState(() {
      if (exists) {
        _selectedIds.remove(leaf.id);
      } else {
        _selectedIds.add(leaf.id);
      }
    });
  }

  List<CategoryNode> _searchResults(String localeCode) {
    return widget.repository.searchLeaves(_query, localeCode, limit: 50);
  }

  List<CategoryNode> _browseNodes() {
    if (_currentNodeId == null) {
      return widget.repository.getRoots();
    }
    return widget.repository.getChildren(_currentNodeId);
  }

  String _breadcrumbForNode(String categoryId, String localeCode) {
    final breadcrumb = widget.repository.getBreadcrumb(categoryId);
    if (breadcrumb.isEmpty) return '';
    return breadcrumb
        .map((node) => node.localizedName(localeCode))
        .where((item) => item.trim().isNotEmpty)
        .join(' > ');
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: _palette.surface,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'Санат іздеу',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: _palette.searchFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _palette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _palette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _palette.accent, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildPathHeader(String localeCode) {
    if (_isSearchMode) return const SizedBox.shrink();
    if (_currentNodeId == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        color: _palette.surface,
        child: Text(
          'Барлық санаттар',
          style: TextStyle(
            color: _palette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final breadcrumb = widget.repository.getBreadcrumb(_currentNodeId!);
    final label = breadcrumb
        .map((node) => node.localizedName(localeCode))
        .join(' > ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      color: _palette.surface,
      child: Row(
        children: [
          IconButton(
            onPressed: _goToParent,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _palette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseList(String localeCode) {
    final nodes = _browseNodes();
    if (nodes.isEmpty) {
      return _buildEmpty('Санат табылмады.');
    }

    return ListView.builder(
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        final leafCount = node.isLeaf
            ? 1
            : widget.repository.getLeavesUnder(node.id).length;
        final isSelected = _selectedIds.contains(node.id);

        return ListTile(
          title: Text(
            node.localizedName(localeCode),
            style: TextStyle(
              color: _palette.textPrimary,
              fontWeight: node.isLeaf ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          subtitle: node.isLeaf
              ? Text(
                  _breadcrumbForNode(node.id, localeCode),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _palette.textSecondary, fontSize: 12),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _palette.badgeFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  leafCount.toString(),
                  style: TextStyle(
                    color: _palette.badgeText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (node.isLeaf && !_isSingle)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _selectLeaf(node.id),
                  activeColor: _palette.accent,
                )
              else
                Icon(
                  node.isLeaf
                      ? Icons.check_circle_outline
                      : Icons.chevron_right_rounded,
                  color: _palette.textSecondary,
                ),
            ],
          ),
          onTap: () {
            if (node.isLeaf) {
              _selectLeaf(node.id);
            } else {
              _openNode(node.id);
            }
          },
        );
      },
    );
  }

  Widget _buildSearchList(String localeCode) {
    final leaves = _searchResults(localeCode);
    if (leaves.isEmpty) {
      return _buildEmpty('Сәйкес санат табылмады.');
    }

    return ListView.builder(
      itemCount: leaves.length,
      itemBuilder: (context, index) {
        final leaf = leaves[index];
        final selected = _selectedIds.contains(leaf.id);
        final breadcrumb = _breadcrumbForNode(leaf.id, localeCode);

        return ListTile(
          title: Text(
            leaf.localizedName(localeCode),
            style: TextStyle(
              color: _palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            breadcrumb,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _palette.textSecondary, fontSize: 12),
          ),
          trailing: _isSingle
              ? Icon(Icons.chevron_right_rounded, color: _palette.textSecondary)
              : Checkbox(
                  value: selected,
                  onChanged: (_) => _selectLeaf(leaf.id),
                  activeColor: _palette.accent,
                ),
          onTap: () => _selectLeaf(leaf.id),
        );
      },
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Text(text, style: TextStyle(color: _palette.textSecondary)),
    );
  }

  Widget _buildBottomBar() {
    if (_isSingle) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _palette.surface,
        border: Border(top: BorderSide(color: _palette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedIds.length}/${widget.selectionLimit} таңдалды',
              style: TextStyle(
                color: _palette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_selectedIds),
            style: FilledButton.styleFrom(
              backgroundColor: _palette.accent,
              foregroundColor: _palette.accentOnColor,
            ),
            child: const Text('Дайын'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = resolveCategoryLocaleCode(
      Localizations.localeOf(context),
    );

    return Scaffold(
      backgroundColor: _palette.background,
      appBar: AppBar(
        backgroundColor: _palette.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _toggleSearchMode,
            icon: Icon(_isSearchMode ? Icons.close : Icons.search),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildEmpty('Санаттарды жүктеу сәтсіз.');
          }

          return Column(
            children: [
              if (_isSearchMode) _buildSearchField(),
              _buildPathHeader(localeCode),
              Expanded(
                child: _isSearchMode
                    ? _buildSearchList(localeCode)
                    : _buildBrowseList(localeCode),
              ),
              _buildBottomBar(),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryPalette {
  const _CategoryPalette({
    required this.background,
    required this.surface,
    required this.searchFill,
    required this.border,
    required this.accent,
    required this.accentOnColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.badgeFill,
    required this.badgeText,
  });

  final Color background;
  final Color surface;
  final Color searchFill;
  final Color border;
  final Color accent;
  final Color accentOnColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color badgeFill;
  final Color badgeText;

  factory _CategoryPalette.forRole(CategoryPickerRole role) {
    switch (role) {
      case CategoryPickerRole.worker:
        return const _CategoryPalette(
          background: Color(0xFFF8F6F1),
          surface: Colors.white,
          searchFill: Color(0xFFFFFBED),
          border: Color(0xFFE6E1D8),
          accent: Color(0xFFF3C24D),
          accentOnColor: Colors.black,
          textPrimary: Color(0xFF1B1B1B),
          textSecondary: Color(0xFF6E6557),
          badgeFill: Color(0xFFFFF0C7),
          badgeText: Color(0xFF8A6300),
        );
      case CategoryPickerRole.client:
        return const _CategoryPalette(
          background: Color(0xFF0F1115),
          surface: Color(0xFF161A20),
          searchFill: Color(0xFF20252D),
          border: Color(0xFF2A313B),
          accent: Color(0xFFF5C443),
          accentOnColor: Colors.black,
          textPrimary: Color(0xFFF7F8FA),
          textSecondary: Color(0xFF9BA7B7),
          badgeFill: Color(0x332F2610),
          badgeText: Color(0xFFF5C443),
        );
    }
  }
}
