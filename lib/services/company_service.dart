import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyService {

  static Future<void> registerCompany(String email, String password, String name) async {
    try {
      // Cria o usuário com e-mail e senha
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Obtém o UID do usuário criado
      String uid = userCredential.user!.uid;

      // Salva informações adicionais no Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'admin': false,
      });
      print('Usuário registrado com sucesso!');
    } on FirebaseAuthException catch (e) {
      print('Erro ao registrar usuário: ${e.message}');
    }
  }
}