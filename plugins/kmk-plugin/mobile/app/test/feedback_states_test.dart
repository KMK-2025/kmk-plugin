import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__APP__/shared/l10n/generated/app_localizations.dart';
import 'package:__APP__/shared/widgets/feedback/empty_state.dart';
import 'package:__APP__/shared/widgets/feedback/error_state.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('الحالة الفارغة تعرض النص العربي الافتراضي', (tester) async {
    await tester.pumpWidget(_wrap(const EmptyState()));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد بيانات بعد'), findsOneWidget);
  });

  testWidgets('حالة الخطأ تستدعي إعادة المحاولة', (tester) async {
    var retried = false;

    await tester.pumpWidget(_wrap(ErrorState(onRetry: () => retried = true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعادة المحاولة'));

    expect(retried, isTrue);
  });

  testWidgets('الاتجاه من اليمين إلى اليسار', (tester) async {
    await tester.pumpWidget(_wrap(const EmptyState()));
    await tester.pumpAndSettle();

    final direction = Directionality.of(tester.element(find.byType(EmptyState)));
    expect(direction, TextDirection.rtl);
  });
}
