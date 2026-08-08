#!/usr/bin/env bash
# حاجز أمان — يمنع الأوامر الخطرة قبل تنفيذها.
# يقرأ حمولة JSON من stdin. الخروج بالكود 2 يمنع الأمر ويُعيد السبب إلى Claude.

input=$(cat)

# استخراج الأمر من حمولة JSON — مع بدائل لأن python3 غير موجود على Windows افتراضيًا
extract() {
  for py in python3 python py; do
    if command -v "$py" >/dev/null 2>&1; then
      printf '%s' "$input" | "$py" -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null && return 0
    fi
  done
  # بديل بلا أي اعتماديات: نفحص الحمولة كاملة
  printf '%s' "$input"
}
cmd=$(extract)
[ -z "$cmd" ] && cmd="$input"

block() { echo "🚫 مرفوض: $1" >&2; exit 2; }

case "$cmd" in
  *migrate:fresh*|*db:wipe*|*"DROP TABLE"*|*"DROP DATABASE"*|*TRUNCATE*)
    block "أمر مدمّر لقاعدة البيانات. أخبر المستخدم واطلب تأكيدًا صريحًا مكتوبًا، وخذ نسخة احتياطية أولًا." ;;
  *"push --force"*|*"push -f"*)
    block "الدفع القسري ممنوع — قد يمحو عملًا سابقًا بلا رجعة." ;;
  *"reset --hard"*)
    block "reset --hard ممنوع. للتراجع استخدم سكيل /تراجع الذي يحفظ نسخة أولًا." ;;
  *.env*)
    block "أي عملية على ملف .env ممنوعة. الأسرار يديرها صاحب المشروع يدويًا." ;;
  *"rm -rf"*)
    block "الحذف الجماعي ممنوع." ;;
esac

# منع الرفع المباشر من فرع main
case "$cmd" in
  *"git push"*)
    branch=$(git branch --show-current 2>/dev/null)
    if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
      block "الرفع المباشر من فرع main ممنوع. أنشئ فرعًا وافتح Pull Request."
    fi ;;
esac

exit 0
