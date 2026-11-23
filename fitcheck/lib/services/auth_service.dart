import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  // current user getter
  User? get currentUser => firebaseAuth.currentUser;

  // gets the auth state changes stream
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // sign in method
  Future<UserCredential> signIn({required String email, required String password}) async {
    return await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  // sign up method
  Future<UserCredential> signUp({required String email, required String password}) async {
    return await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // sign out method
  Future<void> signOut() async {
    return await firebaseAuth.signOut();
  }

  // reset password method (sends the reset email)
  Future<void> resetPassword({required String email}) async {
    return await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser?.updateDisplayName(username);
  }

  // CHANGED: new. Checks a password is correct by signing the user in again.
  // Firebase wants a recent login before sensitive actions (changing the
  // password, deleting the account). Throws if the password is wrong.
  Future<void> reauthenticate({required String password}) async {
    final user = currentUser!;
    final credential = EmailAuthProvider.credential(email: user.email!, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  // CHANGED: no longer takes an email and password. Call reauthenticate()
  // first, so a wrong password stops things before anything is deleted.
  Future<void> deleteAccount() async {
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  // CHANGED: no longer takes an email, it uses the signed in user's own.
  // Checks the current password, then sets the new one.
  Future<void> resetPasswordFromCurrentPassword({required String currentPassword, required String newPassword}) async {
    await reauthenticate(password: currentPassword);
    await currentUser!.updatePassword(newPassword);
  }
}