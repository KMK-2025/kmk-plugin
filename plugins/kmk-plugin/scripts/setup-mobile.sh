#!/usr/bin/env bash
# ==========================================================
#  تجهيز بيئة Flutter كاملة على الجهاز — مرة واحدة لكل جهاز
#  الاستخدام:  bash setup-mobile.sh
#
#  يثبّت ما ينقص فقط: Flutter SDK · Java 17 · أدوات Android · adb
#  ثم يقبل تراخيص Android ويحفظ المسارات. آمن لإعادة التشغيل.
#  التنزيل 3–4GB ويأخذ 15–25 دقيقة: شغّله قبل الجلسة لا خلالها.
# ==========================================================
set -e

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
  Darwin) OS="macos" ;;
  Linux) OS="linux" ;;
  *) echo "❌ نظام تشغيل غير مدعوم: $(uname -s)"; exit 1 ;;
esac

ENV_FILE="$HOME/.kmk-mobile-env"
[ -f "$ENV_FILE" ] && . "$ENV_FILE"

step() { echo; echo "▸ $1"; }
ok()   { echo "  ✔ $1"; }
warn() { echo "  ⚠ $1"; }

to_unix() { if [ "$OS" = "windows" ]; then cygpath -u "$1"; else echo "$1"; fi; }
to_native() { if [ "$OS" = "windows" ]; then cygpath -w "$1"; else echo "$1"; fi; }

command -v git >/dev/null 2>&1 || { echo "❌ Git غير مثبّت — ثبّته أولًا."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "❌ curl غير متاح."; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "❌ unzip غير متاح."; exit 1; }

# ---------- Flutter ----------
step "Flutter SDK"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
if command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(dirname "$(command -v flutter)")"
  ok "موجود مسبقًا"
else
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    echo "  تنزيل Flutter (النسخة المستقرة)…"
    git clone --quiet --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  FLUTTER_BIN="$FLUTTER_HOME/bin"
  export PATH="$FLUTTER_BIN:$PATH"
  ok "ثُبّت في $FLUTTER_HOME"
fi

# ---------- Java ----------
step "Java 17"
find_java_home() {
  for d in "/c/Program Files/Microsoft"/jdk-17* "/c/Program Files/Eclipse Adoptium"/jdk-17* \
           /opt/homebrew/opt/openjdk@17 /usr/local/opt/openjdk@17 /usr/lib/jvm/java-17-openjdk*; do
    [ -x "$d/bin/java" ] || [ -x "$d/bin/java.exe" ] && { echo "$d"; return 0; }
  done
  return 1
}
if ! command -v java >/dev/null 2>&1; then
  case "$OS" in
    windows) winget install --id Microsoft.OpenJDK.17 -e --silent --accept-source-agreements --accept-package-agreements >/dev/null 2>&1 || true ;;
    macos)   command -v brew >/dev/null 2>&1 && brew install openjdk@17 >/dev/null 2>&1 || true ;;
    linux)   command -v apt-get >/dev/null 2>&1 && sudo -n apt-get install -y openjdk-17-jdk >/dev/null 2>&1 || true ;;
  esac
  if JH="$(find_java_home)"; then
    export JAVA_HOME="$JH"
    export PATH="$JAVA_HOME/bin:$PATH"
  fi
fi
if command -v java >/dev/null 2>&1; then
  ok "$(java -version 2>&1 | head -1)"
else
  echo "❌ تعذّر تثبيت Java تلقائيًا. ثبّت JDK 17 يدويًا ثم أعد تشغيل هذا السكربت."
  exit 1
fi

# ---------- Android SDK ----------
step "أدوات Android"
case "$OS" in
  windows) DEFAULT_SDK="$(to_unix "${LOCALAPPDATA:-$HOME/AppData/Local}")/Android/Sdk"; TOOLS_OS="win"; EXT=".bat" ;;
  macos)   DEFAULT_SDK="$HOME/Library/Android/sdk"; TOOLS_OS="mac"; EXT="" ;;
  linux)   DEFAULT_SDK="$HOME/Android/Sdk"; TOOLS_OS="linux"; EXT="" ;;
esac
ANDROID_SDK="$(to_unix "${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$DEFAULT_SDK}}")"
SDKMANAGER="$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager$EXT"

