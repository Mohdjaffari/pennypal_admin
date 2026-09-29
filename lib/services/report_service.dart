import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/report_model.dart';

class ReportService {
  static const String collectionName = 'reports';
  FirebaseFirestore? _firestoreInstance;

  FirebaseFirestore? get firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreInstance ??= FirebaseFirestore.instance;
        return _firestoreInstance;
      }
    } catch (e) {
      debugPrint("ReportService: Firestore unavailable: $e");
    }
    return null;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getReportsStream() {
    final fs = firestore;
    if (fs == null) return const Stream.empty();
    return fs.collection(collectionName).orderBy('generatedAt', descending: true).snapshots();
  }

  Future<bool> saveReport(GeneratedReportRecord report) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      await fs.collection(collectionName).doc(report.id).set(report.toMap());
      return true;
    } catch (e) {
      debugPrint("ReportService.saveReport error: $e");
      return false;
    }
  }

  Future<bool> deleteReport(String reportId) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      await fs.collection(collectionName).doc(reportId).delete();
      return true;
    } catch (e) {
      debugPrint("ReportService.deleteReport error: $e");
      return false;
    }
  }
}
