import 'dart:io';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/core/widgets/app_loading.dart';
import 'package:kuryl_kz/features/categories/data/category_repository.dart';
import 'package:kuryl_kz/features/categories/models/category_node.dart';
import 'package:kuryl_kz/features/categories/ui/category_picker.dart';
import 'package:kuryl_kz/features/categories/utils/category_locale.dart';
import 'package:kuryl_kz/features/location/models/kato_models.dart';
import 'package:kuryl_kz/features/client/request/widgets/privacy_policy_row.dart';
import 'package:kuryl_kz/features/client/request/widgets/request_description_field.dart';
import 'package:kuryl_kz/features/client/request/widgets/request_image_picker.dart';
import 'package:kuryl_kz/features/client/request/widgets/request_input_field.dart';
import 'package:kuryl_kz/features/client/request/widgets/request_location_card.dart';
import 'package:kuryl_kz/features/client/request/widgets/request_location_picker.dart';
import 'package:kuryl_kz/features/client/request/widgets/request_price_field.dart';
import 'package:kuryl_kz/features/client/request/widgets/request_publish_button.dart';
import 'package:kuryl_kz/features/marketplace/services/marketplace_exception.dart';
import 'package:kuryl_kz/features/marketplace/services/order_service.dart';

class RequestCreateScreen extends StatefulWidget {
  const RequestCreateScreen({super.key});

  @override
  State<RequestCreateScreen> createState() => _RequestCreateScreenState();
}

class _RequestCreateScreenState extends State<RequestCreateScreen> {
  final OrderService _orderService = OrderService();
  final CategoryRepository _categoryRepository = CategoryRepository.instance;

  final List<File> _imageFiles = <File>[];
  late final Future<void> _categoryInitFuture;

  String? _selectedCategoryId;

  String _title = '';
  String _description = '';
  String _budget = '';
  LocationBreakdown? _selectedLocation;
  bool _isNegotiable = false;

  bool _isLoading = false;

  final Color kGold = const Color(0xFFFFD700);
  final Color kBorder = const Color(0xFF333333);
  final Color kCardBg = const Color(0xFF111111);

  @override
  void initState() {
    super.initState();
    _categoryInitFuture = _categoryRepository.init();
  }

