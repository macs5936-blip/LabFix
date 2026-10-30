import 'package:cloud_firestore/cloud_firestore.dart';

class LabService {
  LabService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _labs =>
      _firestore.collection('labs');

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchLabs({
    bool activeOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _labs;
    if (activeOnly) query = query.where('active', isEqualTo: true);
    return query.orderBy('name').snapshots().map((snapshot) => snapshot.docs);
  }

  Future<String> createLab({
    required String name,
    required String building,
    required String location,
    required int capacity,
    required String technicianId,
    String notes = '',
  }) async {
    final document = _labs.doc();
    await document.set({
      'name': name.trim(),
      'building': building.trim(),
      'location': location.trim(),
      'capacity': capacity,
      'technicianId': technicianId,
      'notes': notes.trim(),
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  Future<void> setLabActive(String labId, bool active) {
    return _labs.doc(labId).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
