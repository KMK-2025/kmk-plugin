#!/usr/bin/env bash
# ==========================================================
#  تجهيز مشروع جديد بأمر واحد
#  الاستخدام:  bash setup-project.sh اسم-المشروع
#  حتمي بالكامل: بنية موديولز + نسخ API + بوابات جودة
# ==========================================================
set -e

NAME="${1:-}"
if [ -z "$NAME" ]; then
  echo "الاستخدام: bash setup-project.sh اسم-المشروع"
  exit 1
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$HERE/../templates"
TARGET="$(pwd)/$NAME"

if [ -d "$TARGET" ]; then
  echo "❌ المجلد $NAME موجود مسبقًا."
  exit 1
fi

echo "▸ إنشاء المشروع: $NAME"
mkdir -p "$TARGET"
cp -r "$TEMPLATE/." "$TARGET/"
cd "$TARGET"
chmod +x .claude/hooks/*.sh 2>/dev/null || true

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
npm install -D vite-plugin-pwa vitest jsdom prettier \
  @testing-library/react @testing-library/jest-dom @testing-library/user-event >/dev/null 2>&1
# ESLint صراحةً — قوالب Vite الحديثة قد لا تشمله
npm install -D eslint @eslint/js typescript-eslint \
  eslint-plugin-react-hooks eslint-plugin-react-refresh globals >/dev/null 2>&1
if [ ! -f eslint.config.js ]; then
  cat > eslint.config.js <<'JS'
import js from '@eslint/js';
import globals from 'globals';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { ignores: ['dist'] },
  {
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
    },
    plugins: {
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],
    },
  }
);
JS
fi

# بنية features + shared (نمط bulletproof-react)
mkdir -p src/{app,features,shared/{api,components/{ui,table,form,feedback},hooks,store,types,utils,constants},locales,styles,assets/fonts,test}
echo '{}' > src/locales/ar.json
echo '{}' > src/locales/en.json

# إعدادات الجودة
cat > .prettierrc <<'JSON'
{
  "singleQuote": true,
  "semi": true,
  "printWidth": 100,
  "trailingComma": "es5"
}
JSON

cat > vitest.config.ts <<'TS'
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test/setup.ts',
  },
});
TS

echo "import '@testing-library/jest-dom';" > src/test/setup.ts

# سكربتات الفحص — بوابة الجودة الواحدة
node -e "
const fs = require('fs');
const p = JSON.parse(fs.readFileSync('package.json', 'utf8'));
p.scripts.check = 'tsc --noEmit && eslint . && prettier --check src && vitest run --passWithNoTests';
p.scripts.format = 'prettier --write src';
p.scripts.test = 'vitest';
fs.writeFileSync('package.json', JSON.stringify(p, null, 2) + '\n');
"
npx prettier --write src >/dev/null 2>&1 || true

# مجلدات فارغة تدخل Git
find src -type d -empty -exec touch {}/.gitkeep \;
cd ..
echo "  ✔ الواجهة جاهزة (features + shared + بوابة npm run check)"

# ---------- الخدمات ----------
echo "▸ تجهيز الخدمات (قد يأخذ ثلاث دقائق)"
composer create-project laravel/laravel backend --quiet >/dev/null 2>&1
cd backend
composer require laravel/sanctum spatie/laravel-permission spatie/laravel-activitylog --quiet >/dev/null 2>&1
composer require --dev laravel/pint pestphp/pest larastan/larastan --quiet --with-all-dependencies >/dev/null 2>&1
php artisan install:api --no-interaction >/dev/null 2>&1
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider" >/dev/null 2>&1
php artisan vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider" --tag="activitylog-migrations" >/dev/null 2>&1

# بنية الموديولز + نسخ الـ API
mkdir -p app/Modules routes/api/v1
touch app/Modules/.gitkeep

cat > routes/api.php <<'PHP'
<?php

use Illuminate\Support\Facades\Route;

// تحميل مسارات كل نسخة تلقائيًا — كل موديول ملف مستقل في routes/api/v<N>/
foreach (glob(__DIR__.'/api/v*', GLOB_ONLYDIR) as $versionDir) {
    $version = basename($versionDir);
    Route::prefix($version)->middleware('throttle:60,1')->group(function () use ($versionDir) {
        foreach (glob($versionDir.'/*.php') as $routeFile) {
            require $routeFile;
        }
    });
}
PHP
touch routes/api/v1/.gitkeep

# تحليل ثابت — Larastan
cat > phpstan.neon <<'NEON'
includes:
    - vendor/larastan/larastan/extension.neon
parameters:
    paths:
        - app
    level: 6
NEON

# أمان: توكن ينتهي بعد أسبوع
sed -i.bak "s/'expiration' => null/'expiration' => 10080/" config/sanctum.php 2>/dev/null && rm -f config/sanctum.php.bak || true

# أمان: CORS مقفول على الواجهة فقط
php artisan config:publish cors >/dev/null 2>&1 || true
if [ -f config/cors.php ]; then
  sed -i.bak "s/'allowed_origins' => \['\*'\]/'allowed_origins' => [env('FRONTEND_URL', 'http:\/\/localhost:5173')]/" config/cors.php 2>/dev/null && rm -f config/cors.php.bak || true
fi

cd ..
echo "  ✔ الخدمات جاهزة (Modules + v1 + activitylog + larastan)"

# ---------- Git ----------
echo "▸ تجهيز نقاط الحفظ"
git init -q
git add -A
git commit -q -m "البداية: هيكل المشروع جاهز (موديولز + نسخ API + بوابات جودة)"
echo "  ✔ أول نقطة حفظ أُنشئت"

# ---------- الخلاصة ----------
cat <<EOF

════════════════════════════════════════
  ✅ المشروع "$NAME" جاهز
════════════════════════════════════════

البنية:
  backend/app/Modules/          ← كل قسم موديول مستقل
  backend/routes/api/v1/        ← مسارات كل موديول تحت نسخة
  frontend/src/features/        ← كل قسم موديول واجهة
  frontend/src/shared/          ← المشترك فقط

المتبقي عليك كمدرب:
  1. عدّل backend/.env  → بيانات قاعدة البيانات + FRONTEND_URL
  2. cd backend && php artisan migrate
  3. أنشئ مستودعًا على GitHub واربطه
  4. اختبر الأوامر العربية:  cd $NAME && claude
     ثم اكتب  /  وتأكد أن الأوامر تظهر

ثم يبدأ المتدرب من:
     cd $NAME
     claude
     /فكرة

EOF