  Future<void> _pickMultiImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isEmpty) return;

    final newFiles = <File>[];
    for (final xFile in pickedFiles) {
      final file = File(xFile.path);
      final compressed = await _compressImage(file);
      newFiles.add(compressed ?? file);
    }

    if (!mounted) return;
    setState(() {
      _imageFiles.addAll(newFiles);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<File?> _compressImage(File file) async {
    final dir = await path_provider.getTemporaryDirectory();
    final targetPath =
        '${dir.absolute.path}/order_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 62,
    );

    return result != null ? File(result.path) : null;
  }

  double? _parseBudget(String raw) {
    final normalized = raw
        .replaceAll(RegExp(r'[^0-9.,]'), '')
        .replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  CategoryNode? _selectedLeaf() {
    if (!_categoryRepository.isInitialized) return null;
    final id = _selectedCategoryId;
    if (id == null || id.trim().isEmpty) return null;
    return _categoryRepository.getLeaf(id);
  }

  String _selectedLeafName(String localeCode) {
    final leaf = _selectedLeaf();
    if (leaf == null) return '';
    return leaf.localizedName(localeCode);
  }

  String _selectedLeafBreadcrumb(String localeCode) {
    if (!_categoryRepository.isInitialized) return '';
    final leaf = _selectedLeaf();
    if (leaf == null) return '';
    final nodes = _categoryRepository.getBreadcrumb(leaf.id);
    return nodes.map((node) => node.localizedName(localeCode)).join(' > ');
  }

  Future<void> _submitRequest() async {
    final localeCode = resolveCategoryLocaleCode(
      Localizations.localeOf(context),
    );
    await _categoryInitFuture;
    if (!mounted) return;
    final selectedLeaf = _selectedLeaf();
    if (_title.trim().isEmpty ||
        selectedLeaf == null ||
        _description.trim().isEmpty ||
        _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Маңызды өрістерді толтырыңыз (Атауы, Категория, Сипаттама, Мекенжай)',
          ),
        ),
      );
      return;
    }

    final budget = _parseBudget(_budget);
    if (!_isNegotiable && (budget == null || budget <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бағаны дұрыс енгізіңіз немесе "Келісімді" таңдаңыз.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Алдымен жүйеге кіріңіз.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrls = await _orderService.uploadOrderPhotos(
        clientId: user.uid,
        files: _imageFiles,
      );

      await _orderService.createOrder(
        clientId: user.uid,
        title: _title,
        categoryId: selectedLeaf.id,
        categoryPathIds: selectedLeaf.pathIds,
        categoryRootId: selectedLeaf.pathIds.first,
        categoryName: selectedLeaf.localizedName(localeCode),
        description: _description,
        budgetPrice: budget,
        negotiable: _isNegotiable,
        location: _selectedLocation!,
        photos: imageUrls,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Тапсырыс OPEN күйінде жарияланды. ✅'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on MarketplaceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? e.code),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestLocationPicker(
        initialValue: _selectedLocation,
        onSelect: (location) {
          setState(() {
            _selectedLocation = location;
          });
        },
      ),
    );
  }

  Future<void> _openCategoryPicker() async {
    await _categoryInitFuture;
    if (!mounted) return;
    final selected = await CategoryPicker.pickSingleLeaf(
      context: context,
      title: 'Қызмет санатын таңдаңыз',
      role: CategoryPickerRole.client,
      initialLeafId: _selectedCategoryId,
      repository: _categoryRepository,
    );
    if (!mounted || selected == null) return;
    setState(() => _selectedCategoryId = selected);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final localeCode = resolveCategoryLocaleCode(
      Localizations.localeOf(context),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackgroundGlow(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 120 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _openCategoryPicker,
                          child: _buildCategoryCard(localeCode),
                        ),
                        if (_selectedLeaf() != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Тапсырыс санаты: ${_selectedLeafName(localeCode)}',
                            style: const TextStyle(
                              color: Color(0xFFE8C45B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        RequestImagePicker(
                          selectedImages: _imageFiles,
                          onTap: _pickMultiImages,
                          onRemove: _removeImage,
                        ),
                        RequestInputField(
                          label: 'ЖҰМЫС АТАУЫ',
                          placeholder: 'Мысалы: Розетка орнату',
                          icon: CupertinoIcons.briefcase,
                          onChanged: (v) => _title = v,
                          initialValue: _title,
                        ),
                        RequestDescriptionField(
                          value: _description,
                          onChanged: (v) => _description = v,
                        ),
                        RequestPriceField(
                          isNegotiable: _isNegotiable,
                          onToggleNegotiable: (val) {
                            setState(() => _isNegotiable = val);
                          },
                          price: _budget,
                          onPriceChanged: (v) => _budget = v,
                        ),
                        RequestLocationCard(
                          address: _selectedLocation?.shortLabel ?? '',
                          onTap: _openLocationPicker,
                        ),
                        const SizedBox(height: 12),
                        const PrivacyPolicyRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: _isLoading
                    ? Container(
                        height: 100,
                        color: Colors.black.withValues(alpha: 0.82),
                        child: const Center(
                          child: AppLoadingIndicator(
                            size: 28,
                            strokeWidth: 2.5,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      )
                    : RequestPublishButton(onTap: _submitRequest),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: -150,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kGold.withValues(alpha: 0.1),
          boxShadow: [
            BoxShadow(
              color: kGold.withValues(alpha: 0.15),
              blurRadius: 150,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            children: [
              _buildBackButton(),
              const SizedBox(width: 16),
              const Text(
                'Тапсырыс беру',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return const AppBackButton();
  }

  Widget _buildCategoryCard(String localeCode) {
    final leaf = _selectedLeaf();
    final breadcrumb = _selectedLeafBreadcrumb(localeCode);
    final leafName = _selectedLeafName(localeCode);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: leaf != null ? kGold.withValues(alpha: 0.5) : kBorder,
        ),
        boxShadow: leaf != null
            ? [
                BoxShadow(
                  color: kGold.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Icon(
              Icons.category_outlined,
              color: leaf != null ? kGold : Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leafName.isEmpty ? 'Қызмет санатын таңдаңыз' : leafName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: leaf != null ? Colors.white : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (breadcrumb.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    breadcrumb,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            color: leaf != null ? kGold : Colors.grey[600],
            size: 20,
          ),
        ],
      ),
    );
  }
}
