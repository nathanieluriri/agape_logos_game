// test/shared/widgets/pond_text_field_test.dart
import 'package:agape_logos_game/shared/widgets/pond_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PondTextField shows its label and accepts input',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: PondTextField(controller: controller, label: 'Email'),
        ),
      ),
    ));
    expect(find.text('Email'), findsOneWidget);
    await tester.enterText(find.byType(PondTextField), 'frog@pond.com');
    expect(controller.text, 'frog@pond.com');
  });

  testWidgets('PondTextField runs its validator through the enclosing Form',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: PondTextField(
            label: 'Email',
            validator: (v) => (v == null || v.isEmpty) ? 'Enter your email' : null,
          ),
        ),
      ),
    ));
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
  });
}
