import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/core/widgets/app_loading.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';
import 'package:kuryl_kz/features/marketplace/models/offer_model.dart';
import 'package:kuryl_kz/features/marketplace/models/order_model.dart';
import 'package:kuryl_kz/features/marketplace/models/public_profile_model.dart';
import 'package:kuryl_kz/features/marketplace/services/marketplace_exception.dart';
import 'package:kuryl_kz/features/marketplace/services/offer_service.dart';
import 'package:kuryl_kz/features/marketplace/services/order_service.dart';
import 'package:kuryl_kz/features/marketplace/services/user_profile_service.dart';
import 'package:kuryl_kz/screens/chat/chat_screen.dart';

class OrderOffersScreen extends StatefulWidget {
  const OrderOffersScreen({super.key, required this.order});

  final MarketplaceOrder order;

  @override
  State<OrderOffersScreen> createState() => _OrderOffersScreenState();
}

class _OrderOffersScreenState extends State<OrderOffersScreen> {
  final OfferService _offerService = OfferService();
  final OrderService _orderService = OrderService();
  final UserProfileService _profileService = UserProfileService();

  String? _acceptingWorkerId;

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Қазір';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
    if (diff.inHours < 24) return '${diff.inHours} сағ';
    return '${diff.inDays} күн';
  }

  Future<void> _acceptOffer({
    required MarketplaceOffer offer,
    required WorkerPublicProfile? worker,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Алдымен жүйеге кіріңіз.')));
      return;
    }

    setState(() => _acceptingWorkerId = offer.workerId);

    try {
      final client = await _profileService.getClientProfile(user.uid);

      final result = await _orderService.acceptWorkerOffer(
        orderId: widget.order.id,
        clientId: user.uid,
        selectedWorkerId: offer.workerId,
        clientName: client?.name,
        clientAvatarUrl: client?.avatarUrl,
        workerName: worker?.name,
        workerAvatarUrl: worker?.avatarUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Шебер таңдалды. Тапсырыс IN_PROGRESS күйіне өтті.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: result.chatId,
            orderId: widget.order.id,
            clientId: user.uid,
            workerId: offer.workerId,
            currentUserId: user.uid,
            peerUserId: offer.workerId,
            peerName: worker?.name ?? 'Шебер',
            peerAvatarUrl: (worker?.avatarUrl ?? '').trim().isEmpty
                ? null
                : worker?.avatarUrl,
          ),
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
        setState(() => _acceptingWorkerId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: appBarBackButton(context),
        title: const Text('Ұсыныстар'),
        backgroundColor: AppColors.bg,
      ),
      body: StreamBuilder<List<MarketplaceOffer>>(
        stream: _offerService.streamOffersForOrder(widget.order.id),
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

          final offers = snapshot.data!;
          if (offers.isEmpty) {
            return const Center(
              child: Text('Әзірге ұсыныс жоқ', style: AppTypography.bodyMuted),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final offer = offers[index];
              return FutureBuilder<WorkerPublicProfile?>(
                future: _profileService.getWorkerProfile(offer.workerId),
                builder: (context, workerSnapshot) {
                  final worker = workerSnapshot.data;

                  return _OfferTile(
                    offer: offer,
                    worker: worker,
                    timeLabel: _formatTime(offer.createdAt),
                    isAccepting: _acceptingWorkerId == offer.workerId,
                    canAccept:
                        widget.order.isOpen &&
                        offer.status == MarketplaceOfferStatus.sent,
                    onAccept: () => _acceptOffer(offer: offer, worker: worker),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.worker,
    required this.timeLabel,
    required this.isAccepting,
    required this.canAccept,
    required this.onAccept,
  });

  final MarketplaceOffer offer;
  final WorkerPublicProfile? worker;
  final String timeLabel;
  final bool isAccepting;
  final bool canAccept;
  final VoidCallback onAccept;

  String get _statusLabel {
    switch (offer.status) {
      case MarketplaceOfferStatus.accepted:
        return 'Қабылданды';
      case MarketplaceOfferStatus.rejected:
        return 'Қабылданбады';
      case MarketplaceOfferStatus.sent:
        return 'Жіберілді';
    }
  }

  Color get _statusColor {
    switch (offer.status) {
      case MarketplaceOfferStatus.accepted:
        return Colors.green;
      case MarketplaceOfferStatus.rejected:
        return Colors.red;
      case MarketplaceOfferStatus.sent:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workerName = worker?.name ?? 'Шебер';
    final avatarUrl = worker?.avatarUrl ?? '';
    final rating = worker?.ratingAvg ?? 0;
    final reviewsCount = worker?.ratingCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surface2,
                child: avatarUrl.trim().isEmpty
                    ? Text(
                        workerName.isEmpty ? '?' : workerName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : ClipOval(
                        child: SafeNetworkImage(
                          url: avatarUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workerName, style: AppTypography.body),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)} ($reviewsCount)',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(timeLabel, style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${offer.offeredPrice.toStringAsFixed(0)} ₸',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.gold,
            ),
          ),
          if (offer.message.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                offer.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (canAccept)
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: isAccepting ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isAccepting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Accept Worker',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
