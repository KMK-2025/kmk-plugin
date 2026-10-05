import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/pages/home_page.dart';

/// كل مسارات التطبيق تُسجَّل هنا. كل قسم يضيف مساراته عند بنائه.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
    ],
  );
});
