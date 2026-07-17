import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app-wide Cloud Firestore instance. Firebase is initialized in
/// `bootstrap()` (via `Firebase.initializeApp`) before the ProviderScope mounts,
/// so reading the default instance here is safe. Kept behind a provider so the
/// multiplayer listeners can be driven by a fake in tests (e.g. the
/// `fake_cloud_firestore` package) without a live backend.
final firebaseFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
