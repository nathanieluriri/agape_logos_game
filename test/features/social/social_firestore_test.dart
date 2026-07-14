import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agape_logos_game/features/social/data/social_firestore.dart';

void main() {
  test('watchRequests maps Timestamp -> millis and orders newest first',
      () async {
    final db = FakeFirebaseFirestore();
    final reqs =
        db.collection('users').doc('me').collection('friendRequests');
    await reqs.doc('u2').set({
      'fromUid': 'u2',
      'handle': 'bob',
      'displayName': 'Bob',
      'avatarId': 'avatar_01',
      'at': Timestamp.fromMillisecondsSinceEpoch(2000),
    });
    await reqs.doc('u3').set({
      'fromUid': 'u3',
      'handle': 'cara',
      'displayName': 'Cara',
      'avatarId': 'avatar_02',
      'at': Timestamp.fromMillisecondsSinceEpoch(5000),
    });

    final first = await SocialFirestore(db).watchRequests('me').first;

    expect(first.map((r) => r.fromUid).toList(), ['u3', 'u2']); // newest first
    expect(first.first.at, 5000);
    expect(first.first.handle, 'cara');
    expect(first.first.displayName, 'Cara');
    expect(first.first.avatarId, 'avatar_02');
  });

  test('watchRequests tolerates a missing at (defaults to 0)', () async {
    final db = FakeFirebaseFirestore();
    await db
        .collection('users')
        .doc('me')
        .collection('friendRequests')
        .doc('u9')
        .set({
      'fromUid': 'u9',
      'handle': 'dan',
      'displayName': 'Dan',
      'avatarId': 'avatar_03',
      'at': Timestamp.fromMillisecondsSinceEpoch(1000),
    });

    final first = await SocialFirestore(db).watchRequests('me').first;
    expect(first.single.at, 1000);
  });

  test('watchFriends maps Timestamp -> millis and orders newest first',
      () async {
    final db = FakeFirebaseFirestore();
    final friends = db.collection('users').doc('me').collection('friends');
    await friends.doc('f1').set({
      'uid': 'f1',
      'handle': 'eve',
      'displayName': 'Eve',
      'avatarId': 'avatar_04',
      'since': Timestamp.fromMillisecondsSinceEpoch(3000),
    });
    await friends.doc('f2').set({
      'uid': 'f2',
      'handle': 'fay',
      'displayName': 'Fay',
      'avatarId': 'avatar_05',
      'since': Timestamp.fromMillisecondsSinceEpoch(9000),
    });

    final first = await SocialFirestore(db).watchFriends('me').first;

    expect(first.map((f) => f.uid).toList(), ['f2', 'f1']); // newest first
    expect(first.first.since, 9000);
    expect(first.first.handle, 'fay');
  });
}
