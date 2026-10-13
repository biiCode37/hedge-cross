import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_controller.dart';
import 'design_system.dart';
import 'login_screen.dart';
import 'pending_approval_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({
    super.key,
    required this.child,
    this.bypassAuth = false,
  });

  final Widget child;
  final bool bypassAuth;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.bypassAuth) {
        ref.read(authControllerProvider.notifier).restoreSession();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bypassAuth) return widget.child;

    final state = ref.watch(authControllerProvider);

    if (state.isLoading && state.user == null) {
      final theme = Theme.of(context);
      final palette = theme.extension<HedgePalette>();
      return Scaffold(
        backgroundColor: palette?.background ?? HedgeTokens.obsidian,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette?.raised ?? HedgeTokens.obsidianRaised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HedgeTokens.amber),
                  boxShadow: HedgeTokens.neonGlow(HedgeTokens.amber, intensity: 0.5),
                ),
                child: const Icon(Icons.alt_route, color: HedgeTokens.amber, size: 28),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(HedgeTokens.electricCyan),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isAuthenticated) {
      return widget.child;
    }

    if (state.isPendingApproval) {
      final user = state.user!;
      return PendingApprovalScreen(
        email: user.email,
        name: user.name,
        isRequesting: state.isLoading,
        onRequestAccess: () => ref.read(authControllerProvider.notifier).requestAccess(
              email: user.email,
              name: user.name,
            ),
        onSwitchAccount: () => ref.read(authControllerProvider.notifier).logout(),
      );
    }

    return LoginScreen(
      isLoading: state.isLoading,
      errorMessage: state.error,
      onGoogleSignIn: () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
    );
  }
}
