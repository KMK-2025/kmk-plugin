#!/usr/bin/env bash
# ==========================================================
#  تجهيز مشروع جديد بأمر واحد
#
#  الاستخدام:
#    bash setup-project.sh اسم-المشروع [مستخدم-القاعدة] [كلمة-السر]
#
#  حتمي بالكامل: ينتهي بمشروع يعمل — تسجيل دخول حقيقي، غلاف ردود
#  موحّد، صلاحيات مزروعة، واختبارات تمر. الشكل ليس من مسؤوليته:
#  لا ألوان ولا قائمة ولا تخطيط — تلك من عمل /صمم.
#
#  آمن لإعادة التشغيل: كل مرحلة تُسجَّل في .setup-state، وإعادة
#  التشغيل تُكمل من حيث توقّفت.
# ==========================================================
set -euo pipefail

NAME="${1:-}"
DB_USER="${2:-root}"
DB_PASS="${3:-}"

if [ -z "$NAME" ]; then
  echo "الاستخدام: bash setup-project.sh اسم-المشروع [مستخدم-القاعدة] [كلمة-السر]"
  exit 1
fi

case "$NAME" in
  *[!a-zA-Z0-9_-]*)
    echo "❌ اسم المشروع يقبل الحروف الإنجليزية والأرقام و - و _ فقط."
    echo "   المسارات فيها مسافات أو حروف عربية تكسر الأدوات على Windows."
    exit 1 ;;
esac

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$HERE/../templates"
STARTER="$HERE/../starter"
TARGET="$(pwd)/$NAME"
STATE="$TARGET/.setup-state"
LOG="$TARGET/.setup.log"

# اسم قاعدة البيانات: الشُرَط ممنوعة في SQL بلا اقتباس، فنحوّلها.
DB_NAME="$(printf '%s' "$NAME" | tr '-' '_')"
DB_TEST="${DB_NAME}_test"

# ---------- أدوات ----------
step_done() { [ -f "$STATE" ] && grep -qx "$1" "$STATE"; }
# لا يكرّر سطرًا: لاحظت تكرارًا في .setup-state عند تشغيل نسختين معًا.
mark_done()  { step_done "$1" || echo "$1" >> "$STATE"; }

run() {
  printf '\n$ %s\n' "$*" >> "$LOG"
  if ! "$@" >> "$LOG" 2>&1; then
    echo
    echo "❌ فشل الأمر: $*"
    echo "──────── آخر ٣٠ سطرًا من السجل ────────"
    tail -30 "$LOG"
    echo "───────────────────────────────────────"
    echo "السجل الكامل: $LOG"
    echo "أصلح السبب ثم أعد تشغيل الأمر نفسه — سيُكمل من حيث توقّف."
    exit 1
  fi
}

