#!/usr/bin/env bash
# ==========================================================
#  فحص تشخيصي لبيئة الجوال — لا يعدّل شيئًا، يطبع تقريرًا فقط.
# ==========================================================

[ -f "$HOME/.kmk-mobile-env" ] && . "$HOME/.kmk-mobile-env"

OS="غير معروف"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) OS="Windows" ;;
  Darwin) OS="macOS" ;;
  Linux) OS="Linux" ;;
esac

echo "=== نظام التشغيل ==="
echo "OS=$OS"
echo "IOS_BUILD=$([ "$OS" = "macOS" ] && echo "ممكن محليًا" || echo "عبر CI فقط — بناء iOS يحتاج Mac")"

echo
echo "=== الأدوات ==="
check() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "$1=موجود ($($2 2>&1 | head -1))"
  else
    echo "$1=مفقود"
  fi
}
check flutter "flutter --version"
check dart "dart --version"
check java "java -version"
check adb "adb version"
echo "ANDROID_HOME=${ANDROID_HOME:-غير مضبوط}"
echo "ENV_FILE=$([ -f "$HOME/.kmk-mobile-env" ] && echo موجود || echo "مفقود — شغّل setup-mobile.sh")"

if [ "$OS" = "Windows" ]; then
  if reg query "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\AppModelUnlock" //v AllowDevelopmentWithoutDevLicense 2>/dev/null | grep -q "0x1"; then
    echo "DEV_MODE=مفعّل"
  else
    echo "DEV_MODE=غير مفعّل — الإعدادات ← للمطوّرين ← وضع المطوّر"
  fi
fi

echo
echo "=== الأجهزة الموصولة ==="
if command -v adb >/dev/null 2>&1; then
  DEVICES=$(adb devices 2>/dev/null | tail -n +2 | grep -v '^[[:space:]]*$' || true)
  if [ -z "$DEVICES" ]; then
    echo "DEVICES=لا يوجد — صِل الهاتف بالكابل وفعّل تصحيح USB"
  else
    echo "$DEVICES" | while read -r serial state; do
      case "$state" in
        device) echo "DEVICE=$serial جاهز" ;;
        unauthorized) echo "DEVICE=$serial ينتظر الموافقة على شاشة الهاتف («السماح بتصحيح USB»)" ;;
        *) echo "DEVICE=$serial حالته: $state" ;;
      esac
    done
  fi
else
  echo "DEVICES=تعذّر الفحص — adb مفقود"
fi

echo
echo "=== انتهى الفحص ==="
