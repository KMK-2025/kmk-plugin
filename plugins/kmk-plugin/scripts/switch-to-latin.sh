#!/usr/bin/env bash
# ==========================================================
#  تبديل أسماء الأوامر بين العربية واللاتينية
#  شغّله فقط إذا كانت طرفية المتدرب لا تتعامل جيدًا مع العربية.
#
#  الاستخدام:  bash switch-to-latin.sh /مسار/المشروع
#  للرجوع:     bash switch-to-latin.sh /مسار/المشروع --رجوع
#
#  يعدّل اسم المجلد **و** حقل name داخل SKILL.md — الاسم المعروض
#  يأتي من الحقل، فتغيير المجلد وحده يترك الأمر باسمه القديم.
# ==========================================================
set -euo pipefail

TARGET="${1:-.}"
MODE="${2:-}"
S="$TARGET/.claude/skills"

[ -d "$S" ] || { echo "❌ لم أجد $S"; exit 1; }

# مصفوفتان متوازيتان لا مصفوفة ترابطية: declare -A تحتاج bash 4،
# و macOS ما زال يشحن bash 3.2 افتراضيًا.
AR=(فكرة صمم ابن جرب شارك انشر اصلح تراجع وين-وصلنا بيانات حدث)
EN=(idea design build test share deploy fix undo status data update)

rename_skill() {   # rename_skill من إلى
  local from="$1" to="$2"
  [ -d "$S/$from" ] || return 0
  mv "$S/$from" "$S/$to"
  # الحقل name داخل الملف هو ما يظهر للمستخدم — بدّله أيضًا.
  sed -i.bak "s/^name: $from$/name: $to/" "$S/$to/SKILL.md" && rm -f "$S/$to/SKILL.md.bak"
  echo "  → /$to"
}

i=0
if [ "$MODE" = "--رجوع" ] || [ "$MODE" = "--back" ]; then
  while [ "$i" -lt "${#AR[@]}" ]; do
    rename_skill "${EN[$i]}" "${AR[$i]}"
    i=$((i + 1))
  done
  echo "✅ رجعت الأوامر للعربية."
else
  while [ "$i" -lt "${#AR[@]}" ]; do
    rename_skill "${AR[$i]}" "${EN[$i]}"
    i=$((i + 1))
  done
  echo "✅ صارت الأوامر لاتينية."
  echo "   لا تنسَ: البطاقة فيها نسخة بديلة جاهزة بهذه الأسماء."
fi

echo
echo "الأوامر الحالية:"
ls -1 "$S" | sed 's|^|  /|'
echo
echo "تحقّق من التطابق بين اسم المجلد وحقل name:"
for d in "$S"/*/; do
  name=$(basename "$d")
  field=$(grep -m1 '^name:' "$d/SKILL.md" 2>/dev/null | sed 's/^name:[[:space:]]*//')
  if [ "$name" = "$field" ]; then
    echo "  ✔ $name"
  else
    echo "  ✗ المجلد $name لكن الحقل $field"
  fi
done
