import 'dart:io';

import 'package:camera_marketing_app/models/company_model.dart';
import 'package:camera_marketing_app/types/firestore_types.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

const BUCKET_NAME = "filters";

class CompanyService {
  static CollectionReference usersDb = 
    FirebaseFirestore.instance.collection('users').withConverter(
      fromFirestore: (snapshot, _) => CompanyModel.fromJson(snapshot.data()!),
      toFirestore: (model, _) => (model as CompanyModel).toJson(),
    );

  static Future<String?> adminRegisterCompany(
    String email,
    String password,
    String name,
  ) async {
    try {
      // Cria o usuário com e-mail e senha
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Obtém o UID do usuário criado
      String uid = userCredential.user!.uid;

      // Salva informações adicionais no Firestore
      ICompanyFirestore doc =
          {'name': name, 'email': email, 'admin': false, 'filters': []}
              as ICompanyFirestore;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(doc as Map<String, dynamic>);
      print('Usuário registrado com sucesso!');
      return null;
    } on FirebaseAuthException catch (e) {
      print('Erro ao registrar usuário: ${e.message}');
      return 'Erro ao registrar usuário: ${e.message}';
    }
  }

  static Future<CompanyModel?> login(String email, String password) async {
    // await Future.delayed(Duration(seconds: 1));
    // return CompanyModel(filters: [], login: email, name: "ADMIN", password: password, admin: true);
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    String uid = userCredential.user!.uid;
    final CompanyModel doc = await usersDb.doc(uid).get().then((s) => s.data() as CompanyModel);
    return doc;
  }

  static Future<void> createFilterForCompany(String name, String filePath, CompanyModel company) async {
    try {
      final file = File(filePath);
      final filterFileName = "${company.name}__$name.png";
      final storageRef = FirebaseStorage.instance.ref().child(filterFileName);
      await storageRef.putFile(file);
      final bucketUrl = await storageRef.getDownloadURL();

      IFilterFirestore filter = {'name': name, 'url': bucketUrl} as IFilterFirestore;
      await usersDb.doc(company.user!.uid).update({'filters': FieldValue.arrayUnion([filter])});
    } catch (e) {
      print(e);
    }
  }
}
