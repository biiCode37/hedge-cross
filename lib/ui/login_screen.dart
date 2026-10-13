import 'package:flutter/material.dart';
import 'design_system.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.onGoogleSignIn,
    this.isLoading = false,
    this.errorMessage,
  });

  final Future<void> Function() onGoogleSignIn;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<HedgePalette>();

    return Scaffold(
      backgroundColor: palette?.background ?? HedgeTokens.obsidian,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: palette?.raised ?? HedgeTokens.obsidianRaised,
                    borderRadius: BorderRadius.circular(HedgeTokens.panelRadius),
                    border: Border.all(color: HedgeTokens.amber, width: 2),
                    boxShadow: HedgeTokens.neonGlow(HedgeTokens.amber, intensity: 0.8),
                  ),
                  child: const Icon(Icons.alt_route, color: HedgeTokens.amber, size: 44),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'HEDGE',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFamily: HedgeTokens.cyberFont,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Headway Generator',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: HedgeTokens.electricCyan,
                  fontWeight: FontWeight.w600,
                  fontFamily: HedgeTokens.cyberFont,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'By Mikrotrans Utara',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette?.muted ?? theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(HedgeTokens.radius),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                height: HedgeTokens.primaryButtonHeight,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onGoogleSignIn,
                  icon: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Icon(Icons.login, size: 22),
                  label: const Text(
                    'Masuk dengan Akun Google',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HedgeTokens.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HedgeTokens.radius),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
