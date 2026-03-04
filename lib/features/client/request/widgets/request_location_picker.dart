import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/features/location/models/kato_models.dart';
import 'package:kuryl_kz/features/location/widgets/location_picker.dart';

class RequestLocationPicker extends StatefulWidget {
  const RequestLocationPicker({
    super.key,
    required this.onSelect,
    this.initialValue,
  });

  final ValueChanged<LocationBreakdown> onSelect;
  final LocationBreakdown? initialValue;

  @override
  State<RequestLocationPicker> createState() => _RequestLocationPickerState();
}

class _RequestLocationPickerState extends State<RequestLocationPicker> {
  LocationBreakdown? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsetsBottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.38),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Мекен-жай таңдау',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Өңір → Аудан → Елді мекен тізбегімен таңдаңыз.',
                        style: TextStyle(
                          color: Color(0xFFBDBDC7),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    surface: const Color(0xFF141418),
                    onSurface: Colors.white,
                    primary: const Color(0xFFFFD700),
                  ),
                  textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: Colors.white,
                    displayColor: Colors.white,
                  ),
                  iconTheme: const IconThemeData(color: Color(0xFFC8C8D2)),
                  dividerColor: Colors.white.withValues(alpha: 0.12),
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: LocationPicker(
                    mode: LocationPickerMode.order,
                    enableSearch: true,
                    showHeader: false,
                    initialValue: widget.initialValue,
                    onChanged: (value) {
                      setState(() {
                        _selected = value;
                      });
                    },
                  ),
                ),
              ),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0x1A2ECC71),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x662ECC71)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: Color(0xFF2ECC71),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selected!.shortLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selected == null
                    ? null
                    : () {
                        final selected = _selected;
                        if (selected == null) return;
                        widget.onSelect(selected);
                        Navigator.pop(context);
                      },
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text(
                  'Осы мекен-жайды таңдау',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[700],
                  disabledForegroundColor: Colors.grey[300],
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