if [ ! -e "$SDKMANAGER" ]; then
  echo "  تنزيل أدوات سطر الأوامر…"
  TMP_ZIP="$(mktemp -d)/cmdline-tools.zip"
  curl -fsSL -o "$TMP_ZIP" "https://dl.google.com/android/repository/commandlinetools-${TOOLS_OS}-11076708_latest.zip"
  mkdir -p "$ANDROID_SDK/cmdline-tools"
  unzip -q -o "$TMP_ZIP" -d "$ANDROID_SDK/cmdline-tools"
  rm -rf "$ANDROID_SDK/cmdline-tools/latest"
  mv "$ANDROID_SDK/cmdline-tools/cmdline-tools" "$ANDROID_SDK/cmdline-tools/latest"
fi
export ANDROID_HOME="$ANDROID_SDK"

yes 2>/dev/null | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true
"$SDKMANAGER" "platform-tools" >/dev/null 2>&1 || warn "تعذّر تثبيت platform-tools — تحقق من الاتصال"
if [ "$OS" = "windows" ]; then
  "$SDKMANAGER" "extras;google;usb_driver" >/dev/null 2>&1 || true
fi
export PATH="$PATH:$ANDROID_SDK/platform-tools:$ANDROID_SDK/cmdline-tools/latest/bin"
ok "Android SDK في $ANDROID_SDK (التراخيص مقبولة)"

# ---------- ضبط Flutter ----------
step "ضبط Flutter"
flutter config --no-analytics >/dev/null 2>&1 || true
flutter config --android-sdk "$(to_native "$ANDROID_SDK")" >/dev/null 2>&1 || true
flutter --version >/dev/null 2>&1
flutter precache --android >/dev/null 2>&1 || warn "تعذّر التحميل المسبق — سيُحمَّل عند أول بناء"
ok "$(flutter --version 2>/dev/null | head -1)"

# ---------- حفظ المسارات ----------
step "حفظ المسارات"
{
  echo "# أنشأه setup-mobile.sh — مسارات Flutter و Android"
  [ -n "${JAVA_HOME:-}" ] && echo "export JAVA_HOME=\"$JAVA_HOME\""
  echo "export ANDROID_HOME=\"$ANDROID_SDK\""
  echo "case \":\$PATH:\" in *\":$FLUTTER_BIN:\"*) ;; *) export PATH=\"$FLUTTER_BIN:\$PATH:$ANDROID_SDK/platform-tools:$ANDROID_SDK/cmdline-tools/latest/bin${JAVA_HOME:+:$JAVA_HOME/bin}\" ;; esac"
} > "$ENV_FILE"

SOURCE_LINE='[ -f "$HOME/.kmk-mobile-env" ] && . "$HOME/.kmk-mobile-env"'
for rc in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc"; do
  if [ "$rc" = "$HOME/.bashrc" ] || [ -f "$rc" ]; then
    grep -qF '.kmk-mobile-env' "$rc" 2>/dev/null || echo "$SOURCE_LINE" >> "$rc"
  fi
done
ok "محفوظة في $ENV_FILE"

# ---------- وضع المطوّر على Windows ----------
DEV_MODE="غير مطلوب"
if [ "$OS" = "windows" ]; then
  if reg query "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\AppModelUnlock" //v AllowDevelopmentWithoutDevLicense 2>/dev/null | grep -q "0x1"; then
    DEV_MODE="مفعّل"
  else
    DEV_MODE="غير مفعّل"
  fi
fi

cat <<EOF

════════════════════════════════════════
  ✅ بيئة الجوال جاهزة
════════════════════════════════════════
FLUTTER=$(flutter --version 2>/dev/null | head -1)
ANDROID_HOME=$ANDROID_SDK
DEV_MODE=$DEV_MODE
EOF

if [ "$DEV_MODE" = "غير مفعّل" ]; then
  cat <<'EOF'

⚠ خطوة يدوية واحدة على Windows (مرة واحدة):
  الإعدادات ← النظام ← للمطوّرين ← فعّل «وضع المطوّر»
  (أو شغّل:  start ms-settings:developers)
EOF
fi

cat <<'EOF'

على هاتف Android (مرة واحدة لكل هاتف):
  1. الإعدادات ← حول الهاتف ← اضغط «رقم الإصدار» 7 مرات
  2. الإعدادات ← خيارات المطوّر ← فعّل «تصحيح USB»
  3. صِل الهاتف بالكابل ووافق على «السماح بتصحيح USB»

أغلق تطبيق Claude وافتحه من جديد ليرى المسارات الجديدة.
EOF
