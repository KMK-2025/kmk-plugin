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
XAMPP=""
for d in /c/xampp /d/xampp "$HOME/xampp" /opt/lampp /Applications/XAMPP/xamppfiles; do
  [ -d "$d" ] && XAMPP="$d" && break
done
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
  echo "PHP_INI=$(php --ini 2>/dev/null | grep 'Loaded Configuration' | cut -d: -f2 | xargs)"
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
echo "=== انتهى الفحص ==="
