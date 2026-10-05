import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_version_status.dart';
import 'update_required_page.dart';

/// يغطّي التطبيق كله: إن قال الخادم إن الإصدار غير مدعوم، تظهر شاشة
/// «حدّث التطبيق» بدل أي شاشة أخرى.
class VersionGate extends ConsumerWidget {
  const VersionGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appVersionStatusProvider);

    return status.when(
      data: (value) => value.mustUpdate ? UpdateRequiredPage(storeUrl: value.storeUrl) : child,
      loading: () => child,
      error: (error, stackTrace) => child,
    );
  }
}
