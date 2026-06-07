import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/models/admin_log_model.dart';

/// Service to handle all Firestore operations related to Admin Activity Logs.
class AdminLogService {
  AdminLogService._privateConstructor();
  static final AdminLogService instance = AdminLogService._privateConstructor();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<AdminLogModel> get _logsRef =>
      _db.collection('admin_logs').withConverter<AdminLogModel>(
            fromFirestore: (snapshot, _) => AdminLogModel.fromFirestore(snapshot),
            toFirestore: (model, _) => model.toMap(),
          );

  /// Saves a new admin activity log to Firestore.
  Future<void> saveLog(AdminLogModel log) async {
    try {
      await _logsRef.add(log);
    } catch (e) {
      throw Exception('Gagal menyimpan log aktivitas admin: $e');
    }
  }

  /// Helper to quickly log an action.
  Future<void> logAction({
    required String adminName,
    required String actionType,
    required String description,
  }) async {
    final log = AdminLogModel(
      id: '',
      adminName: adminName,
      actionType: actionType,
      description: description,
      timestamp: DateTime.now(),
    );
    await saveLog(log);
  }

  /// Streams admin logs in real-time ordered by timestamp descending.
  Stream<List<AdminLogModel>> getAdminLogsStream({int? limit}) {
    Query<AdminLogModel> query = _logsRef.orderBy('timestamp', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}
