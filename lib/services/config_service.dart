import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigService {
  static Future<String> getSupportUrl() async {
    final firestore = FirebaseFirestore.instance;
    final docSnapshot =
        await firestore.collection('config').doc('supportUrl').get();
    final data = docSnapshot.data();
    return data?['url'] as String? ?? '';
  }

  static Future<void> setSupportUrl(String url) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('config').doc('supportUrl').set({'url': url});
  }
}