import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/features/marketplace/models/order_model.dart';
import 'package:kuryl_kz/features/marketplace/services/marketplace_exception.dart';
import 'package:kuryl_kz/features/marketplace/services/order_service.dart';
import 'package:kuryl_kz/features/marketplace/services/user_profile_service.dart';
import 'package:kuryl_kz/screens/chat/chat_screen.dart';

class WorkerMyJobsScreen extends StatefulWidget {
  const WorkerMyJobsScreen({super.key});

  @override
  State<WorkerMyJobsScreen> createState() => _WorkerMyJobsScreenState();
}

class _WorkerMyJobsScreenState extends State<WorkerMyJobsScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final UserProfileService _profileService = UserProfileService();

  late final TabController _tabController;

  String? _busyOrderId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _statusLabel(MarketplaceOrder order) {
    if (order.isInProgress) {
      if (order.doneByWorker && !order.doneByClient) {
        return 'Клиент растауын күтуде';
      }
      return 'Орындалуда';
    }
    if (order.isCompleted) return 'Аяқталды';
    if (order.isCancelled) return 'Тоқтатылды';
    return order.status.wire;
  }

  Color _statusColor(MarketplaceOrder order) {
    if (order.isInProgress) {
      if (order.doneByWorker && !order.doneByClient) return Colors.orange;
      return Colors.blue;
    }
    if (order.isCompleted) return Colors.green;
    if (order.isCancelled) return Colors.red;
    return Colors.grey;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd.$mm • $hh:$min';
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

  Future<String?> _askCancelReason() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Тоқтату себебі'),
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
                final reason = controller.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Себеп міндетті.')),
                  );
                  return;
                }
                Navigator.pop(context, reason);
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

  Future<void> _openChat({
    required MarketplaceOrder order,
    required String workerId,
  }) async {
    final client = await _profileService.getClientPublicProfile(order.clientId);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: order.id,
          orderId: order.id,
          clientId: order.clientId,
          workerId: workerId,
          currentUserId: workerId,
          peerUserId: order.clientId,
          peerName: client?.name ?? 'Клиент',
          peerAvatarUrl: (client?.avatarUrl ?? '').trim().isEmpty
              ? null
              : client?.avatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Алдымен жүйеге кіріңіз')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: appBarBackButton(context),
        title: const Text(
          'Менің жұмыстарым',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFFD700),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Ағымдағы'),
            Tab(text: 'Тарих'),
          ],
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<MarketplaceOrder>>(
          stream: _orderService.streamWorkerOrders(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Қате: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allOrders = snapshot.data!;
            final active = allOrders.where((o) => o.isInProgress).toList();
            final history = allOrders
                .where((o) => o.isCompleted || o.isCancelled)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _OrdersList(
                  orders: active,
                  emptyLabel: 'Ағымдағы жұмыс жоқ',
                  busyOrderId: _busyOrderId,
                  statusLabel: _statusLabel,
                  statusColor: _statusColor,
                  formatDate: _formatDate,
                  onOpenChat: (order) =>
                      _openChat(order: order, workerId: user.uid),
                  onDone: (order) {
                    _withOrderAction(order.id, () async {
                      await _orderService.markWorkerDone(
                        orderId: order.id,
                        workerId: user.uid,
                      );
                    });
                  },
                  onCancel: (order) async {
                    final reason = await _askCancelReason();
                    if (reason == null) return;
                    await _withOrderAction(order.id, () async {
                      await _orderService.cancelOrder(
                        orderId: order.id,
                        actorId: user.uid,
                        actorRole: 'worker',
                        reason: reason,
                      );
                    });
                  },
                ),
                _OrdersList(
                  orders: history,
                  emptyLabel: 'Тарих бос',
                  busyOrderId: _busyOrderId,
                  statusLabel: _statusLabel,
                  statusColor: _statusColor,
                  formatDate: _formatDate,
                  onOpenChat: (order) =>
                      _openChat(order: order, workerId: user.uid),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.orders,
    required this.emptyLabel,
    required this.busyOrderId,
    required this.statusLabel,
    required this.statusColor,
    required this.formatDate,
    required this.onOpenChat,
    this.onDone,
    this.onCancel,
  });

  final List<MarketplaceOrder> orders;
  final String emptyLabel;
  final String? busyOrderId;
  final String Function(MarketplaceOrder order) statusLabel;
  final Color Function(MarketplaceOrder order) statusColor;
  final String Function(DateTime? value) formatDate;
  final ValueChanged<MarketplaceOrder> onOpenChat;
  final ValueChanged<MarketplaceOrder>? onDone;
  final ValueChanged<MarketplaceOrder>? onCancel;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Text(emptyLabel, style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      separatorBuilder: (_, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final order = orders[index];
        final isBusy = busyOrderId == order.id;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor(order).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel(order),
                      style: TextStyle(
                        color: statusColor(order),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    formatDate(order.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.locationShort,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.budgetLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (onDone != null || onCancel != null)
                    Wrap(
                      spacing: 8,
                      children: [
                        SizedBox(
                          height: 34,
                          child: OutlinedButton(
                            onPressed: isBusy ? null : () => onOpenChat(order),
                            child: const Text('Chat'),
                          ),
                        ),
                        if (onDone != null)
                          SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              onPressed: isBusy || order.doneByWorker
                                  ? null
                                  : () => onDone!(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                foregroundColor: Colors.black,
                              ),
                              child: isBusy
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      order.doneByWorker
                                          ? 'Жіберілді'
                                          : 'I finished the job',
                                    ),
                            ),
                          ),
                        if (onCancel != null)
                          SizedBox(
                            height: 34,
                            child: OutlinedButton(
                              onPressed: isBusy ? null : () => onCancel!(order),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                      ],
                    )
                  else
                    SizedBox(
                      height: 34,
                      child: OutlinedButton(
                        onPressed: () => onOpenChat(order),
                        child: const Text('Chat'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
