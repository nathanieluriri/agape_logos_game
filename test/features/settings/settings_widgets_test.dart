import 'package:agape_logos_game/features/settings/presentation/widgets/settings_action_row.dart';
import 'package:agape_logos_game/features/settings/presentation/widgets/settings_section.dart';
import 'package:agape_logos_game/features/settings/presentation/widgets/settings_switch_row.dart';
import 'package:agape_logos_game/shared/widgets/pond_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SettingsSwitchRow shows the label and reports toggles',
      (tester) async {
    bool? changed;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SettingsSwitchRow(
          label: 'Sound effects',
          value: true,
          onChanged: (v) => changed = v,
        ),
      ),
    ));
    expect(find.text('Sound effects'), findsOneWidget);
    await tester.tap(find.byType(PondSwitch));
    await tester.pump(const Duration(milliseconds: 300));
    expect(changed, isFalse);

    // The whole row is the tap target: tapping the label toggles too.
    changed = null;
    await tester.tap(find.text('Sound effects'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(changed, isFalse);
  });

  testWidgets('SettingsActionRow fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SettingsActionRow(label: 'Sign out', onTap: () => taps++),
      ),
    ));
    await tester.tap(find.text('Sign out'));
    expect(taps, 1);
  });

  testWidgets('SettingsSection renders its title and children', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SettingsSection(title: 'Sound', children: [Text('row')]),
      ),
    ));
    expect(find.text('SOUND'), findsOneWidget); // title is upper-cased
    expect(find.text('row'), findsOneWidget);
  });
}
