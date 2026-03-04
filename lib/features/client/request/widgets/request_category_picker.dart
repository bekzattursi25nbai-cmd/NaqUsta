// lib/features/request/widgets/request_category_picker.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';

class RequestCategoryPicker extends StatefulWidget {
  final List<JobCategory> categories;
  final JobCategory? selected;
  final Function(JobCategory) onSelect;

  const RequestCategoryPicker({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<RequestCategoryPicker> createState() => _RequestCategoryPickerState();
}

class _RequestCategoryPickerState extends State<RequestCategoryPicker> {
  // Іздеу үшін керек тізім
  List<JobCategory> _filteredCategories = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Басында барлық категорияны көрсетеміз
    _filteredCategories = widget.categories;
  }

  // Іздеу функциясы
  void _filterCategories(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCategories = widget.categories;
      });
    } else {
      setState(() {
        _filteredCategories = widget.categories
            .where((cat) => cat.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // Биігірек қылдым
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ---------------------------------------------------------
          // HEADER
          // ---------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Категория таңдау",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF222222),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---------------------------------------------------------
          // SEARCH BAR (ІЗДЕУ) - Жаңадан қосылды!
          // ---------------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCategories,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Мысалы: Сантехник, Электрик...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                icon: Icon(CupertinoIcons.search, color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ---------------------------------------------------------
          // LIST OF CATEGORIES
          // ---------------------------------------------------------
          Expanded(
            child: _filteredCategories.isEmpty
                ? const Center(
                    child: Text(
                      "Ештеңе табылмады 🤷‍♂️",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cat = _filteredCategories[index];
                      final isSelected = widget.selected?.id == cat.id;

                      return GestureDetector(
                        onTap: () {
                          widget.onSelect(cat);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFFD700)
                                  : Colors.transparent,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700)
                                          .withValues(alpha: 0.15),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Text(cat.icon,
                                  style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  CupertinoIcons.checkmark_alt_circle_fill,
                                  color: Color(0xFFFFD700),
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
