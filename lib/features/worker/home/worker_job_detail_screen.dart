import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';
import 'package:kuryl_kz/features/client/request/models/category_model.dart';
import 'package:kuryl_kz/features/marketplace/models/offer_model.dart';
import 'package:kuryl_kz/features/marketplace/models/order_model.dart';
import 'package:kuryl_kz/features/marketplace/services/marketplace_exception.dart';
import 'package:kuryl_kz/features/marketplace/services/offer_service.dart';
import 'package:kuryl_kz/features/marketplace/services/order_service.dart';

class WorkerJobDetailScreen extends StatefulWidget {
  const WorkerJobDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<WorkerJobDetailScreen> createState() => _WorkerJobDetailScreenState();
}

class _WorkerJobDetailScreenState extends State<WorkerJobDetailScreen> {
  final OrderService _orderService = OrderService();
  final OfferService _offerService = OfferService();

  int _selectedImageIndex = 0;
  bool _isSubmitting = false;

  String _categoryIcon(String categoryName) {
    for (final item in jobCategories) {
      if (item.name == categoryName) return item.icon;
    }
    return '🛠️';
  }

  String _absoluteDate(DateTime? value) {
    if (value == null) return 'Белгісіз';
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yyyy • $hh:$min';
  }

  Future<void> _openOfferSheet({
    required MarketplaceOrder order,
    required String workerId,
    MarketplaceOffer? existingOffer,
  }) async {
    if (!order.isOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тапсырыс енді OPEN күйінде емес.')),
      );
      return;
    }

    final priceController = TextEditingController(
      text: existingOffer != null
          ? existingOffer.offeredPrice.toStringAsFixed(0)
          : (order.budgetPrice?.toStringAsFixed(0) ?? ''),
    );
    final messageController = TextEditingController(
      text: existingOffer?.message ?? '',
    );
    bool sameAsBudget = existingOffer == null && order.budgetPrice != null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    existingOffer == null
                        ? 'Ұсыныс жіберу'
                        : 'Ұсынысты жаңарту',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (order.budgetPrice != null)
                    TextButton.icon(
                      onPressed: () {
                        setModalState(() {
                          sameAsBudget = !sameAsBudget;
                          if (sameAsBudget) {
                            priceController.text = order.budgetPrice!
                                .toStringAsFixed(0);
                          }
                        });
                      },
                      icon: Icon(
                        sameAsBudget
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: sameAsBudget
                            ? const Color(0xFFFFD700)
                            : Colors.grey,
                      ),
                      label: const Text('Тапсырыс бағасымен бірдей'),
                    ),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    enabled: !sameAsBudget,
                    decoration: InputDecoration(
                      labelText: 'Ұсыныс бағасы',
                      hintText: 'Мысалы: 120000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Хабарлама (міндетті емес)',
                      hintText: 'Жұмысты қашан бастай алатыныңызды жазыңыз',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              final price = double.tryParse(
                                priceController.text.replaceAll(',', '.'),
                              );

                              if (!sameAsBudget &&
                                  (price == null || price <= 0)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Бағаны дұрыс енгізіңіз.'),
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(context);
                              await _submitOffer(
                                orderId: order.id,
                                workerId: workerId,
                                offeredPrice: price,
                                sameAsBudget: sameAsBudget,
                                message: messageController.text,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(
                        existingOffer == null
                            ? 'Ұсыныс жіберу'
                            : 'Ұсынысты сақтау',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    priceController.dispose();
    messageController.dispose();
  }

  Future<void> _submitOffer({
    required String orderId,
    required String workerId,
    required double? offeredPrice,
    required bool sameAsBudget,
    required String message,
  }) async {
    setState(() => _isSubmitting = true);

    try {
      final result = await _offerService.sendOrUpdateOffer(
        orderId: orderId,
        workerId: workerId,
        offeredPrice: offeredPrice,
        sameAsBudget: sameAsBudget,
        message: message,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.updatedExisting
                ? 'Ұсынысыңыз жаңартылды.'
                : 'Ұсынысыңыз жіберілді.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on MarketplaceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Алдымен жүйеге кіріңіз')),
      );
    }

    return StreamBuilder<MarketplaceOrder?>(
      stream: _orderService.streamOrder(widget.orderId),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(leading: appBarBackButton(context)),
            body: Center(child: Text('Қате: ${orderSnapshot.error}')),
          );
        }

        if (!orderSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final order = orderSnapshot.data;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(leading: appBarBackButton(context)),
            body: const Center(child: Text('Тапсырыс табылмады.')),
          );
        }

