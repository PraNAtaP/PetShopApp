import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/services/firestore_service.dart';

class FunFactBannerModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String topic;
  final DateTime createdAt;
  final bool isActive;

  FunFactBannerModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
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
    imageUrl: data['imageUrl'] ?? '',
    topic: data['topic'] ?? '',
    createdAt: (data['createdAt'] as Timestamp).toDate(),
    isActive: data['isActive'] ?? true,
  );
}
 
 Map<String, dynamic> toMap() {
      return {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'topic': topic,
        'createdAt': createdAt,
        'isActive': isActive,
      };
   }
}
