import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user (for auto-login)
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign Up
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber
  }) async {
    try {
      // 1. Create Auth User
      UserCredential cred = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      // 2. Create User Model
      UserModel newUser = UserModel(
          uid: cred.user!.uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber
      );

      // 3. Save to Firestore (The "users" collection)
      await _firestore.collection('users').doc(cred.user!.uid).set(newUser.toMap());

    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign In
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Login Failed: ${e.toString()}');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}