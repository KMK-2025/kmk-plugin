import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => const TokenStorage());

/// يحفظ توكن الدخول في مخزن الجهاز المشفَّر — لا في SharedPreferences.
class TokenStorage {
  const TokenStorage();

  static const String _key = 'auth_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<String?> read() => _storage.read(key: _key);

  Future<void> write(String token) => _storage.write(key: _key, value: token);

  Future<void> clear() => _storage.delete(key: _key);
}
