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

  /// Returns a new DocumentReference for admin_logs. Useful for including logs in a batched write.
  DocumentReference getNewLogRef() {
    return _db.collection('admin_logs').doc();
  }

  /// Builds a serializable map for an admin log using server timestamp.
  Map<String, dynamic> buildLogMap({
    required String adminName,
    required String actionType,
    required String description,
    String? adminId,
    String? targetId,
    String? targetType,
  }) {
    final map = {
      'adminName': adminName,
      'actionType': actionType,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (adminId != null) map['adminId'] = adminId;
    if (targetId != null) map['targetId'] = targetId;
    if (targetType != null) map['targetType'] = targetType;
    return map;
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

  /// Streams admin logs filtered by category (Semua, Produk, Chat, Grooming, Adopsi)
  Stream<List<AdminLogModel>> getAdminLogsByCategoryStream({String category = 'Semua', int? limit}) {
    Query<AdminLogModel> query = _logsRef.orderBy('timestamp', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      final allLogs = snapshot.docs.map((doc) => doc.data()).toList();
      
      if (category == 'Semua') {
        return allLogs;
      }

      // Melakukan filtering lokal berdasarkan kecocokan actionType
      return allLogs.where((log) {
        final action = log.actionType.toUpperCase();
        switch (category.toUpperCase()) {
          case 'PRODUK':
            return action.contains('PRODUCT') || action.contains('PRODUK');
          case 'CHAT':
            return action.contains('CHAT') || action.contains('PESAN');
          case 'GROOMING':
            // Cocok dengan 'UPDATE_GROOMING_STATUS' yang dikirim dari GroomingService
            return action.contains('GROOMING'); 
          case 'ADOPSI':
            // Cocok dengan 'ADD_ANIMAL', 'UPDATE_ANIMAL', 'DELETE_ANIMAL', 'APPROVE_ADOPTION', dll.
            return action.contains('ANIMAL') || action.contains('ADOPTION') || action.contains('ADOPSI');
            
          default:
            return true;
        }
      }).toList();
    });
  }
}
