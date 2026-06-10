import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/models/user_model.dart';
import 'package:petshopapp/services/admin_log_service.dart';

class AdminUserService {
  static final AdminUserService instance = AdminUserService._internal();
  AdminUserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<UserModel>> getAllCustomersStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
          users.sort((a, b) {
            final dateA = a.createdAt ?? DateTime(0);
            final dateB = b.createdAt ?? DateTime(0);
            return dateB.compareTo(dateA);
          });
          return users;
        });
  }

  Future<void> toggleBlockUser(UserModel user, String adminName) async {
    final newStatus = !user.isBlocked;
    await _firestore.collection('users').doc(user.uid).update({
      'is_blocked': newStatus,
    });
    
    // Log the action
    final action = newStatus ? 'BLOKIR_USER' : 'UNBLOCK_USER';
    final desc = newStatus ? 'Memblokir akun pelanggan: ${user.nama} (${user.email})' : 'Membuka blokir akun pelanggan: ${user.nama} (${user.email})';
    
    await AdminLogService.instance.logAction(
      adminName: adminName,
      actionType: action,
      description: desc,
    );
  }
}
