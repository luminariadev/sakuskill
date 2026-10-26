abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class AuthorizationFailure extends Failure {
  const AuthorizationFailure(super.message);
}

class SecurityFailure extends Failure {
  const SecurityFailure(super.message);
}

class StateMachineFailure extends Failure {
  const StateMachineFailure(super.message);
}
