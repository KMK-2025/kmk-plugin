<!-- kmk:mobile -->
---

## تطبيق الجوال — `mobile/` (Flutter)

هذا المشروع له تطبيق جوال يستهلك **نفس الخدمات** التي يستهلكها الموقع. مع صاحب المشروع قل "التطبيق" أو "الجوال" — لا Flutter ولا APK ولا build.

**التقنيات:** Flutter · Riverpod · go_router · dio · freezed + json_serializable · flutter_secure_storage · gen-l10n
**الجودة:** flutter analyze (وضع صارم) · dart format · flutter test

### البنية — تطابق الموقع
```
mobile/lib/
├── app/                          ← نقطة الدخول والراوتر
├── features/invoices/            ← نفس اسم موديول الموقع، بـ snake_case
│   ├── pages/                    ← القائمة، النموذج، التفاصيل
│   ├── widgets/                  ← خاص بهذا الموديول فقط
│   ├── providers/                ← الحالة (Riverpod)
│   ├── services/invoices_service.dart
│   └── models/                   ← freezed، مطابقة حرفيًا للعقد
├── shared/
│   ├── api/                      ← عميل الخدمات ورقم النسخة — المكان الوحيد
│   ├── theme/                    ← الألوان والمسافات — المكان الوحيد
│   ├── widgets/feedback/         ← الحالات: Loading · Empty · Error · Unauthorized
│   ├── l10n/                     ← app_ar.arb و app_en.arb
│   └── app_version/ · push/ · utils/
```

### قواعد الجوال
- **ممنوع** أن يستورد موديول من داخل موديول آخر. المشترك مكانه `shared/`.
- كل استدعاء خدمة عبر `features/<x>/services/` مستخدمًا `dioProvider`. **ممنوع** Dio داخل شاشة، و**ممنوع** كتابة عنوان أو رقم نسخة — من `ApiConfig` فقط.
- كل نص من ملفات ARB عبر `AppLocalizations.of(context)`. **ممنوع** نص عربي داخل ملف Dart. المفاتيح camelCase تقابل مفاتيح الموقع: `invoices.list.title` ↔ `invoicesListTitle`، وبنفس المفاتيح في الملفين.
- كل لون ومسافة من `shared/theme/app_theme.dart`. **ممنوع** `Color(0x…)` أو أرقام مسافات داخل شاشة.
- الاتجاه RTL يأتي من اللغة تلقائيًا. استخدم `EdgeInsetsDirectional` و `AlignmentDirectional` و `start/end` — **ممنوع** `left/right`.
- كل شاشة بيانات تعرض الحالات الخمس عبر `shared/widgets/feedback/`.
- النماذج (models) بـ freezed + json_serializable وتطابق العقد حرفيًا. بعد تعديلها: `dart run build_runner build --delete-conflicting-outputs`، والملفات المولَّدة تُحفظ في Git.
- توكن الدخول في `TokenStorage` (مخزن مشفَّر) فقط.
- كل ملف أقل من 200 سطر. التسمية: ملفات `snake_case.dart`، أصناف `PascalCase`، متغيرات `camelCase`.

### التطبيق القديم يبقى في أيدي الناس — أهم قاعدة في المشروع
الموقع يتحدّث عند الجميع فورًا؛ التطبيق لا. إصدار قديم من التطبيق سيبقى يعمل على هاتف عميل لشهور.

- كل طلب من التطبيق يحمل `X-App-Version` و `X-Platform` (يضيفهما `AppHeadersInterceptor`).
- **ممنوع تغيير شكل ردّ في نسخة API قائمة.** حارس التوافق `ApiShape` يكشف ذلك آليًا في الاختبارات.
- عند كشف الكسر: **لا تسأل صاحب المشروع.** أعد النسخة القائمة كما كانت، شغّل `bash .claude/scripts/bump-api-version.sh "السبب"`، وانقل التغيير للنسخة الجديدة. السكربت يوجّه الإصدار القادم من التطبيق للنسخة الجديدة ويسجّلها في العقد.
- لإجبار الإصدارات القديمة على التحديث: ارفع `min_supported` في `backend/config/mobile.php`. لا تُحذف نسخة API قبل ذلك وبموافقة صاحب المشروع.
- `latest` في نفس الملف يُحدَّث مع كل نشر للتطبيق.

### الإشعارات
أي موديول يريد إشعار مستخدم يستدعي `App\Modules\Mobile\Services\PushNotifier::send()` — لا يتصل بـ Firebase مباشرة. الإرسال الفعلي يحتاج ربط مشروع Firebase بحساب صاحب المشروع؛ قبل ذلك تُسجَّل الإشعارات في السجل فقط.

### بوابة الجودة — الجوال
```bash
. ~/.kmk-mobile-env 2>/dev/null; cd mobile && flutter analyze && dart format --set-exit-if-changed lib test && flutter test
```
ابدأ كل أمر `flutter` أو `dart` أو `adb` بـ `. ~/.kmk-mobile-env 2>/dev/null;` لتتوفر المسارات.

### التجربة على الهاتف
```bash
. ~/.kmk-mobile-env 2>/dev/null
adb devices                               # الهاتف موصول؟
adb reverse tcp:8000 tcp:8000             # الهاتف يرى الخدمات المحلية عبر الكابل
cd mobile && flutter run -d <serial>      # تشغيل مع تحديث فوري
adb exec-out screencap -p > .claude/tmp/screen.png   # لقطة تفحصها بنفسك
```
بناء iOS يحتاج Mac: على Windows و Linux يُبنى iOS في GitHub Actions فقط.
