import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/services/firestore_service.dart';

class FunFactBannerModel {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final List<int> gradientColors;
  final String topic;
  final DateTime createdAt;
  final bool isActive;

  FunFactBannerModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.gradientColors,
    required this.topic,
    required this.createdAt,
    required this.isActive,
  });
  factory FunFactBannerModel.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  return FunFactBannerModel(
    id: doc.id,
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    emoji: data['emoji'] ?? '',
    gradientColors: List<int>.from(data['gradientColors'] ?? []),
    topic: data['topic'] ?? '',
    createdAt: (data['createdAt'] as Timestamp).toDate(),
    isActive: data['isActive'] ?? true,
  );
}
 
 Map<String, dynamic> toMap() {
      return {
        'title': title,
        'description': description,
        'emoji': emoji,
        'gradientColors': gradientColors,
        'topic': topic,
        'createdAt': createdAt,
        'isActive': isActive,
      };
   }
}
