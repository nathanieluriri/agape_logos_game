import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_page_header.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../application/match_providers.dart';
import '../../domain/match_settings.dart';
import '../widgets/join_code_entry.dart';
import '../widgets/match_settings_form.dart';

/// Which matchmaking form this page hosts. The chooser itself lives on the
/// multiplayer sheet (multiplayer_sheet.dart), not on this page.
enum MatchmakingMode { create, join }

/// Matchmaking form host: create a match (settings form) or join one (code
/// entry), selected by [mode]. Thin composition; the Function calls live in
/// MatchRemote.
class MatchmakingPage extends ConsumerStatefulWidget {
  const MatchmakingPage({super.key, this.mode = MatchmakingMode.create});

  final MatchmakingMode mode;

  @override
  ConsumerState<MatchmakingPage> createState() => _MatchmakingPageState();
}

class _MatchmakingPageState extends ConsumerState<MatchmakingPage> {
  bool _busy = false;
  String? _error;

  Future<void> _create(MatchSettings settings) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final out = await ref
          .read(matchServiceProvider)
          .create(settings.toWire());
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
    final isCreate = widget.mode == MatchmakingMode.create;
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: PondBackground(
        child: PondStage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PondPageHeader(
                title: isCreate ? 'Create a match' : 'Join a match',
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      if (isCreate)
                        MatchSettingsForm(onCreate: _create, busy: _busy)
                      else
                        JoinCodeEntry(onSubmit: _join, busy: _busy),
                      if (_error != null) _ErrorText(_error!),
                    ],
                  ),
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
