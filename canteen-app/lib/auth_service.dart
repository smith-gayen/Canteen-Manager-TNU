import 'services/api_service.dart';

class AuthService {
  static Map<String, dynamic>? get currentUser => ApiService.currentUser;

  static Future<String?> registerUser({
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String phone,
    required String uid,
    required String hostel,
    required String room,
    required String password,
  }) async {
    return ApiService.registerUser(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      phone: phone,
      uid: uid,
      hostel: hostel,
      room: room,
      password: password,
    );
  }

  static Future<String?> login(String identifier, String password) async {
    return ApiService.login(identifier, password);
  }

  static Future<bool> isLoggedIn() async {
    return ApiService.isLoggedIn();
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    return ApiService.getCurrentUser();
  }

  static Future<void> logout() async {
    await ApiService.logout();
  }
}
