import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_state.dart';

/// Placeholder home data matching the reference screen. Reactive so widgets can
/// `ref.watch(homeControllerProvider.select(...))`; real data swaps in here only.
class HomeController extends Notifier<HomeState> {
  static const HomeState placeholder = HomeState(
    currency: 9999,
    levelLabel: 'Level 3 Completed!',
    progressDone: 5,
    progressTotal: 8,
    nextLevelLabel: 'Lv.26',
  );

  @override
  HomeState build() => placeholder;
}

final homeControllerProvider =
    NotifierProvider<HomeController, HomeState>(HomeController.new);
