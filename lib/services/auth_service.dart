import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<String?> loginAdmin(String email, String password) async {
    try {
      // Login Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ambil UID user setelah login
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Ambil data user di Firestore
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      // Pastikan role adalah admin
      if (doc.exists && doc["role"] == "admin") {
        return "admin";
      } else {
        return null; // bukan admin
      }
    } catch (e) {
      return null;
    }
  }
}