        return StreamBuilder<MarketplaceOffer?>(
          stream: _offerService.streamWorkerOffer(
            orderId: order.id,
            workerId: currentUser.uid,
          ),
          builder: (context, offerSnapshot) {
            final existingOffer = offerSnapshot.data;

            return Scaffold(
              backgroundColor: const Color(0xFFF3F4F6),
              body: SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HeaderGallery(
                                  photos: order.photos,
                                  selectedIndex: _selectedImageIndex,
                                  onSelect: (index) {
                                    setState(() => _selectedImageIndex = index);
                                  },
                                  fallbackIcon: _categoryIcon(
                                    order.categoryName,
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -20),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      20,
                                      20,
                                      120,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(28),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              order.budgetLabel,
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: order.isOpen
                                                    ? Colors.green.withValues(
                                                        alpha: 0.12,
                                                      )
                                                    : Colors.grey.withValues(
                                                        alpha: 0.15,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                order.status.wire,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: order.isOpen
                                                      ? Colors.green.shade700
                                                      : Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          order.title,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            _InfoChip(
                                              icon: Icons.category_outlined,
                                              text: order.categoryName,
                                            ),
                                            _InfoChip(
                                              icon: Icons.location_on_outlined,
                                              text: order.locationShort,
                                            ),
                                            _InfoChip(
                                              icon: Icons.schedule,
                                              text: _absoluteDate(
                                                order.createdAt,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'Толық сипаттама',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          order.description,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.55,
                                            color: Color(0xFF4B5563),
                                          ),
                                        ),
                                        if (existingOffer != null) ...[
                                          const SizedBox(height: 22),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF9FAFB),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFFE5E7EB),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Менің ұсынысым',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${existingOffer.offeredPrice.toStringAsFixed(0)} ₸',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                if (existingOffer.message
                                                    .trim()
                                                    .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 6,
                                                        ),
                                                    child: Text(
                                                      existingOffer.message,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(
                                                          0xFF6B7280,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: const AppBackButton(),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          12 + MediaQuery.of(context).padding.bottom,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (order.isOpen && !_isSubmitting)
                                ? () => _openOfferSheet(
                                    order: order,
                                    workerId: currentUser.uid,
                                    existingOffer: existingOffer,
                                  )
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    order.isOpen
                                        ? (existingOffer == null
                                              ? 'Ұсыныс жіберу'
                                              : 'Ұсынысты жаңарту')
                                        : 'Тапсырыс OPEN емес',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HeaderGallery extends StatelessWidget {
  const _HeaderGallery({
    required this.photos,
    required this.selectedIndex,
    required this.onSelect,
    required this.fallbackIcon,
  });

  final List<String> photos;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final hasPhotos = photos.isNotEmpty;
    final safeIndex = hasPhotos ? selectedIndex.clamp(0, photos.length - 1) : 0;
    final currentPhoto = hasPhotos ? photos[safeIndex] : null;

    return Container(
      color: const Color(0xFF111827),
      child: Column(
        children: [
          SizedBox(
            height: 280,
            width: double.infinity,
            child: currentPhoto == null
                ? Center(
                    child: Text(
                      fallbackIcon,
                      style: const TextStyle(fontSize: 54),
                    ),
                  )
                : SafeNetworkImage(url: currentPhoto, fit: BoxFit.cover),
          ),
          if (photos.length > 1)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => onSelect(index),
                      child: Container(
                        width: 72,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedIndex == index
                                ? const Color(0xFFFFD700)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SafeNetworkImage(
                            url: photos[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
