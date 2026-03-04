import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kuryl_kz/core/theme/app_theme.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';

import '../home/screens/client_home_screen.dart';
import '../chat/screens/client_list_screen.dart';
import '../profile/screens/client_profile_screen.dart';
import '../request/screens/request_create_screen.dart';
import '../my_request/screens/my_requests_screen.dart';
import '../registration/models/client_register_model.dart';

class ClientMainNavigation extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ClientMainNavigation({super.key, this.userData});

  @override
  State<ClientMainNavigation> createState() => _ClientMainNavigationState();
}

class _ClientMainNavigationState extends State<ClientMainNavigation> {
  int _currentIndex = 0;
  ClientRegisterModel? _profileModel;
  final Map<int, Widget> _screenCache = <int, Widget>{};
  final Set<int> _loadedTabs = <int>{0};

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _profileModel = ClientRegisterModel();
      _profileModel!.name = widget.userData!['name'] ?? '';
      _profileModel!.phone = widget.userData!['phone'] ?? '';
      _profileModel!.city = widget.userData!['city'] ?? '';
      _profileModel!.address = widget.userData!['address'] ?? '';
      _profileModel!.addressType = widget.userData!['address_type'] ?? '';
      _profileModel!.floor = widget.userData!['floor'] ?? '';
      _profileModel!.age = widget.userData!['age'] ?? 0;
      _profileModel!.interests = List<String>.from(
        widget.userData!['interests'] ?? [],
      );
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const ClientHomeScreen();
      case 1:
        return const MyRequestScreen();
      case 2:
        return const ClientListScreen();
      case 3:
        return ClientProfileScreen(userData: _profileModel);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _getScreen(int index) {
    return _screenCache.putIfAbsent(index, () => _buildScreen(index));
  }

  Widget _buildBody() {
    return Stack(
      children: List<Widget>.generate(4, (index) {
        if (!_loadedTabs.contains(index)) {
          return const SizedBox.shrink();
        }
        return Offstage(
          offstage: _currentIndex != index,
          child: TickerMode(
            enabled: _currentIndex == index,
            child: _getScreen(index),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.clientDark(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: _buildBody(),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _ClientFloatingNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ClientFloatingNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavIcon(
                      icon: LucideIcons.home,
                      active: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                    _NavIcon(
                      icon: LucideIcons.clock,
                      active: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                    const SizedBox(width: 56),
                    _NavIcon(
                      icon: LucideIcons.messageSquare,
                      active: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                    _NavIcon(
                      icon: LucideIcons.user,
                      active: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RequestCreateScreen(),
                  ),
                );
              },
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.gold, AppColors.goldDeep],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.bg, width: 4),
                  boxShadow: AppShadows.glow,
                ),
                child: const Center(
                  child: Icon(LucideIcons.plus, color: Colors.black, size: 30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: active ? AppColors.gold : AppColors.textMuted,
            ),
            if (active) ...[
              const SizedBox(height: 6),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.gold, blurRadius: 6)],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
