import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

class AppVersionStatus {
  const AppVersionStatus({required this.mustUpdate, this.storeUrl});

  final bool mustUpdate;
  final String? storeUrl;
}

/// يسأل الخادم عند فتح التطبيق: هل هذا الإصدار ما زال مدعومًا؟
/// عند انقطاع الاتصال لا نمنع المستخدم — الخادم نفسه يرفض الإصدار القديم.
final appVersionStatusProvider = FutureProvider<AppVersionStatus>((ref) async {
  final dio = ref.watch(dioProvider);

  try {
    final response = await dio.get<Map<String, dynamic>>('/app/version');
    final data = response.data?['data'] as Map<String, dynamic>?;

    return AppVersionStatus(
      mustUpdate: data?['must_update'] as bool? ?? false,
      storeUrl: data?['store_url'] as String?,
    );
  } on DioException {
    return const AppVersionStatus(mustUpdate: false);
  }
});
