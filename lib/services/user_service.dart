import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {

  static Future<void> registerUser(String email, String password, bool isAdmin) async {
    try {
      // Cria o usuário com e-mail e senha
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Obtém o UID do usuário criado
      String uid = userCredential.user!.uid;

      // Salva informações adicionais no Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'admin': isAdmin,
      });

      print('Usuário registrado com sucesso!');
    } on FirebaseAuthException catch (e) {
      print('Erro ao registrar usuário: ${e.message}');
    }
  }
}