import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/models/funfact_banner_model.dart';

class FunFactBannerProvider
    extends ChangeNotifier {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  List<FunFactBannerModel> banners = [];

  FunFactBannerProvider() {
    fetchBanners();
  }

  // =========================
  // GET DATA REALTIME
  // =========================

  void fetchBanners() {

    _firestore
        .collection('funfact')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .listen((snapshot) {

      banners = snapshot.docs.map((doc) {

        return FunFactBannerModel
            .fromFirestore(doc);

      }).toList();

      notifyListeners();
    });
  }

  // =========================
  // ADD
  // =========================

  Future<void> addBanner(
    FunFactBannerModel banner,
  ) async {

    await _firestore
        .collection('funfact')
        .add(
          banner.toMap(),
        );
  }

  // =========================
  // DELETE
  // =========================

  Future<void> deleteBanner(
    String id,
  ) async {

    await _firestore
        .collection('funfact')
        .doc(id)
        .delete();
  }

  // =========================
  // TOGGLE ACTIVE
  // =========================

  Future<void> toggleStatus(
    String id,
    bool currentStatus,
  ) async {

    await _firestore
        .collection('funfact')
        .doc(id)
        .update({
      'isActive': !currentStatus,
    });
  }
}