import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/core/widgets/app_chips.dart';
import 'package:kuryl_kz/core/widgets/app_loading.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';
import 'package:kuryl_kz/features/categories/data/category_repository.dart';
import 'package:kuryl_kz/features/categories/utils/category_locale.dart';
import 'package:kuryl_kz/features/client/my_request/screens/order_offers_screen.dart';
import 'package:kuryl_kz/features/marketplace/models/order_model.dart';
import 'package:kuryl_kz/features/marketplace/services/marketplace_exception.dart';
import 'package:kuryl_kz/features/marketplace/services/order_service.dart';
import 'package:kuryl_kz/features/marketplace/services/review_service.dart';
import 'package:kuryl_kz/features/marketplace/services/user_profile_service.dart';
import 'package:kuryl_kz/screens/chat/chat_screen.dart';

class MyRequestScreen extends StatefulWidget {
  const MyRequestScreen({super.key});

  @override
  State<MyRequestScreen> createState() => _MyRequestScreenState();
}

class _MyRequestScreenState extends State<MyRequestScreen> {
  final OrderService _orderService = OrderService();
  final ReviewService _reviewService = ReviewService();
  final UserProfileService _profileService = UserProfileService();
  final CategoryRepository _categoryRepository = CategoryRepository.instance;

  int _selectedFilter = 0;
  String? _busyOrderId;

  @override
  void initState() {
    super.initState();
    _categoryRepository.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  String _timeAgo(DateTime? value) {
    if (value == null) return 'Қазір';

    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'Қазір';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
    if (diff.inHours < 24) return '${diff.inHours} сағ';
    if (diff.inDays < 7) return '${diff.inDays} күн';

    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    return '$dd.$mm';
  }

  String _statusLabel(MarketplaceOrderStatus status) {
    switch (status) {
      case MarketplaceOrderStatus.open:
        return 'OPEN';
      case MarketplaceOrderStatus.inProgress:
        return 'IN_PROGRESS';
      case MarketplaceOrderStatus.completed:
        return 'COMPLETED';
      case MarketplaceOrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color _statusColor(MarketplaceOrderStatus status) {
    switch (status) {
      case MarketplaceOrderStatus.open:
        return AppColors.gold;
      case MarketplaceOrderStatus.inProgress:
        return AppColors.warning;
      case MarketplaceOrderStatus.completed:
        return AppColors.success;
      case MarketplaceOrderStatus.cancelled:
        return AppColors.danger;
    }
  }

  String _leafName(MarketplaceOrder order, String localeCode) {
    if (!_categoryRepository.isInitialized) return order.categoryName;
    final leaf = _categoryRepository.getLeaf(order.categoryId);
    return leaf?.localizedName(localeCode) ?? order.categoryName;
  }

  String _breadcrumb(MarketplaceOrder order, String localeCode) {
    if (!_categoryRepository.isInitialized) return order.categoryName;
    final nodes = _categoryRepository.getBreadcrumb(order.categoryId);
    if (nodes.isEmpty) return order.categoryName;
    return nodes.map((node) => node.localizedName(localeCode)).join(' > ');
  }

  List<MarketplaceOrder> _applyFilter(List<MarketplaceOrder> orders) {
    switch (_selectedFilter) {
      case 1:
        return orders
            .where((item) => item.isOpen || item.isInProgress)
            .toList();
      case 2:
        return orders
            .where((item) => item.isCompleted || item.isCancelled)
            .toList();
      case 0:
      default:
        return orders;
    }
  }

  Future<void> _withOrderAction(
    String orderId,
    Future<void> Function() action,
  ) async {
    if (_busyOrderId != null) return;
    setState(() => _busyOrderId = orderId);

    try {
      await action();
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
        setState(() => _busyOrderId = null);
      }
    }
  }

  Future<String?> _askCancelReason({required bool isRequired}) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isRequired ? 'Себепті көрсетіңіз' : 'Тоқтату (міндетті емес)',
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Себеп',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Бас тарту'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (isRequired && text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Себеп міндетті.')),
                  );
                  return;
                }
                Navigator.pop(context, text);
              },
              child: const Text('Тоқтату'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _openChat(MarketplaceOrder order) async {
    final user = FirebaseAuth.instance.currentUser;
    final workerId = order.acceptedWorkerId;
    if (user == null || workerId == null || workerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Чатқа өту үшін шебер бекітілген болуы керек.'),
        ),
      );
      return;
    }

