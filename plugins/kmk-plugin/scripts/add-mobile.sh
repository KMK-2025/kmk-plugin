#!/usr/bin/env bash
# ==========================================================
#  إضافة تطبيق جوال (Flutter) إلى مشروع قائم — حتمي لا توليدي
#  الاستخدام:  bash add-mobile.sh <مجلد-المشروع> <اسم_التطبيق> <معرّف.الشركة>
#  مثال:       bash add-mobile.sh ./clinic clinic com.acme
#
#  ينشئ mobile/ بالبنية الكاملة، ويضيف موديول Mobile للخدمات
#  (فحص الإصدار + تسجيل الأجهزة)، ويثبّت أمر /build-mobile.
# ==========================================================
set -e

PROJECT_ARG="${1:-}"
APP="${2:-}"
ORG="${3:-}"

usage() { echo "الاستخدام: bash add-mobile.sh <مجلد-المشروع> <اسم_التطبيق> <معرّف.الشركة>"; exit 1; }
[ -n "$PROJECT_ARG" ] && [ -n "$APP" ] && [ -n "$ORG" ] || usage

echo "$APP" | grep -Eq '^[a-z][a-z0-9_]*$' \
  || { echo "❌ اسم التطبيق يجب أن يكون حروفًا إنجليزية صغيرة وأرقامًا وشرطة سفلية فقط، مثل: clinic"; exit 1; }
echo "$ORG" | grep -Eq '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$' \
  || { echo "❌ معرّف الشركة يجب أن يكون بهذا الشكل: com.acme"; exit 1; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY="$HERE/../mobile"
PROJECT="$(cd "$PROJECT_ARG" && pwd)"

[ -f "$HOME/.kmk-mobile-env" ] && . "$HOME/.kmk-mobile-env"

command -v flutter >/dev/null 2>&1 \
  || { echo "❌ Flutter غير متاح. شغّل أولًا: bash \"$HERE/setup-mobile.sh\""; exit 1; }
[ -d "$PROJECT/backend" ] || { echo "❌ لم أجد backend/ في $PROJECT — هذا ليس مشروعًا أنشأه /start."; exit 1; }
[ ! -e "$PROJECT/mobile" ] || { echo "❌ المجلد mobile/ موجود مسبقًا في هذا المشروع."; exit 1; }

cd "$PROJECT"

# ---------- التطبيق ----------
echo "▸ إنشاء تطبيق الجوال ($ORG.$APP)"
flutter create --org "$ORG" --project-name "$APP" --platforms android,ios mobile >/dev/null
cd mobile

echo "▸ تثبيت المكتبات (قد يأخذ دقيقتين)"
flutter pub add flutter_localizations --sdk=flutter >/dev/null
flutter pub add intl:any flutter_riverpod go_router dio flutter_secure_storage \
  package_info_plus freezed_annotation json_annotation >/dev/null
flutter pub add --dev build_runner freezed json_serializable mocktail >/dev/null

echo "▸ وضع البنية (features + shared)"
rm -f test/widget_test.dart
cp -r "$OVERLAY/app/." .
for f in test/*.dart; do
  sed -i.bak "s/__APP__/$APP/g" "$f" && rm -f "$f.bak"
done

# الترجمة تُولَّد تلقائيًا من ملفات ARB
if ! grep -q '^  generate: true' pubspec.yaml; then
  awk '{ print } /^flutter:[[:space:]]*$/ { print "  generate: true" }' pubspec.yaml > pubspec.yaml.tmp
  mv pubspec.yaml.tmp pubspec.yaml
fi
grep -q 'lib/shared/l10n/generated' .gitignore 2>/dev/null || printf '\n# ترجمة مولَّدة\nlib/shared/l10n/generated/\n' >> .gitignore

# Android: الإنترنت في كل البناءات، و HTTP المحلي في بناء التجربة فقط
MAIN_MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MAIN_MANIFEST" ] && ! grep -q 'android.permission.INTERNET' "$MAIN_MANIFEST"; then
  awk '!done && /<application/ { print "    <uses-permission android:name=\"android.permission.INTERNET\"/>"; done = 1 } { print }' \
    "$MAIN_MANIFEST" > "$MAIN_MANIFEST.tmp"
  mv "$MAIN_MANIFEST.tmp" "$MAIN_MANIFEST"
fi
mkdir -p android/app/src/debug
cat > android/app/src/debug/AndroidManifest.xml <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- بناء التجربة فقط: يسمح بالاتصال بالخدمات المحلية عبر HTTP -->
    <application android:usesCleartextTraffic="true"/>
</manifest>
XML

flutter pub get >/dev/null
flutter gen-l10n >/dev/null
dart format lib test >/dev/null
cd "$PROJECT"
echo "  ✔ التطبيق جاهز في mobile/"

# ---------- الخدمات ----------
echo "▸ إضافة خدمات الجوال (فحص الإصدار + تسجيل الأجهزة)"
cp -r "$OVERLAY/backend/." backend/
( cd backend && ./vendor/bin/pint >/dev/null 2>&1 || true )
echo "  ✔ موديول Mobile في backend/app/Modules/Mobile"

# ---------- الأوامر والدستور ----------
echo "▸ تثبيت أمر الجوال والوكيل"
mkdir -p .claude
cp -r "$OVERLAY/claude/." .claude/
if [ -f CLAUDE.md ] && ! grep -q 'kmk:mobile' CLAUDE.md; then
  printf '\n' >> CLAUDE.md
  cat "$OVERLAY/CLAUDE.mobile.md" >> CLAUDE.md
fi
if [ -f docs/api-contract.md ] && ! grep -q 'kmk:mobile' docs/api-contract.md; then
  printf '\n' >> docs/api-contract.md
  cat "$OVERLAY/api-contract.mobile.md" >> docs/api-contract.md
fi
mkdir -p .github/workflows
cp "$OVERLAY/github/mobile-release.yml" .github/workflows/mobile-release.yml
echo "  ✔ /build-mobile والوكيل flutter-builder"

# ---------- نقطة حفظ ----------
if git rev-parse --git-dir >/dev/null 2>&1; then
  git add -A
  git commit -q -m "إضافة تطبيق الجوال (Flutter) وخدماته" || true
  echo "  ✔ نقطة حفظ أُنشئت"
fi

cat <<EOF

════════════════════════════════════════
  ✅ تطبيق الجوال أُضيف للمشروع
════════════════════════════════════════

  mobile/lib/features/     ← كل قسم موديول، كما في الموقع
  mobile/lib/shared/       ← المشترك: الخدمات، التصميم، الترجمة
  backend/app/Modules/Mobile ← فحص الإصدار وتسجيل الأجهزة

المتبقي:
  1. cd backend && php artisan migrate
  2. صِل هاتف Android بالكابل ثم:  /test mobile
  3. للإشعارات: مشروع Firebase بحساب صاحب المشروع (يُربط لاحقًا)

EOF
