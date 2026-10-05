/// عنوان الخدمات ورقم نسخة الـ API — المكان الوحيد لهما في التطبيق.
///
/// [apiVersion] يُرفع آليًا بسكربت bump-api-version.sh؛ لا تعدّله يدويًا
/// ولا تكتب رقم نسخة داخل أي service.
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  static const String apiVersion = 'v1';

  static String get root => '$baseUrl/$apiVersion';
}
