import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/data/city_repository.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';

class CityPickerSheet extends StatefulWidget {
  final String? selectedCity;
  final ValueChanged<String> onSelect;

  const CityPickerSheet({
    super.key,
    required this.selectedCity,
    required this.onSelect,
  });

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _cities = CityRepository.all();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _cities = CityRepository.search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + media.viewInsets.bottom),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF181B24), Color(0xFF0E1017)],
            ),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 260,
                maxHeight: media.size.height * 0.72,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Қаланы таңдаңыз', style: AppTypography.h3),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      style: AppTypography.body,
                      cursorColor: AppColors.gold,
                      decoration: InputDecoration(
                        hintText: 'Қаланы іздеу',
                        hintStyle: AppTypography.bodyMuted,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textMuted,
                        ),
                        suffixIcon: hasQuery
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearch('');
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.textSecondary,
                                ),
                                splashRadius: 20,
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface2.withValues(alpha: 0.9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          borderSide: const BorderSide(
                            color: AppColors.gold,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _cities.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              itemCount: _cities.length,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                    height: 1,
                                    color: AppColors.border,
                                  ),
                              itemBuilder: (context, index) {
                                final city = _cities[index];
                                final isSelected = city == widget.selectedCity;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => widget.onSelect(city),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.md,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              city,
                                              style: AppTypography.body
                                                  .copyWith(
                                                    color: isSelected
                                                        ? AppColors.gold
                                                        : AppColors.textPrimary,
                                                  ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: AppColors.gold,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, color: AppColors.textMuted, size: 30),
          const SizedBox(height: 10),
          Text('Нәтиже табылмады', style: AppTypography.body),
          const SizedBox(height: 4),
          Text('Басқа атаумен іздеп көріңіз', style: AppTypography.caption),
        ],
      ),
    );
  }
}
