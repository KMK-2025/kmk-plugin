import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api_config.dart';
import 'token_storage.dart';

/// عميل الخدمات الوحيد في التطبيق. كل service يأخذه من هنا.
final dioProvider = Provider<Dio>((ref) {
  final tokens = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.root,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: <String, Object>{'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    AppHeadersInterceptor(readToken: tokens.read, readAppVersion: _readAppVersion),
  );

  return dio;
});

Future<String> _readAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}

/// يضيف لكل طلب: نوع الجهاز، رقم إصدار التطبيق، وتوكن الدخول.
/// الخادم يعتمد على رقم الإصدار ليرفض الإصدارات غير المدعومة.
class AppHeadersInterceptor extends Interceptor {
  AppHeadersInterceptor({required this.readToken, required this.readAppVersion});

  final Future<String?> Function() readToken;
  final Future<String> Function() readAppVersion;

  static String get platformName =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers['X-Platform'] = platformName;
    options.headers['X-App-Version'] = await readAppVersion();

    final token = await readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }
}
