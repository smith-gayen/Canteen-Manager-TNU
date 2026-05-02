import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

class ApiService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _currentUserKey = 'current_user';

  static String? _token;
  static Map<String, dynamic>? currentUser;

  static Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}/api$path');

  static Future<void> _saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    _token = accessToken;
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_currentUserKey, jsonEncode(user));
  }

  static Future<void> _hydrateSession() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_accessTokenKey);
    final cachedUser = prefs.getString(_currentUserKey);
    if (cachedUser != null && currentUser == null) {
      currentUser = jsonDecode(cachedUser) as Map<String, dynamic>;
    }
  }

  static Map<String, String> _headers({bool withAuth = true}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static String _extractError(dynamic decoded, int statusCode) {
    if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
      final detail = decoded['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        }
      }
      return detail.toString();
    }
    return 'Request failed with status $statusCode';
  }

  static Map<String, dynamic> _normalizeUser(Map<String, dynamic> user) {
    return {
      'id': user['id'],
      'firstName': user['first_name'] ?? '',
      'middleName': user['middle_name'] ?? '',
      'lastName': user['last_name'] ?? '',
      'email': user['email'] ?? '',
      'phone': user['phone'] ?? '',
      'uid': user['uid'] ?? '',
      'hostel': user['hostel'] ?? '',
      'room': user['room'] ?? '',
      'role': user['role'] ?? '',
    };
  }

  static Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    if (withAuth) {
      await _hydrateSession();
    }

    final response = http.Request(method, _uri(path))
      ..headers.addAll(_headers(withAuth: withAuth))
      ..body = body == null ? '' : jsonEncode(body);
    final streamed = await response.send();
    final responseBody = await streamed.stream.bytesToString();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      if (streamed.statusCode == 401 && withAuth) {
        await logout();
      }
      throw Exception(_extractError(decoded, streamed.statusCode));
    }
    return decoded;
  }

  static Future<String?> login(String identifier, String password) async {
    try {
      final tokenResponse =
          await _request(
                'POST',
                '/auth/login',
                body: {'identifier': identifier, 'password': password},
                withAuth: false,
              )
              as Map<String, dynamic>;
      final accessToken = tokenResponse['access_token']?.toString();
      final refreshToken = tokenResponse['refresh_token']?.toString();
      if (accessToken == null || refreshToken == null) {
        return 'Login succeeded but the backend did not return tokens.';
      }
      _token = accessToken;
      final me = await _request('GET', '/auth/me') as Map<String, dynamic>;
      await _saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: _normalizeUser(me),
      );
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

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
    try {
      await _request(
        'POST',
        '/auth/register',
        withAuth: false,
        body: {
          'first_name': firstName,
          'middle_name': middleName.isEmpty ? null : middleName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'uid': uid,
          'hostel': hostel,
          'room': room,
          'password': password,
        },
      );
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  static Future<bool> isLoggedIn() async {
    await _hydrateSession();
    if (_token == null) return false;
    try {
      final me = await _request('GET', '/auth/me') as Map<String, dynamic>;
      currentUser = _normalizeUser(me);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, jsonEncode(currentUser));
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    await _hydrateSession();
    if (currentUser != null) return currentUser;
    if (_token == null) return null;
    final me = await _request('GET', '/auth/me') as Map<String, dynamic>;
    currentUser = _normalizeUser(me);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(currentUser));
    return currentUser;
  }

  static Future<void> logout() async {
    _token = null;
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_currentUserKey);
  }

  static Future<List<dynamic>> getMeals() async {
    final decoded = await _request('GET', '/meals/slots');
    return decoded is List ? decoded : <dynamic>[];
  }

  static Future<Map<String, dynamic>> getMenu({
    required String date,
    required int slotId,
  }) async {
    final encodedDate = Uri.encodeQueryComponent(date);
    final decoded = await _request('GET', '/meals/menu?date=$encodedDate&slot_id=$slotId');
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> createBooking(
    int slotId,
    String date,
    List<int> itemIds,
  ) async {
    final decoded = await _request(
      'POST',
      '/bookings',
      body: {
        'slot_id': slotId,
        'date': date,
        'item_ids': itemIds,
      },
    );
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> getQrData(int bookingId) async {
    final decoded = await _request('GET', '/tokens/qr-data/$bookingId');
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<List<dynamic>> getBookingHistory() async {
    final decoded = await _request('GET', '/bookings/history/list');
    return decoded is List ? decoded : <dynamic>[];
  }
}
