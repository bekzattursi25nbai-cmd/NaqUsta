import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/features/auth/models/auth_role.dart';
import 'package:kuryl_kz/features/auth/screens/role_selection_screen.dart';
import 'package:kuryl_kz/features/auth/services/auth_profile_repository.dart';
import 'package:kuryl_kz/features/auth/services/role_selection_cache.dart';
import 'package:kuryl_kz/features/client/navigation/client_main_navigation.dart';
import 'package:kuryl_kz/features/client/registration/screens/client_register_screen.dart';
import 'package:kuryl_kz/features/worker/navigation/worker_main_navigation.dart';
import 'package:kuryl_kz/features/worker/registration/screens/worker_registration_steps.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthProfileRepository _profileRepository = AuthProfileRepository();

  String? _lastUid;
  Future<AuthProfileLookupResult>? _lookupFuture;

  Future<AuthProfileLookupResult> _profileLookup(String uid) {
    return _profileRepository.lookupByUid(uid);
  }

  void _refreshProfileLookup() {
    setState(() {
      _lookupFuture = null;
    });
  }

  Future<void> _signOutToReset() async {
    RoleSelectionCache.instance.clear();
    await FirebaseAuth.instance.signOut();
  }

  Widget _buildLoading() {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }

  Widget _buildLookupError(Object error) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 44, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Профильді тексеру қатесі: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _refreshProfileLookup,
                  child: const Text('Қайта тексеру'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _signOutToReset,
                  child: const Text('Аккаунттан шығу'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConflictState() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 52),
                const SizedBox(height: 12),
                const Text(
                  'Аккаунт конфликті: бір UID үшін users және workers профилі қатар табылды.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Қолдауға жүгініңіз немесе аккаунттан шығып қайта кіріңіз.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _signOutToReset,
                  child: const Text('Шығу'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissingProfile(User user) {
    final cachedRole = RoleSelectionCache.instance.selectedRole;
    if (cachedRole == null) {
      return RoleSelectionScreen(
        authenticatedMode: true,
        onRoleSelected: (role) {
          RoleSelectionCache.instance.setRole(role);
          _refreshProfileLookup();
        },
      );
    }

    if (cachedRole == AuthRole.worker) {
      return const WorkerRegistrationSteps();
    }

    return ClientRegisterScreen(
      prefillPhone: user.phoneNumber ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        final user = snapshot.data;
        if (user == null) {
          _lastUid = null;
          _lookupFuture = null;
          return const RoleSelectionScreen();
        }

        if (_lastUid != user.uid || _lookupFuture == null) {
          _lastUid = user.uid;
          _lookupFuture = _profileLookup(user.uid);
        }

        return FutureBuilder<AuthProfileLookupResult>(
          future: _lookupFuture,
          builder: (context, lookupSnapshot) {
            if (lookupSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }

            if (lookupSnapshot.hasError) {
              return _buildLookupError(lookupSnapshot.error!);
            }

            final result = lookupSnapshot.data;
            if (result == null) {
              return _buildLookupError('Профиль статусы бос қайтты');
            }

            switch (result.status) {
              case AuthProfileStatus.worker:
                RoleSelectionCache.instance.clear();
                return const WorkerMainNavigation();
              case AuthProfileStatus.client:
                RoleSelectionCache.instance.clear();
                return ClientMainNavigation(userData: result.clientData);
              case AuthProfileStatus.conflict:
                return _buildConflictState();
              case AuthProfileStatus.missing:
                return _buildMissingProfile(user);
            }
          },
        );
      },
    );
  }
}
