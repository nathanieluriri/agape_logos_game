import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../features/multiplayer/application/resume_providers.dart';
import '../features/social/application/social_providers.dart';
import '../features/store/application/store_providers.dart';

/// The curated "refresh on resume" set: one-shot `FutureProvider`s that only
/// refetch on an explicit invalidation (pull-to-refresh, a matching mutation,
/// or a full app restart) and otherwise go stale for the rest of the session.
///
/// Add a newly identified stale provider here, and nowhere else, to have it
/// refresh automatically the next time the app returns to the foreground.
///
/// `publicProfileProvider` is intentionally omitted: it is already
/// `autoDispose`, so closing and reopening its page already re-fetches it.
final List<ProviderOrFamily> resumeRefreshProviders = <ProviderOrFamily>[
  activeMatchesProvider,
  matchHistoryProvider,
  storeCatalogProvider,
];

/// Invalidates [resumeRefreshProviders] whenever the app transitions to
/// [AppLifecycleState.resumed].
///
/// This is the single general hook for the "stale one-shot provider" bug
/// family: a page that only ever fetches once (no live listener) silently
/// serves a stale snapshot until a manual pull-to-refresh or a full restart.
/// Rather than hand-adding an invalidate call at every mutation site that
/// might affect one of these providers, this widget re-invalidates the whole
/// registered set in one place on every foreground resume.
///
/// Additive, not a replacement: existing per-mutation invalidations (on match
/// finish, forfeit, and so on) still fire for immediate in-session feedback.
/// This hook is the catch-all that guarantees freshness even when no such
/// mutation happened on this device (e.g. a friend's move landed while the
/// app was backgrounded).
///
/// Placed high in the widget tree (wrapping the whole app) so it observes
/// every resume regardless of which screen is on top. Does not overload the
/// existing `WidgetsBindingObserver` in `bootstrap.dart`, which owns sync
/// flushing and the profile refetch; this is a separate, dedicated observer
/// so each concern stays independently testable.
class ResumeRefreshGate extends ConsumerStatefulWidget {
  const ResumeRefreshGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ResumeRefreshGate> createState() => _ResumeRefreshGateState();
}

class _ResumeRefreshGateState extends ConsumerState<ResumeRefreshGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    for (final ProviderOrFamily provider in resumeRefreshProviders) {
      ref.invalidate(provider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
