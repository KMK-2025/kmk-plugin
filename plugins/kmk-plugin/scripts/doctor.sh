#!/usr/bin/env bash
# ==========================================================
#  فحص تشخيصي للبيئة — يُشغَّل قبل أي إنشاء مشروع
#  لا يعدّل شيئًا. يطبع تقريرًا فقط، وClaude يقرؤه ويتصرف.
# ==========================================================

OS="غير معروف"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) OS="Windows" ;;
  Darwin) OS="macOS" ;;
  Linux) OS="Linux" ;;
esac

echo "=== نظام التشغيل ==="
echo "OS=$OS"
[ "$OS" = "Windows" ] && echo "SHELL_OK=$([ -n "$MSYSTEM" ] && echo نعم || echo "لا — يجب التشغيل من Git Bash")"

echo
echo "=== الأدوات ==="
check() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "$1=موجود ($($2 2>&1 | head -1))"
  else
    echo "$1=مفقود"
  fi
}
check node "node -v"
check npm "npm -v"
check git "git --version"
check php "php -v"
check composer "composer -V"
check mysql "mysql --version"
check docker "docker --version"
check gh "gh --version"

echo
echo "=== XAMPP ==="
# أكثر سبب شائع لـ mysql مفقود على Windows: XAMPP مثبّت لكن مساره ليس في PATH
# بحث بنمط عام لا بمسارات محدّدة: التثبيت كثيرًا ما يكون xampp_8.2
# أو على قرص آخر، والقائمة الثابتة كانت تفوّت أكثر الحالات شيوعًا.
#
# ملاحظة: لا يصلح هنا نمط مثل /[c-z]/xampp* — جذر MSYS ليس مجلدًا حقيقيًا
# فلا تتوسّع فيه أحرف الأقراص. لا بد من المرور عليها واحدًا واحدًا.
XAMPP=""
for drive in c d e f g h; do
  for d in "/$drive"/xampp*; do
    if [ -d "$d/mysql/bin" ]; then XAMPP="$d"; break 2; fi
  done
done
if [ -z "$XAMPP" ]; then
  for d in "$HOME"/xampp* /opt/lampp /Applications/XAMPP/xamppfiles; do
    if [ -d "$d/mysql/bin" ]; then XAMPP="$d"; break; fi
  done
fi
if [ -n "$XAMPP" ]; then
  echo "XAMPP_PATH=$XAMPP"
  echo "XAMPP_MYSQL_BIN=$([ -d "$XAMPP/mysql/bin" ] && echo "$XAMPP/mysql/bin" || echo مفقود)"
  echo "MYSQL_IN_PATH=$(command -v mysql >/dev/null 2>&1 && echo نعم || echo "لا — يحتاج إضافة $XAMPP/mysql/bin إلى PATH")"
  # هل الخدمة تعمل فعلًا؟
  if command -v "$XAMPP/mysql/bin/mysqladmin" >/dev/null 2>&1 || [ -x "$XAMPP/mysql/bin/mysqladmin.exe" ]; then
    if "$XAMPP/mysql/bin/mysqladmin" -u root ping >/dev/null 2>&1; then
      echo "MYSQL_RUNNING=نعم"
    else
      echo "MYSQL_RUNNING=لا — شغّلها من XAMPP Control Panel"
    fi
  fi
else
  echo "XAMPP_PATH=غير مثبّت"
fi

echo
echo "=== إضافات PHP المطلوبة لـ Laravel ==="
if command -v php >/dev/null 2>&1; then
  MODS=$(php -m 2>/dev/null | tr 'A-Z' 'a-z')
  for ext in pdo_mysql mbstring openssl tokenizer xml ctype json fileinfo curl zip; do
    echo "$MODS" | grep -qx "$ext" && echo "$ext=موجود" || echo "$ext=مفقود"
  done
  # ما بعد أول نقطتين فقط — cut -d: يقطع المسار عند حرف القرص (D:)
  echo "PHP_INI=$(php --ini 2>/dev/null | grep 'Loaded Configuration' | sed 's/^[^:]*:[[:space:]]*//')"
else
  echo "تعذّر الفحص — php مفقود"
fi

echo
echo "=== حالة قاعدة البيانات ==="
if command -v mysql >/dev/null 2>&1; then
  if mysql -u root -e "SELECT 1" >/dev/null 2>&1; then
    echo "DB_CONNECT=نجح بلا كلمة سر (root)"
  elif mysql -u root -proot -e "SELECT 1" >/dev/null 2>&1; then
    echo "DB_CONNECT=نجح بكلمة سر root"
  else
    echo "DB_CONNECT=فشل — الخدمة متوقفة أو الاعتمادات مختلفة"
  fi
else
  echo "DB_CONNECT=تعذّر — mysql غير متاح في PATH"
fi

echo
echo "=== إصدارات أدنى ==="
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
  if [ "$NODE_MAJOR" -ge 20 ] 2>/dev/null; then
    echo "NODE_MAJOR=$NODE_MAJOR"
  else
    echo "NODE_MAJOR=$NODE_MAJOR — قديم، Vite يحتاج 20.19 أو أحدث"
  fi
fi
if command -v php >/dev/null 2>&1; then
  php -r 'exit(version_compare(PHP_VERSION, "8.2", ">=") ? 0 : 1);' 2>/dev/null \
    && echo "PHP_OK=نعم" || echo "PHP_OK=لا — Laravel 12 يحتاج PHP 8.2 أو أحدث"
fi

echo
echo "=== المنافذ ==="
# منفذ مشغول سبب شائع لفشل غامض: Apache على 8000 أو MySQL ثانٍ على 3306
port_busy() {
  if command -v netstat >/dev/null 2>&1; then
    netstat -an 2>/dev/null | grep -qE "[:.]$1[[:space:]].*LISTEN"
  elif command -v lsof >/dev/null 2>&1; then
    lsof -i ":$1" >/dev/null 2>&1
  else
    return 1
  fi
}
for p in 3306 5173 8000; do
  port_busy "$p" && echo "PORT_$p=مشغول" || echo "PORT_$p=حر"
done

echo
echo "=== انتهى الفحص ==="
