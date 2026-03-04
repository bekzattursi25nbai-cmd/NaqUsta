import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/features/auth/models/auth_role.dart';
import 'package:kuryl_kz/features/auth/screens/login_screen.dart';
import 'package:kuryl_kz/features/auth/services/role_selection_cache.dart';
import 'package:kuryl_kz/features/auth/widgets/role_card.dart';

class RoleSelectionScreen extends StatefulWidget {
  final ValueChanged<AuthRole>? onRoleSelected;
  final bool authenticatedMode;

  const RoleSelectionScreen({
    super.key,
    this.onRoleSelected,
    this.authenticatedMode = false,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  Future<void> _selectRole(AuthRole role) async {
    RoleSelectionCache.instance.setRole(role);

    if (widget.onRoleSelected != null) {
      widget.onRoleSelected!(role);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhoneLoginScreen(selectedRole: role),
      ),
    );
  }

  Future<void> _signOutIfNeeded() async {
    RoleSelectionCache.instance.clear();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    const Color amber400 = Color(0xFFFFC107);
    const Color amber600 = Color(0xFFD97706);
    const Color gray900 = Color(0xFF111827);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.authenticatedMode)
                          Row(
                            children: [
                              const Spacer(),
                              TextButton(
                                onPressed: _signOutIfNeeded,
                                child: const Text('Шығу'),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: amber400,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: amber400.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.verified_user_outlined,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'NaqUsta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: gray900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.authenticatedMode
                              ? 'Профиль аяқталмаған. Рөліңізді таңдаңыз'
                              : 'Жалғастыру үшін рөліңізді таңдаңыз',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 40),
                        RoleCard(
                          title: 'Шебермін',
                          subtitle: 'Жұмыс іздеймін, бригада басқарамын',
                          icon: Icons.engineering,
                          bgColor: amber400,
                          textColor: gray900,
                          iconBgColor: Colors.white,
                          iconColor: amber600,
                          onTap: () => _selectRole(AuthRole.worker),
                        ),
                        const SizedBox(height: 20),
                        RoleCard(
                          title: 'Тапсырыс беремін',
                          subtitle: 'Үй саламын, жөндеу жасаймын',
                          icon: Icons.home_work,
                          bgColor: gray900,
                          textColor: Colors.white,
                          iconBgColor: Colors.grey,
                          iconColor: Colors.white,
                          onTap: () => _selectRole(AuthRole.client),
                        ),
                        const Spacer(),
                        const SizedBox(height: 20),
                        const Text(
                          'V 1.0.0 kuryl',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
