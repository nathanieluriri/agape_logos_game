// lib/preview/pond_previews.dart
//
// Design previews for the pond screens. Run with:
//   flutter widget-preview start
// (or open the Widget Previews panel in the IDE on Flutter 3.38+).
//
// These are static, provider-free compositions: the previewer runs on
// Flutter Web, so nothing here may import bootstrap, Drift, or the Flame
// ambient layer.
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../core/design/tokens/colors.dart';
import '../core/design/tokens/gradients.dart';
import '../core/design/tokens/spacing.dart';
import '../features/level_complete/presentation/widgets/level_progress_bar.dart';
import '../features/settings/presentation/widgets/settings_action_row.dart';
import '../features/settings/presentation/widgets/settings_header.dart';
import '../features/settings/presentation/widgets/settings_section.dart';
import '../features/settings/presentation/widgets/settings_switch_row.dart';
import '../shared/widgets/film_play_icon.dart';
import '../shared/widgets/lily_pad.dart';
import '../shared/widgets/play_pad_cluster.dart';
import '../shared/widgets/play_triangle.dart';
import '../shared/widgets/pond_icon_button.dart';
import '../shared/widgets/pond_loader.dart';
import '../shared/widgets/pond_pill_button.dart';
import '../shared/widgets/pond_switch.dart';
import '../shared/widgets/pond_top_bar.dart';
import '../shared/widgets/wordmark_logo.dart';

Widget _stage({double width = 390, double height = 844, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Center(
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.pond),
          child: child,
        ),
      ),
    ),
  );
}

@Preview(name: 'Home screen (static)')
Widget homeScreenPreview() {
  return _stage(
    child: Column(
      children: [
        PondTopBar(coins: 9999, onSettings: () {}, onAddCoins: () {}),
        const Spacer(),
        const WordmarkLogo(),
        const Spacer(),
        PlayPadCluster(
          nextLabel: 'Lv.26',
          onPlay: () {},
          secondaryIcon: const Icon(
            Icons.account_balance_wallet,
            size: 26,
            color: AppColors.padLabel,
          ),
          secondaryLabel: 'Withdraw',
          onSecondary: () {},
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    ),
  );
}

@Preview(name: 'Level complete screen (static)')
Widget levelCompleteScreenPreview() {
  return _stage(
    child: Column(
      children: [
        PondTopBar(coins: 9999, onSettings: () {}, onAddCoins: () {}),
        const SizedBox(height: AppSpacing.lg),
        const WordmarkLogo(),
        const SizedBox(height: AppSpacing.xl),
        const LevelProgressBar(
          label: 'Level 3 Completed!',
          fraction: 5 / 8,
          fractionText: '5/8',
        ),
        const Spacer(),
        PlayPadCluster(
          nextLabel: 'Lv.26',
          onPlay: () {},
          secondaryIcon: const FilmPlayIcon(size: 30),
          secondaryLabel: 'Bonus Gift',
          onSecondary: () {},
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    ),
  );
}

@Preview(name: 'Play pad (green, notched)')
Widget playPadPreview() {
  return _stage(
    width: 300,
    height: 300,
    child: const Center(
      child: LilyPad(
        size: 180,
        rotationDegrees: -135,
        palette: LilyPadPalette.green,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayTriangle(size: 52),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Lv.26',
              style: TextStyle(
                color: AppColors.padLabel,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

@Preview(name: 'Bonus pad (blue, smooth)')
Widget bonusPadPreview() {
  return _stage(
    width: 240,
    height: 240,
    child: const Center(
      child: LilyPad(
        size: 104,
        shape: PadShape.smooth,
        rotationDegrees: 25,
        palette: LilyPadPalette.bonusBlue,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilmPlayIcon(size: 30),
            SizedBox(height: AppSpacing.xxs),
            Text(
              'Bonus Gift',
              style: TextStyle(
                color: AppColors.padLabel,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

@Preview(name: 'Top bar (settings + coin pill)')
Widget topBarPreview() {
  return _stage(
    height: 120,
    child: Center(
      child: PondTopBar(coins: 9999, onSettings: () {}, onAddCoins: () {}),
    ),
  );
}

@Preview(name: 'Level progress bar')
Widget progressBarPreview() {
  return _stage(
    height: 200,
    child: const Center(
      child: LevelProgressBar(
        label: 'Level 3 Completed!',
        fraction: 5 / 8,
        fractionText: '5/8',
      ),
    ),
  );
}

@Preview(name: 'Settings screen (static)')
Widget settingsScreenPreview() {
  return _stage(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsHeader(title: 'Settings'),
          const SizedBox(height: AppSpacing.lg),
          SettingsSection(
            title: 'Sound',
            children: [
              SettingsSwitchRow(
                label: 'Sound effects',
                value: true,
                onChanged: (_) {},
              ),
              SettingsSwitchRow(
                label: 'Music',
                value: false,
                onChanged: (_) {},
              ),
            ],
          ),
          SettingsSection(
            title: 'Account',
            children: [
              SettingsActionRow(label: 'Sign out', onTap: () {}),
              SettingsActionRow(
                label: 'Delete account',
                danger: true,
                icon: Icons.delete_outline,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

@Preview(name: 'Pond controls')
Widget pondControlsPreview() {
  return _stage(
    height: 560,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PondSwitch(value: true, onChanged: (_) {}),
          const SizedBox(height: AppSpacing.sm),
          PondSwitch(value: false, onChanged: (_) {}),
          const SizedBox(height: AppSpacing.lg),
          PondPillButton(label: 'Continue', onPressed: () {}),
          const SizedBox(height: AppSpacing.sm),
          PondPillButton(
            label: 'Not now',
            variant: PondPillVariant.quiet,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          PondPillButton(
            label: 'Delete',
            variant: PondPillVariant.danger,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.lg),
          PondIconButton(icon: Icons.arrow_back_rounded, onPressed: () {}),
          const SizedBox(height: AppSpacing.lg),
          const PondLoader(label: 'Loading puzzle'),
          const SizedBox(height: AppSpacing.lg),
          const PondLoader(label: 'Loading account'),
          const SizedBox(height: AppSpacing.lg),
          const PondLoader(label: 'Loading settings'),
          const SizedBox(height: AppSpacing.lg),
          const PondLoader(label: 'Loading the store'),
        ],
      ),
    ),
  );
}
