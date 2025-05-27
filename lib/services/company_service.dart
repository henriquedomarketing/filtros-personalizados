import 'dart:convert';
import 'dart:io';

import 'package:camera_marketing_app/models/company_model.dart';
import 'package:camera_marketing_app/models/filter_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

const BUCKET_NAME = "filtros";
final JsonEncoder encoder = JsonEncoder.withIndent('  ');

final MOCK_COMPANY = CompanyModel(filters: [
  FilterModel(name: "My Filter", url: "https://www.gstatic.com/mobilesdk/240501_mobilesdk/firebase_28dp.png", category: "Vendas"),
], login: "admin@admin.com", name: "ADMIN", admin: false);

final MOCK_ADMIN = CompanyModel(filters: [
  FilterModel(name: "My Filter", url: "https://www.gstatic.com/mobilesdk/240501_mobilesdk/firebase_28dp.png", category: "Vendas"),
], login: "admin@admin.com", name: "ADMIN", admin: true);

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
      print("[REGISTER COMPANY] start");
      // Cria o usuário com e-mail e senha
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      print("[REGISTER COMPANY] created userCredential ${userCredential.toString()}");
      // Obtém o UID do usuário criado
      String uid = userCredential.user!.uid;

      // Salva informações adicionais no Firestore
      CompanyModel docModel = CompanyModel(name: name, login: email, admin: false, filters: []);
      await usersDb.doc(uid).set(docModel);
      print("[REGISTER COMPANY] saved doc to firestore");
      print(encoder.convert(docModel.toJson()));
      print('Usuário registrado com sucesso!');
      return null;
    } on FirebaseAuthException catch (e, stackTrace) {
      print('Erro ao registrar usuário: ${e.message}');
      print(stackTrace);
      return 'Erro ao registrar usuário: ${e.message}';
    } catch (e, stackTrace) {
      print('Erro ao registrar usuário: $e');
      print(stackTrace);
      return 'Erro desconhecido: $e';
    }
  }

  static Future<CompanyModel?> login(String email, String password) async {
    // await Future.delayed(Duration(seconds: 1));
    // return MOCK_ADMIN;
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    String uid = userCredential.user!.uid;
    final CompanyModel doc = await usersDb.doc(uid).get().then((s) => s.data() as CompanyModel);
    print("LOGIN SUCESSFUL:");
    print(encoder.convert(doc));
    return doc;
  }

  static Future<void> createFilterForCompany(String name, String filePath, String category, CompanyModel company, {int order = 0}) async {
    try {
      final file = File(filePath);
      final filterFileName = "${company.name}__$name.png";
      final storageRef = FirebaseStorage.instance
          .ref(BUCKET_NAME)
          .child(filterFileName);
      await storageRef.putFile(file);
      final bucketUrl = await storageRef.getDownloadURL();

      final orderedFilters = company.filters;
      orderedFilters.insert(order, FilterModel(name: name, url: bucketUrl, category: category));
      await usersDb.doc(company.uid!).update({'filters': orderedFilters.map((f) => f.toJson()).toList()});
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
    }
  }

  static Future<List<CompanyModel>> fetchCompanies() async {
    // await Future.delayed(Duration(seconds: 1));
    // return [
    //   CompanyModel(name: "Empresa 1", filters: [
    //     FilterModel(name: "ABC", url: ""),
    //     FilterModel(name: "DEF", url: ""),
    //   ]),
    //   CompanyModel(name: "Empresa 2", filters: [])
    // ];
    final usersRef = await usersDb.where('admin', isEqualTo: false).get();
    final users = usersRef.docs;
    return users.map((s) {
      final data = s.data() as CompanyModel;
      return CompanyModel.fromJson({...data.toJson(), 'uid': s.id});
    }).toList();
  }
}
