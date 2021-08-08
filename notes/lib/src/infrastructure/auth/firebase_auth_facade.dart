import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:notes/src/domain/auth/email_address.dart';
import 'package:notes/src/domain/auth/auth_failure.dart';
import 'package:dartz/dartz.dart';
import 'package:notes/src/domain/auth/i_auth_facade.dart';
import 'package:notes/src/domain/auth/password.dart';

class FirebaseAuthFacade implements IAuthFacade {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthFacade(this._firebaseAuth, this._googleSignIn);

  @override
  Future<Either<AuthFailure, Unit>> registerWithEmailAndPassword(
      {required EmailAddress emailAddress, required Password password}) async {
    final emailAddressStr = emailAddress.getOrCrash();
    final passStr = password.getOrCrash();
    try {
      return await this
          ._firebaseAuth
          .createUserWithEmailAndPassword(
              email: emailAddressStr, password: passStr)
          .then((_) => right(unit));
    } on PlatformException catch (e) {
      if (e.code == 'email-already-in-use') {
        return left(const AuthFailure.emailAlreadyInUse());
      } else {
        return left(const AuthFailure.serverError());
      }
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signInWithEmailAndPassword(
      {required EmailAddress emailAddress, required Password password}) async {
    final emailAddressStr = emailAddress.getOrCrash();
    final passStr = password.getOrCrash();
    try {
      return await this
          ._firebaseAuth
          .signInWithEmailAndPassword(email: emailAddressStr, password: passStr)
          .then((_) => right(unit));
    } on PlatformException catch (e) {
      if (e.code == 'wrong-password' || e.code == "user-not-found") {
        return left(const AuthFailure.emailAlreadyInUse());
      } else {
        return left(const AuthFailure.serverError());
      }
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signInWithGoogle() async {
    try {
      final googleUser = await this._googleSignIn.signIn();
      if (googleUser == null) {
        return left(AuthFailure.cancelledByUser());
      }

      final googleAuth = await googleUser.authentication;
      final authCredential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);

      return _firebaseAuth
          .signInWithCredential(authCredential)
          .then((r) => right(unit));
    } on PlatformException catch (_) {
      return left(AuthFailure.serverError());
    }
  }
}