set_env() {   # set_env FILE KEY VALUE
  local file="$1" key="$2" value="$3"
  if grep -q "^${key}=" "$file" 2>/dev/null; then
    sed -i.bak "s|^${key}=.*|${key}=${value}|" "$file" && rm -f "$file.bak"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

mysql_do() {  # mysql_do SQL
  if [ -n "$DB_PASS" ]; then
    mysql -u "$DB_USER" -p"$DB_PASS" -e "$1"
  else
    mysql -u "$DB_USER" -e "$1"
  fi
}

# ---------- المجلد ----------
if [ -d "$TARGET" ]; then
  if [ -f "$STATE" ]; then
    echo "▸ استئناف مشروع غير مكتمل: $NAME"
  else
    echo "❌ المجلد $NAME موجود مسبقًا وليس مشروعًا نصف مبني."
    exit 1
  fi
else
  echo "▸ إنشاء المشروع: $NAME"
  mkdir -p "$TARGET"
fi

cd "$TARGET"
: > "$LOG"

# ---------- الفحوصات المسبقة ----------
echo "▸ فحص الأدوات"
MISSING=""
for tool in node npm git php composer mysql; do
  command -v "$tool" >/dev/null 2>&1 || MISSING="$MISSING $tool"
done
if [ -n "$MISSING" ]; then
  echo "⚠️  أدوات ناقصة:$MISSING"
  echo "   ثبّتها ثم أعد تشغيل السكربت."
  exit 1
fi

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_MAJOR" -lt 20 ]; then
  echo "❌ Node $(node -v) قديم. Vite يحتاج 20.19 أو أحدث."
  exit 1
fi
echo "  ✔ node $(node -v) · php $(php -r 'echo PHP_VERSION;')"

# ---------- القوالب ----------
# آمن للتكرار، ويحدّث القوالب عند إعادة التشغيل.
cp -R "$TEMPLATE/." "$TARGET/"
chmod +x .claude/hooks/*.sh 2>/dev/null || true
cp "$STARTER/VERSION" .kmk-shell-version

# ---------- الواجهة ----------
if ! step_done frontend; then
  echo "▸ تجهيز الواجهة (دقيقة أو دقيقتان)"
  mkdir -p frontend
  cp -R "$STARTER/frontend/." frontend/
  # npm ci من ملف قفل مثبّت: نفس الإصدارات لكل مستخدم، بلا مفاجآت.
  ( cd frontend && run npm ci --no-audit --no-fund )
  mark_done frontend
  echo "  ✔ الواجهة جاهزة"
fi

# ---------- الخدمات ----------
if ! step_done backend; then
  echo "▸ تجهيز الخدمات (ثلاث دقائق تقريبًا)"

  if [ ! -f backend/artisan ]; then
    run composer create-project "laravel/laravel:^12.0" backend --quiet --no-interaction
  fi

  cd backend
  run composer require --no-interaction \
    "laravel/sanctum:^4.0" "spatie/laravel-permission:^6.9" "spatie/laravel-activitylog:^4.8"
  run composer require --dev --no-interaction --with-all-dependencies \
    "laravel/pint:^1.18" "pestphp/pest:^3.5" "pestphp/pest-plugin-laravel:^3.0" "larastan/larastan:^3.0"

  run php artisan install:api --no-interaction
  run php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider" --force
  run php artisan vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider" --tag="activitylog-migrations" --force
  # لا نشغّل pest --init: لا يحترم --no-interaction ويتوقّف عند سؤال عن GitHub
  # فيتجمّد السكربت. ولا حاجة إليه أصلًا — الأساس يشحن tests/Pest.php و phpunit.xml.

  # الأساس التقني يُنسخ أخيرًا ليتغلّب على كل ما وَلَّدته الأدوات.
  cp -R "$STARTER/backend/." .

  # اسم قاعدة الاختبار خاص بالمشروع (القالب يحمل قيمة بديلة).
  sed -i.bak "s|value=\"kmk_testing\"|value=\"$DB_TEST\"|" phpunit.xml && rm -f phpunit.xml.bak

  cd ..
  mark_done backend
  echo "  ✔ الخدمات جاهزة (Auth + غلاف موحّد + صلاحيات)"
fi

# ---------- قاعدة البيانات والإعدادات ----------
if ! step_done env; then
  echo "▸ قاعدة البيانات وملفات الإعداد"

  if ! mysql_do "SELECT 1" >/dev/null 2>&1; then
    echo "❌ تعذّر الاتصال بـ MySQL بالمستخدم '$DB_USER'."
    echo "   إن كانت الخدمة متوقفة: شغّل MySQL من XAMPP ثم أعد المحاولة."
    echo "   وإن كانت لها كلمة سر:"
    echo "     bash setup-project.sh $NAME $DB_USER <كلمة-السر>"
    exit 1
  fi

  mysql_do "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  mysql_do "CREATE DATABASE IF NOT EXISTS \`$DB_TEST\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

  set_env backend/.env APP_NAME "$NAME"
  set_env backend/.env APP_URL http://localhost:8000
  set_env backend/.env APP_LOCALE ar
  set_env backend/.env APP_FALLBACK_LOCALE en
  set_env backend/.env DB_CONNECTION mysql
  set_env backend/.env DB_HOST 127.0.0.1
  set_env backend/.env DB_PORT 3306
  set_env backend/.env DB_DATABASE "$DB_NAME"
  set_env backend/.env DB_USERNAME "$DB_USER"
  set_env backend/.env DB_PASSWORD "$DB_PASS"
  set_env backend/.env FRONTEND_URL http://localhost:5173
  set_env backend/.env SANCTUM_TOKEN_EXPIRATION 10080

  cp frontend/.env.example frontend/.env
  printf 'VITE_API_URL=https://api.example.com/api\n' > frontend/.env.production

  ( cd backend && run php artisan key:generate --force )

  mark_done env
  echo "  ✔ القاعدتان $DB_NAME و $DB_TEST جاهزتان"
fi

# ---------- الجداول والبيانات الأولية ----------
if ! step_done migrate; then
  echo "▸ إنشاء الجداول وزرع الأدوار والمستخدمين"
  ( cd backend && run php artisan migrate --force --seed )
  mark_done migrate
  echo "  ✔ admin@test.com / password جاهز"
fi

# ---------- بوابات الجودة ----------
if ! step_done gates; then
  echo "▸ التحقق من أن المشروع أخضر قبل تسليمه"
  ( cd backend \
    && run ./vendor/bin/pint \
    && run ./vendor/bin/phpstan analyse --no-progress --memory-limit=1G \
    && run php artisan test )
  ( cd frontend && run npm run check )
  mark_done gates
  echo "  ✔ كل الفحوصات تمر"
fi

# ---------- Git ----------
if ! step_done git; then
  echo "▸ تجهيز نقاط الحفظ"
  if [ ! -d .git ]; then
    # فرع العمل اسمه work: main يبقى فرع الإصدار على GitHub وحده،
    # فلا يقف المستخدم عليه أبدًا ولا يصطدم بحاجز منع الرفع منه.
    git init -q -b work 2>/dev/null || { git init -q; git checkout -q -b work; }
  fi
  git add -A
  git commit -q -m "البداية: الأساس التقني جاهز (مصادقة + غلاف موحّد + صلاحيات)"
  git tag -f "shell-$(cat .kmk-shell-version)" -m "الأساس التقني كما سلّمته الإضافة" >/dev/null 2>&1 || true
  mark_done git
  echo "  ✔ أول نقطة حفظ أُنشئت على فرع work"
fi

rm -f "$STATE"

cat <<EOF

════════════════════════════════════════
  ✅ المشروع "$NAME" جاهز ويعمل
════════════════════════════════════════

الدخول:  admin@test.com / password

التشغيل:
  cd $NAME/backend  && php artisan serve
  cd $NAME/frontend && npm run dev     →  http://localhost:5173

ما الجاهز فعلًا (لا مجلدات فارغة):
  · تسجيل دخول يعمل، وصلاحيات، وأدوار مزروعة
  · غلاف ردود موحّد لكل الحالات (401/403/422/500)
  · بنية مسارات جاهزة لتسجيل أقسام جديدة
  · اختبارات تمر، وبوابات جودة خضراء

ما ليس جاهزًا عن قصد:
  الشكل. لا ألوان ولا قائمة ولا تخطيط — كلها من عمل /صمم
  بعد أن يضع صاحب النظام صوره المرجعية في docs/design/

الخطوة التالية للمتدرب:
  cd $NAME && claude
  /فكرة   ثم   /صمم   ثم   /ابن

EOF
