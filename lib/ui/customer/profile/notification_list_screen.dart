import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    if (_currentUser == null) return;
    try {
      final query = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _currentUser.uid)
          .where('read', isEqualTo: false)
          .get();

      if (query.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in query.docs) {
          batch.update(doc.reference, {'read': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'adoption_cancellation':
        return Icons.cancel_schedule_send_rounded;
      case 'grooming_booking':
        return Icons.wash_rounded;
      case 'order_shipping':
        return Icons.local_shipping_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'adoption_cancellation':
        return Colors.red;
      case 'grooming_booking':
        return Colors.blue;
      case 'order_shipping':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Silakan login terlebih dahulu.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFC),
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: _currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Terjadi kesalahan: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          
          // Sort memory side descending since offline items might lack serverTimestamp initially
          final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
            ..sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return -1;
              if (bTime == null) return 1;
              return bTime.compareTo(aTime);
            });

          if (sortedDocs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_off_outlined,
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Belum Ada Notifikasi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Semua pemberitahuan tentang pesanan dan adopsi Anda akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Notifikasi';
              final body = data['body'] ?? '';
              final type = data['type'] as String?;
              final createdAt = data['createdAt'] as Timestamp?;
              final isRead = data['read'] as bool? ?? false;

              final timeText = createdAt != null
                  ? DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate())
                  : 'Baru saja';

              final iconColor = _getColorForType(type);
              final iconBgColor = iconColor.withValues(alpha: 0.1);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      // Navigate based on type
                      if (type == 'adoption_cancellation') {
                        context.push('/adoption-history');
                      } else if (type == 'grooming_booking') {
                        context.push('/grooming-history');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconForType(type),
                              color: iconColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isRead ? AppColors.textDark : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  body,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
