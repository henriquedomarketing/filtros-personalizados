import 'dart:convert';
import 'dart:io';

import 'package:camera_marketing_app/models/company_model.dart';
import 'package:camera_marketing_app/models/filter_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

const BUCKET_NAME = "filtros";
const VIDEO_INPUT_BUCKET = "videos_input";
const BANNER_FILENAME = "banner_800";
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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filterFileName = "${company.name}__${name}__$timestamp.png";
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

  static Future<bool> uploadBanner(String imagePath) async {
    try {
      final file = File(imagePath);
      final storageRef = FirebaseStorage.instance
          .ref("/")
          .child(BANNER_FILENAME);
      await storageRef.putFile(file);
      print('Banner uploaded successfully!');
      return true;
    } catch (e, stackTrace) {
      print('Error uploading banner: $e');
      print(stackTrace);
      return false;
    }
  }

  static Future<String?> uploadAndProcessVideo(String videoPath, String filterUrl) async {
    try {
      print("[COMPANY_SERVICE] Uploading video to bucket!");
      final file = File(videoPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalFileName = videoPath.split('/').last;
      final videoFileName = "${timestamp}__${originalFileName}";
      final storageRef = FirebaseStorage.instance
          .ref(VIDEO_INPUT_BUCKET)
          .child(videoFileName);
      await storageRef.putFile(file);

      print("[COMPANY_SERVICE] DONE! videoName = $videoFileName filterUrl = $filterUrl");
      print("[COMPANY_SERVICE] Making request to process video!");
      final response = await http.post(
        // Uri.parse('http://localhost:5001/cameramarketing-91d5a/us-east1/processVideo'),
        Uri.parse('https://processvideo-27ncrf2gpq-ue.a.run.app'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'videoName': videoFileName,
          'filterUrl': filterUrl,
        }),
      );

      print("[COMPANY_SERVICE] DONE! status_code=${response.statusCode}");
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final outputVideoUrl = responseBody['videoUrl'] as String;
        print('[COMPANY_SERVICE] Video processed successfully: $outputVideoUrl');
        return outputVideoUrl;
      } else {
        throw Exception('Failed to process video: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error uploading video: $e');
      print(stackTrace);
      throw e;
    }
  }
}
