import 'package:flutter/material.dart';
import 'package:kuryl_kz/features/categories/data/category_repository.dart';
import 'package:kuryl_kz/features/categories/ui/category_picker.dart';
import 'package:kuryl_kz/features/categories/utils/category_locale.dart';

class CategoryNodeFilterPicker {
  const CategoryNodeFilterPicker._();

  static Future<String?> pickNode({
    required BuildContext context,
    required String title,
    required CategoryPickerRole role,
    String? initialNodeId,
    CategoryRepository? repository,
  }) {
    return Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => _CategoryNodeFilterScreen(
          title: title,
          role: role,
          initialNodeId: initialNodeId,
          repository: repository ?? CategoryRepository.instance,
        ),
      ),
    );
  }
}

class _CategoryNodeFilterScreen extends StatefulWidget {
  const _CategoryNodeFilterScreen({
    required this.title,
    required this.role,
    required this.initialNodeId,
    required this.repository,
  });

  final String title;
  final CategoryPickerRole role;
  final String? initialNodeId;
  final CategoryRepository repository;

  @override
  State<_CategoryNodeFilterScreen> createState() =>
      _CategoryNodeFilterScreenState();
}

class _CategoryNodeFilterScreenState extends State<_CategoryNodeFilterScreen> {
  late Future<void> _initFuture;
  String? _currentNodeId;

  _CategoryPalette get _palette => _CategoryPalette.forRole(widget.role);

  @override
  void initState() {
    super.initState();
    _currentNodeId = widget.initialNodeId;
    _initFuture = widget.repository.init();
  }

  void _goBack() {
    final currentId = _currentNodeId;
    if (currentId == null) {
      Navigator.of(context).pop();
      return;
    }
    final currentNode = widget.repository.byId[currentId];
    setState(() => _currentNodeId = currentNode?.parentId);
  }

  List<String> _breadcrumb(String localeCode) {
    final current = _currentNodeId;
    if (current == null) return const <String>[];
    return widget.repository
        .getBreadcrumb(current)
        .map((node) => node.localizedName(localeCode))
        .toList(growable: false);
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
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Тазалау', style: TextStyle(color: _palette.accent)),
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
            return const Center(child: Text('Санаттарды жүктеу сәтсіз.'));
          }

          final nodes = _currentNodeId == null
              ? widget.repository.getRoots()
              : widget.repository.getChildren(_currentNodeId);
          final breadcrumb = _breadcrumb(localeCode);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                color: _palette.surface,
                child: Text(
                  breadcrumb.isEmpty
                      ? 'Барлық санаттар'
                      : breadcrumb.join(' > '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _palette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: nodes.length,
                  itemBuilder: (context, index) {
                    final node = nodes[index];
                    final leafCount = node.isLeaf
                        ? 1
                        : widget.repository.getLeavesUnder(node.id).length;

                    return ListTile(
                      title: Text(
                        node.localizedName(localeCode),
                        style: TextStyle(color: _palette.textPrimary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                          Navigator.of(context).pop(node.id);
                        } else {
                          setState(() => _currentNodeId = node.id);
                        }
                      },
                    );
                  },
                ),
              ),
              if (_currentNodeId != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: _palette.surface,
                    border: Border(top: BorderSide(color: _palette.border)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_currentNodeId),
                      style: FilledButton.styleFrom(
                        backgroundColor: _palette.accent,
                        foregroundColor: _palette.accentOnColor,
                      ),
                      child: const Text('Осы тармақпен сүзу'),
                    ),
                  ),
                ),
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
