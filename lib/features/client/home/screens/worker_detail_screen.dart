import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_buttons.dart';
import 'package:kuryl_kz/core/widgets/app_loading.dart';
import 'package:kuryl_kz/core/widgets/app_chips.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';
import 'package:kuryl_kz/features/client/home/models/worker_model.dart';
import 'package:kuryl_kz/features/worker/profile/models/worker_profile_data.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WorkerDetailScreen extends StatefulWidget {
  final WorkerModel worker;

  const WorkerDetailScreen({super.key, required this.worker});

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  late WorkerProfileData _profile;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final seeded = WorkerProfileData.fromHomeWorker(
      id: widget.worker.id,
      fullName: widget.worker.name,
      avatarUrl: widget.worker.avatarUrl,
      specialty: widget.worker.specialty,
      city: widget.worker.city,
      experience: widget.worker.experience,
      rating: widget.worker.rating,
      completedOrders: widget.worker.completedOrders,
      reviewCount: widget.worker.reviewCount,
      price: widget.worker.price,
      tags: widget.worker.tags,
      about: widget.worker.bio,
    );
    _profile = WorkerProfileData.fromMap(seeded, widget.worker.id);
    _loadWorkerProfile();
  }

  Future<void> _loadWorkerProfile() async {
    final workerId = widget.worker.id.trim();
    if (workerId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .get();

      if (!doc.exists) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Шебер профилі табылмады, карточка дерегі көрсетілді.';
        });
        return;
      }

      final data = doc.data() ?? <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _profile = WorkerProfileData.fromMap(data, workerId);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Профиль жүктеу қатесі: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final heroTag = widget.worker.id.trim().isEmpty
        ? null
        : 'worker-avatar-${widget.worker.id.trim()}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: _BottomBar(worker: widget.worker),
      body: RefreshIndicator(
        onRefresh: _loadWorkerProfile,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.bg,
              foregroundColor: AppColors.textPrimary,
              pinned: true,
              expandedHeight: 280,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A1A22), Color(0xFF0B0B0F)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 82,
                      left: 24,
                      right: 24,
                      child: Column(
                        children: [
                          Hero(
                            tag: heroTag ?? 'worker-avatar-fallback',
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.gold,
                                  width: 2,
                                ),
                                boxShadow: AppShadows.glow,
                              ),
                              child: ClipOval(
                                child: SafeNetworkImage(
                                  url: profile.avatarUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            profile.fullName,
                            style: AppTypography.h2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                            child: Text(
                              profile.specialty.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(profile.city, style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: _StatsRow(profile: profile),
              ),
            ),
            if (profile.showPhone || profile.showEmail)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ContactCard(profile: profile),
                ),
              ),
            SliverToBoxAdapter(child: _sectionTitle('Орналасу аймағы')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _locationSection(profile),
              ),
            ),
            SliverToBoxAdapter(child: _sectionTitle('Мамандықтар')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _specialtiesSection(profile),
              ),
            ),
            SliverToBoxAdapter(child: _sectionTitle('Не істей аламын')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _servicesSection(profile),
              ),
            ),
            SliverToBoxAdapter(child: _sectionTitle('Бригада')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _brigadeSection(profile),
              ),
            ),
            SliverToBoxAdapter(child: _sectionTitle('Шебер туралы')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  profile.bio.isEmpty ? 'Қосымша ақпарат жоқ.' : profile.bio,
                  style: AppTypography.bodyMuted,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _sectionTitle('Портфолио')),
            SliverToBoxAdapter(child: _portfolioSection(profile)),
            SliverToBoxAdapter(child: _sectionTitle('Тәжірибе')),
            SliverToBoxAdapter(
              child: _timelineSection(
                items: profile.experiences
                    .map(
                      (item) => _TimelineItem(
                        title: item.role,
                        subtitle: item.company,
                        period: item.years,
                        description: item.description,
                      ),
                    )
                    .toList(),
                emptyText: 'Тәжірибе деректері қосылмаған.',
              ),
            ),
            SliverToBoxAdapter(child: _sectionTitle('Білім')),
            SliverToBoxAdapter(
              child: _timelineSection(
                items: profile.educations
                    .map(
                      (item) => _TimelineItem(
                        title: item.degree,
                        subtitle: item.institution,
                        period: item.years,
                        description: item.description,
                      ),
                    )
                    .toList(),
                emptyText: 'Білім бөлімі толтырылмаған.',
              ),
            ),
            SliverToBoxAdapter(child: _sectionTitle('Сертификаттар')),
            SliverToBoxAdapter(
              child: _timelineSection(
                items: profile.certificates
                    .map(
                      (item) => _TimelineItem(
                        title: item.title,
                        subtitle: item.issuer,
                        period: item.year,
                        description: item.description,
                      ),
                    )
                    .toList(),
                emptyText: 'Сертификаттар әлі қосылмаған.',
              ),
            ),
            SliverToBoxAdapter(
              child: _sectionTitle('Пікірлер (${profile.reviewCount})'),
            ),
            SliverToBoxAdapter(child: _reviewsSection(profile)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _availabilityIcon(profile.availabilityStatus),
                        size: 18,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Қолжетімділік: ${_availabilityLabel(profile.availabilityStatus)}',
                          style: AppTypography.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (profile.availabilitySlots.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.availabilitySlots
                        .map((slot) => AppTagChip(label: slot))
                        .toList(),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 130,
                child: Center(
                  child: _isLoading
                      ? const AppLoadingIndicator(
                          size: 24,
                          strokeWidth: 2.4,
                          color: AppColors.gold,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(title, style: AppTypography.h3),
    );
  }

  Widget _locationSection(WorkerProfileData profile) {
    final locationRows = <_InfoRow>[
      _InfoRow('Қала', profile.city),
      _InfoRow('Аудан', profile.district),
      _InfoRow('Ауыл/Елді мекен', profile.village),
      _InfoRow('Қосымша адрес', profile.addressNote),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: locationRows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${row.label}: ',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: row.value.trim().isEmpty
                            ? 'Not specified'
                            : row.value.trim(),
                        style: AppTypography.body.copyWith(
                          color: row.value.trim().isEmpty
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _specialtiesSection(WorkerProfileData profile) {
    final specialties = profile.specialties
        .where((item) => item.trim().isNotEmpty)
        .toList();
    if (specialties.isEmpty) {
      return const Text('Not specified', style: AppTypography.bodyMuted);
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: specialties.map((tag) => AppTagChip(label: tag)).toList(),
    );
  }

  Widget _servicesSection(WorkerProfileData profile) {
    final serviceNames = profile.services
        .map((item) => item.name.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (serviceNames.isEmpty) {
      return const Text('Not specified', style: AppTypography.bodyMuted);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: serviceNames
          .map(
            (name) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $name', style: AppTypography.body),
            ),
          )
          .toList(),
    );
  }

  Widget _brigadeSection(WorkerProfileData profile) {
    if (!profile.hasBrigade) {
      return const Text('Not specified', style: AppTypography.bodyMuted);
    }

    final size = profile.brigadeSize == null
        ? 'Not specified'
        : profile.brigadeSize.toString();
    final role = profile.brigadeRole.trim().isEmpty
        ? 'Not specified'
        : profile.brigadeRole.trim();
    final name = profile.brigadeName.trim().isEmpty
        ? 'Not specified'
        : profile.brigadeName.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Атауы: $name', style: AppTypography.body),
          const SizedBox(height: 6),
          Text('Саны: $size', style: AppTypography.body),
          const SizedBox(height: 6),
          Text('Рөлі: $role', style: AppTypography.body),
        ],
      ),
    );
  }

  Widget _portfolioSection(WorkerProfileData profile) {
    if (profile.portfolio.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Портфолио әлі қосылмаған.',
          style: AppTypography.bodyMuted,
        ),
      );
    }

    return SizedBox(
      height: 215,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final item = profile.portfolio[index];
          final image = item.images.isNotEmpty ? item.images.first : '';

          return Container(
            width: 250,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadii.lg),
                  ),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: SafeNetworkImage(url: image, fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description.isEmpty
                            ? 'Сипаттама берілмеген'
                            : item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemCount: profile.portfolio.length,
      ),
    );
  }

  Widget _timelineSection({
    required List<_TimelineItem> items,
    required String emptyText,
  }) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(emptyText, style: AppTypography.bodyMuted),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: items
            .map(
              (item) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? 'Атауы жоқ' : item.title,
                      style: AppTypography.body,
                    ),
                    if (item.subtitle.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.subtitle,
                          style: AppTypography.caption,
                        ),
                      ),
                    if (item.period.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(item.period, style: AppTypography.caption),
                      ),
                    if (item.description.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          item.description,
                          style: AppTypography.bodyMuted,
                        ),
                      ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _reviewsSection(WorkerProfileData profile) {
    if (profile.reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            'Пікірлер әлі жоқ. Бұл бөлім reviews моделімен интеграцияланған.',
            style: AppTypography.caption,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: profile.reviews
            .map(
              (review) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(review.author, style: AppTypography.body),
                        ),
                        const Icon(Icons.star, size: 14, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(review.text, style: AppTypography.bodyMuted),
                    if (review.date.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(review.date, style: AppTypography.caption),
                      ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  IconData _availabilityIcon(String status) {
    switch (status) {
      case 'busy':
        return Icons.work_outline;
      case 'offline':
        return Icons.pause_circle_outline;
      case 'available':
      default:
        return Icons.check_circle_outline;
    }
  }

  String _availabilityLabel(String status) {
    switch (status) {
      case 'busy':
        return 'Бос емес';
      case 'offline':
        return 'Қазір қолжетімсіз';
      case 'available':
      default:
        return 'Қолжетімді';
    }
  }
}

class _StatsRow extends StatelessWidget {
  final WorkerProfileData profile;

  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat(
            'Рейтинг',
            profile.rating.toStringAsFixed(1),
            Icons.star,
            AppColors.gold,
          ),
          _divider(),
          _stat(
            'Жұмыс',
            '${profile.completedOrders}+',
            LucideIcons.briefcase,
            AppColors.textPrimary,
          ),
          _divider(),
          _stat(
            'Тәжірибе',
            profile.experience,
            LucideIcons.clock,
            AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.border);

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: AppTypography.body),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final WorkerProfileData profile;

  const _ContactCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Байланыс', style: AppTypography.body),
          const SizedBox(height: 8),
          if (profile.showPhone && profile.phone.trim().isNotEmpty)
            Text('Телефон: ${profile.phone}', style: AppTypography.caption),
          if (profile.showEmail && profile.email.trim().isNotEmpty)
            Text('Email: ${profile.email}', style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _TimelineItem {
  final String title;
  final String subtitle;
  final String period;
  final String description;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.period,
    required this.description,
  });
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}

class _BottomBar extends StatelessWidget {
  final WorkerModel worker;

  const _BottomBar({required this.worker});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            AppIconButton(
              icon: LucideIcons.messageSquare,
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Алдымен жүйеге кіріңіз')),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Чат тек белсенді тапсырыс бекітілгеннен кейін ашылады.',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppPrimaryButton(
                label: 'Сұраныс жіберу',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Hire/Request flow қолжетімді болғанда осы жерге байланысады.',
                      ),
                    ),
                  );
                },
                icon: LucideIcons.briefcase,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
