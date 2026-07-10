import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../../../shared/widgets/pond_top_bar.dart';
import '../../../profile/application/profile_providers.dart';
import '../../application/match_providers.dart';
import '../../domain/match_settings.dart';
import '../widgets/join_code_entry.dart';
import '../widgets/match_settings_form.dart';

/// Matchmaking: create a match (settings form) or join one (code entry). Thin
/// composition; the Function calls live in MatchRemote.
class MatchmakingPage extends ConsumerStatefulWidget {
  const MatchmakingPage({super.key});

  @override
  ConsumerState<MatchmakingPage> createState() => _MatchmakingPageState();
}

enum _Mode { choose, create, join }

class _MatchmakingPageState extends ConsumerState<MatchmakingPage> {
  _Mode _mode = _Mode.choose;
  bool _busy = false;
  String? _error;

  Future<void> _create(MatchSettings settings) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final out =
          await ref.read(matchServiceProvider).create(settings.toWire());
      if (!mounted) return;
      context.pushReplacement('/multiplayer/lobby/${out.matchId}');
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not create a match. Check your connection.';
        });
      }
    }
  }

  Future<void> _join(String code) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final matchId = await ref.read(matchServiceProvider).join(code);
      if (!mounted) return;
      context.pushReplacement('/multiplayer/lobby/$matchId');
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'That code did not match an open lobby.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(coinsProvider);
    return Scaffold(
      body: PondBackground(
        child: PondStage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PondTopBar(
                coins: coins,
                onSettings: () => context.push('/settings'),
                onAddCoins: () => context.push('/store'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _body(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_mode) {
      case _Mode.choose:
        return _Chooser(
          onCreate: () => setState(() => _mode = _Mode.create),
          onJoin: () => setState(() => _mode = _Mode.join),
        );
      case _Mode.create:
        return Column(
          children: [
            MatchSettingsForm(onCreate: _create, busy: _busy),
            if (_error != null) _ErrorText(_error!),
          ],
        );
      case _Mode.join:
        return Column(
          children: [
            JoinCodeEntry(onSubmit: _join, busy: _busy),
            if (_error != null) _ErrorText(_error!),
          ],
        );
    }
  }
}

class _Chooser extends StatelessWidget {
  const _Chooser({required this.onCreate, required this.onJoin});
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  @override
  Widget build(BuildContext context) {
    // Reuse the pond pill buttons for the two primary actions.
    return Column(
      children: [
        _BigAction(label: 'Create a match', icon: Icons.add_rounded, onTap: onCreate),
        const SizedBox(height: AppSpacing.md),
        _BigAction(label: 'Join with a code', icon: Icons.vpn_key_rounded, onTap: onJoin),
      ],
    );
  }
}

class _BigAction extends StatelessWidget {
  const _BigAction({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: const BoxDecoration(
            gradient: AppGradients.pondCard,
            borderRadius: AppRadii.card,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.padLabel),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.padLabel,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.dangerOnPond, fontSize: 13),
        ),
      );
}
