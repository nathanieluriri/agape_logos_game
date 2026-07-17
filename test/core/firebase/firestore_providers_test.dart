import 'package:agape_logos_game/core/firebase/firestore_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFirestore extends Fake implements FirebaseFirestore {}

void main() {
  test('firebaseFirestoreProvider is overridable for tests', () {
    final fake = _FakeFirestore();
    final container = ProviderContainer(
      overrides: [firebaseFirestoreProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    expect(container.read(firebaseFirestoreProvider), same(fake));
  });
}
