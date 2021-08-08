import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart';
import 'package:notes/src/domain/auth/auth_failure.dart';
import 'package:notes/src/domain/auth/email_address.dart';
import 'package:notes/src/domain/auth/i_auth_facade.dart';
import 'package:notes/src/domain/auth/password.dart';

part 'sign_in_form_event.dart';
part 'sign_in_form_state.dart';

part 'sign_in_form_bloc.freezed.dart';

class SignInFormBloc extends Bloc<SignInFormEvent, SignInFormState> {
  final IAuthFacade _authFacade;

  SignInFormBloc(this._authFacade);

  @override
  SignInFormState get initialState => SignInFormState.initial();

  @override
  Stream<SignInFormState> mapEventToState(
    SignInFormEvent event,
  ) async* {
    yield* event.map(
      emailChanged: (emailChanged) async* {
        yield state.copyWith(
          emailAddress: EmailAddress(emailChanged.email),
          authFailureOrSuccessOption: none(),
        );
      },
      passwordChanged: (passwordChanged) async* {
        yield state.copyWith(
          password: Password(passwordChanged.password),
          authFailureOrSuccessOption: none(),
        );
      },
      registerWithEmailAndPasswordPressed: (regEmailPassPress) async* {
        yield* _performActionOnAuthFacadeWithEmailAndPassword(
          _authFacade.registerWithEmailAndPassword,
        );
      },
      signInWithEmailAndPasswordPressed: (signInWithEmailAndPassword) async* {
        yield* _performActionOnAuthFacadeWithEmailAndPassword(
          _authFacade.signInWithEmailAndPassword,
        );
      },
      signInWithGooglePressed: (signInWithGooglePressed) async* {
        yield state.copyWith(
          isSubmitting: true,
          authFailureOrSuccessOption: none(),
        );

        final authFailureOrSuccess = await _authFacade.signInWithGoogle();

        yield state.copyWith(
          isSubmitting: false,
          authFailureOrSuccessOption: some(authFailureOrSuccess),
        );
      },
    );
  }

  Stream<SignInFormState> _performActionOnAuthFacadeWithEmailAndPassword(
    Future<Either<AuthFailure, Unit>> Function(
            {required EmailAddress emailAddress, required Password password})
        formardCall,
  ) async* {
    Either<AuthFailure, Unit>? failureOrSuccess;

    if (state.emailAddress.isValid() && state.password.isValid()) {
      yield state.copyWith(
        isSubmitting: true,
        authFailureOrSuccessOption: none(),
      );

      failureOrSuccess = await formardCall(
          emailAddress: state.emailAddress, password: state.password);

      yield state.copyWith(
        isSubmitting: false,
        authFailureOrSuccessOption: some(failureOrSuccess),
      );
    }

    yield state.copyWith(
      isSubmitting: false,
      showErrorMessages: true,
      authFailureOrSuccessOption: optionOf(failureOrSuccess),
    );
  }
}