    final worker = await _profileService.getWorkerProfile(workerId);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: order.id,
          orderId: order.id,
          clientId: user.uid,
          workerId: workerId,
          currentUserId: user.uid,
          peerUserId: workerId,
          peerName: worker?.name ?? 'Шебер',
          peerAvatarUrl: (worker?.avatarUrl ?? '').trim().isEmpty
              ? null
              : worker!.avatarUrl,
        ),
      ),
    );
  }

  Future<void> _submitReview(MarketplaceOrder order) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    int rating = 5;
    final textController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Пікір қалдыру'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List<Widget>.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        onPressed: () => setModalState(() => rating = star),
                        icon: Icon(
                          star <= rating ? Icons.star : Icons.star_border,
                          color: AppColors.gold,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Пікір (міндетті емес)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Бас тарту'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Жіберу'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      textController.dispose();
      return;
    }

    await _withOrderAction(order.id, () async {
      final client = await _profileService.getClientProfile(user.uid);
      await _reviewService.submitReview(
        orderId: order.id,
        clientId: user.uid,
        rating: rating,
        text: textController.text,
        clientName: client?.name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пікір сақталды. Рақмет!'),
          backgroundColor: Colors.green,
        ),
      );
    });

    textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final canGoBack = Navigator.of(context).canPop();
    final localeCode = resolveCategoryLocaleCode(
      Localizations.localeOf(context),
    );

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Text('Алдымен жүйеге кіріңіз', style: AppTypography.body),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  if (canGoBack) ...[
                    const AppBackButton(),
                    const SizedBox(width: 8),
                  ],
                  const Expanded(
                    child: Text('Тапсырыстарым', style: AppTypography.h2),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  AppChoiceChip(
                    label: 'Барлығы',
                    selected: _selectedFilter == 0,
                    onTap: () => setState(() => _selectedFilter = 0),
                  ),
                  const SizedBox(width: 10),
                  AppChoiceChip(
                    label: 'Белсенді',
                    selected: _selectedFilter == 1,
                    onTap: () => setState(() => _selectedFilter = 1),
                  ),
                  const SizedBox(width: 10),
                  AppChoiceChip(
                    label: 'Тарих',
                    selected: _selectedFilter == 2,
                    onTap: () => setState(() => _selectedFilter = 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<List<MarketplaceOrder>>(
                stream: _orderService.streamClientOrders(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Қате: ${snapshot.error}',
                        style: AppTypography.bodyMuted,
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: AppLoadingIndicator(size: 28, strokeWidth: 2.6),
                    );
                  }

                  final filtered = _applyFilter(snapshot.data!);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'Тапсырыс жоқ',
                        style: AppTypography.bodyMuted,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      final isBusy = _busyOrderId == order.id;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                  child: SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: order.photos.isEmpty
                                        ? Container(
                                            color: AppColors.surface2,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              CupertinoIcons.photo,
                                              color: AppColors.textMuted,
                                            ),
                                          )
                                        : SafeNetworkImage(
                                            url: order.photos.first,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _leafName(order, localeCode),
                                              style: AppTypography.caption,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            _timeAgo(order.createdAt),
                                            style: AppTypography.caption,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        order.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.body,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _breadcrumb(order, localeCode),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.caption,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        order.budgetLabel,
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.gold,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        order.locationShort,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      order.status,
                                    ).withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _statusLabel(order.status),
                                    style: TextStyle(
                                      color: _statusColor(order.status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (order.isOpen)
                                  Text(
                                    'Ұсыныстар: ${order.offersCount}',
                                    style: AppTypography.caption,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (order.cancelReason != null &&
                                order.cancelReason!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Себеп: ${order.cancelReason}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (order.isOpen)
                                  _ActionButton(
                                    text: 'Offers',
                                    busy: isBusy,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              OrderOffersScreen(order: order),
                                        ),
                                      );
                                    },
                                  ),
                                if (order.isOpen)
                                  _ActionButton(
                                    text: 'Cancel',
                                    outlined: true,
                                    busy: isBusy,
                                    onTap: () async {
                                      final reason = await _askCancelReason(
                                        isRequired: false,
                                      );
                                      if (reason == null && context.mounted) {
                                        return;
                                      }
                                      await _withOrderAction(
                                        order.id,
                                        () async {
                                          await _orderService.cancelOrder(
                                            orderId: order.id,
                                            actorId: user.uid,
                                            actorRole: 'client',
                                            reason: reason,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                if (order.isInProgress)
                                  _ActionButton(
                                    text: 'Chat',
                                    busy: isBusy,
                                    onTap: () => _openChat(order),
                                  ),
                                if (order.isInProgress)
                                  _ActionButton(
                                    text: order.doneByClient
                                        ? 'Расталды'
                                        : 'Confirm completion',
                                    busy: isBusy,
                                    enabled: !order.doneByClient,
                                    onTap: () {
                                      _withOrderAction(order.id, () async {
                                        await _orderService.markClientDone(
                                          orderId: order.id,
                                          clientId: user.uid,
                                        );
                                      });
                                    },
                                  ),
                                if (order.isInProgress)
                                  _ActionButton(
                                    text: 'Cancel',
                                    outlined: true,
                                    busy: isBusy,
                                    onTap: () async {
                                      final reason = await _askCancelReason(
                                        isRequired: true,
                                      );
                                      if (reason == null) return;
                                      await _withOrderAction(
                                        order.id,
                                        () async {
                                          await _orderService.cancelOrder(
                                            orderId: order.id,
                                            actorId: user.uid,
                                            actorRole: 'client',
                                            reason: reason,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                if (order.isCompleted)
                                  _ActionButton(
                                    text: order.reviewCreatedAt == null
                                        ? 'Review'
                                        : 'Пікір берілді',
                                    busy: isBusy,
                                    enabled: order.reviewCreatedAt == null,
                                    onTap: () => _submitReview(order),
                                  ),
                                if (order.isCompleted &&
                                    order.acceptedWorkerId != null)
                                  _ActionButton(
                                    text: 'Chat',
                                    outlined: true,
                                    busy: isBusy,
                                    onTap: () => _openChat(order),
                                  ),
                              ],
                            ),
                          ],
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
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.text,
    required this.onTap,
    this.outlined = false,
    this.enabled = true,
    this.busy = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool outlined;
  final bool enabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final onPressed = (!enabled || busy) ? null : onTap;

    final child = busy
        ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(
            text,
            style: TextStyle(
              color: outlined ? AppColors.textPrimary : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          );

    if (outlined) {
      return SizedBox(
        height: 32,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: child,
      ),
    );
  }
}
