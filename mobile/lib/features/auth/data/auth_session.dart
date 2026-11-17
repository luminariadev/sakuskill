/// Menyimpan token JWT dan identitas pengguna aktif di memori sesi aplikasi.
class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  String? accessToken;
  String? userId;
  String? get id => userId;
  String? fullName;
  String? email;
  String? role;

  String? get userName => fullName;
  String? get userEmail => email;
  String? get userRole => role;

  bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;
  bool get isProvider => role == 'Penyedia Jasa';

  void save({
    required String token,
    String? id,
    String? name,
    String? userEmail,
    String? userRole,
  }) {
    accessToken = token;
    userId = id;
    fullName = name;
    email = userEmail;
    role = userRole;
  }

  void clear() {
    accessToken = null;
    userId = null;
    fullName = null;
    email = null;
    role = null;
  }
}
