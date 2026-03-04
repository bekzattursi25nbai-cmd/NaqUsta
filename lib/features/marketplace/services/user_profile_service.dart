import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kuryl_kz/features/marketplace/models/public_profile_model.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _publicProfiles =>
      _firestore.collection('public_profiles');

  Future<WorkerPublicProfile?> getWorkerProfile(String workerId) async {
    final doc = await _firestore.collection('workers').doc(workerId).get();
    if (!doc.exists) return null;
    return WorkerPublicProfile.fromMap(
      doc.data() ?? <String, dynamic>{},
      doc.id,
    );
  }

  Future<ClientPublicProfile?> getClientProfile(String clientId) async {
    final publicDoc = await _publicProfiles.doc(clientId).get();
    if (publicDoc.exists) {
      return ClientPublicProfile.fromMap(
        publicDoc.data() ?? <String, dynamic>{},
        publicDoc.id,
      );
    }

    // Avoid forbidden cross-user reads from /users for non-owners.
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != clientId) return null;

    final usersDoc = await _firestore.collection('users').doc(clientId).get();
    if (usersDoc.exists) {
      return ClientPublicProfile.fromMap(
        usersDoc.data() ?? <String, dynamic>{},
        usersDoc.id,
      );
    }

    final legacyDoc = await _firestore
        .collection('clients')
        .doc(clientId)
        .get();
    if (!legacyDoc.exists) return null;

    return ClientPublicProfile.fromMap(
      legacyDoc.data() ?? <String, dynamic>{},
      legacyDoc.id,
    );
  }

  Future<ClientPublicProfile?> getClientPublicProfile(String clientId) async {
    final doc = await _publicProfiles.doc(clientId).get();
    if (!doc.exists) return null;
    return ClientPublicProfile.fromMap(doc.data() ?? <String, dynamic>{}, doc.id);
  }
}
