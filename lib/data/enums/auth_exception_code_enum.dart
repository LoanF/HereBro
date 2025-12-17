enum AuthExceptionCode {
  emailAlreadyInUse('email-already-in-use', 'Cet email est déjà utilisé.'),
  weakPassword(
    'weak-password',
    'Le mot de passe est trop faible (6 caractères min).',
  ),
  userNotFound('user-not-found', 'Aucun utilisateur trouvé avec cet email..'),
  wrongPassword('wrong-password', 'Mot de passe incorrect.'),
  invalidEmail('invalid-email', 'L\'adresse email est mal formatée.'),
  invalidCredential(
    'invalid-credential',
    'L\'adresse email ou le mot de passe est incorrect.',
  ),
  channelError(
    'channel-error',
    'Veuillez spécifier un email et un mot de passe.',
  );

  const AuthExceptionCode(this.code, this.message);

  final String code;
  final String message;

  static String getMessageFromCode(String code) {
    for (var exception in AuthExceptionCode.values) {
      if (exception.code == code) {
        return exception.message;
      }
    }
    return 'Erreur de connexion inconnue.';
  }
}
