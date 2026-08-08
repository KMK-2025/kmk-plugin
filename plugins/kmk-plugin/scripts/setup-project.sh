#!/usr/bin/env bash
# ==========================================================
#  تجهيز مشروع جديد بأمر واحد
#  الاستخدام:  bash تجهيز-مشروع.sh اسم-المشروع
#  ينفّذه المدرب مرة واحدة لكل مشروع، قبل المحاضرة.
# ==========================================================
set -e

NAME="${1:-}"
if [ -z "$NAME" ]; then
  echo "الاستخدام: bash تجهيز-مشروع.sh اسم-المشروع"
  exit 1
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$HERE/القالب"
TARGET="$(pwd)/$NAME"

if [ -d "$TARGET" ]; then
  echo "❌ المجلد $NAME موجود مسبقًا."
  exit 1
fi

echo "▸ إنشاء المشروع: $NAME"
mkdir -p "$TARGET"
cp -r "$TEMPLATE/." "$TARGET/"
cd "$TARGET"
chmod +x .claude/hooks/*.sh

# ---------- الفحوصات المسبقة ----------
echo "▸ فحص الأدوات المطلوبة"
MISSING=""
for tool in node npm git php composer; do
  command -v "$tool" >/dev/null 2>&1 || MISSING="$MISSING $tool"
done
# على Windows شغّل هذا السكربت من Git Bash لا من CMD أو PowerShell
case "$(uname -s)" in
  MINGW*|MSYS*) echo "  ℹ يعمل داخل Git Bash — جيد" ;;
esac
if [ -n "$MISSING" ]; then
  echo "⚠️  أدوات ناقصة:$MISSING"
  echo "   ثبّتها ثم أعد تشغيل السكربت."
  exit 1
fi
echo "  ✔ node $(node -v) · php $(php -r 'echo PHP_VERSION;')"

# ---------- الواجهة ----------
echo "▸ تجهيز الواجهة (قد يأخذ دقيقتين)"
npm create vite@latest frontend -- --template react-ts >/dev/null 2>&1
cd frontend
npm install >/dev/null 2>&1
npm install bootstrap bootstrap-icons react-router-dom axios \
  @tanstack/react-query react-hook-form zod @hookform/resolvers \
  zustand i18next react-i18next react-hot-toast >/dev/null 2>&1
npm install -D vite-plugin-pwa vitest >/dev/null 2>&1
mkdir -p src/{api,services,components/{ui,table,form,feedback},layouts,pages,hooks,store,types,utils,constants,locales,styles,assets/fonts}
echo '{}' > src/locales/ar.json
echo '{}' > src/locales/en.json
cd ..
echo "  ✔ الواجهة جاهزة"

# ---------- الخدمات ----------
echo "▸ تجهيز الخدمات (قد يأخذ ثلاث دقائق)"
composer create-project laravel/laravel backend --quiet >/dev/null 2>&1
cd backend
composer require laravel/sanctum spatie/laravel-permission --quiet >/dev/null 2>&1
composer require --dev laravel/pint pestphp/pest --quiet --with-all-dependencies >/dev/null 2>&1
php artisan install:api --no-interaction >/dev/null 2>&1
cd ..
echo "  ✔ الخدمات جاهزة"

# ---------- Git ----------
echo "▸ تجهيز نقاط الحفظ"
git init -q
git add -A
git commit -q -m "البداية: هيكل المشروع جاهز"
echo "  ✔ أول نقطة حفظ أُنشئت"

# ---------- الخلاصة ----------
cat <<EOF

════════════════════════════════════════
  ✅ المشروع "$NAME" جاهز
════════════════════════════════════════

المتبقي عليك كمدرب:
  1. عدّل backend/.env  → بيانات قاعدة البيانات
  2. cd backend && php artisan migrate
  3. أنشئ مستودعًا على GitHub واربطه
  4. اختبر الأوامر العربية:  cd $NAME && claude
     ثم اكتب  /  وتأكد أن الأوامر تظهر

ثم يبدأ المتدرب من:
     cd $NAME
     claude
     /فكرة

EOF
