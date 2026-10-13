import 'package:flutter/material.dart';
import 'design_system.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({
    super.key,
    required this.email,
    required this.name,
    required this.onRequestAccess,
    required this.onSwitchAccount,
    this.isRequesting = false,
  });

  final String email;
  final String name;
  final Future<void> Function() onRequestAccess;
  final VoidCallback onSwitchAccount;
  final bool isRequesting;

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
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: palette?.raised ?? HedgeTokens.obsidianRaised,
                    borderRadius: BorderRadius.circular(HedgeTokens.panelRadius),
                    border: Border.all(color: HedgeTokens.amber, width: 2),
                    boxShadow: HedgeTokens.neonGlow(HedgeTokens.amber, intensity: 0.6),
                  ),
                  child: const Icon(Icons.shield_outlined, color: HedgeTokens.amber, size: 36),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Akses Terbatas',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: HedgeTokens.cyberFont,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: HedgeTokens.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: HedgeTokens.amber.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'Menunggu Izin Koordinator',
                    style: TextStyle(
                      color: HedgeTokens.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette?.surface ?? HedgeTokens.obsidianSurface,
                  borderRadius: BorderRadius.circular(HedgeTokens.radius),
                  border: Border.all(color: palette?.border ?? Colors.white12),
                ),
                child: Column(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: palette?.muted ?? Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Akun Google ini belum terdaftar dalam sistem resmi Petugas Driving Order (PDO) Mikrotrans Utara. Silakan ajukan izin atau hubungi Koordinator Lapangan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette?.muted ?? Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              SizedBox(
                height: HedgeTokens.primaryButtonHeight,
                child: ElevatedButton.icon(
                  onPressed: isRequesting ? null : onRequestAccess,
                  icon: isRequesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: const Text(
                    'Ajukan Permohonan Akses',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HedgeTokens.electricCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HedgeTokens.radius),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSwitchAccount,
                child: const Text('Ganti Akun Google Lain'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
