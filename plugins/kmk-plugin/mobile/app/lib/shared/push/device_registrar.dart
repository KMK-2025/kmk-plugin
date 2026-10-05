import 'package:dio/dio.dart';

import '../api/api_client.dart';

/// يسجّل رمز الإشعارات لهذا الجهاز عند الخادم.
///
/// يُستدعى بعد تسجيل الدخول وعند كل تحديث للرمز. مصدر الرمز هو Firebase،
/// ويُربط بعد إعداد مشروع Firebase لهذا التطبيق.
Future<void> registerDevice(Dio dio, String pushToken) async {
  await dio.post<Map<String, dynamic>>(
    '/devices',
    data: <String, String>{
      'token': pushToken,
      'platform': AppHeadersInterceptor.platformName,
    },
  );
}
