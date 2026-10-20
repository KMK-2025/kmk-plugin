#!/usr/bin/env bash
# ==========================================================
#  حاجز أمان — يمنع الأوامر الخطرة قبل تنفيذها.
#  يقرأ حمولة JSON من stdin. الخروج بالكود 2 يمنع الأمر
#  ويُعيد السبب إلى Claude.
#
#  المبدأ في الأسرار: يُمنع *طباعة* .env أو إدخاله في Git،
#  ولا يُمنع إنشاؤه — وإلا تعذّر تجهيز المشروع من أصله.
# ==========================================================
set -u

payload=$(cat)

# ---------- استخراج الأمر وحده — لا نفحص الحمولة كاملة أبدًا ----------
cmd=""
for py in python3 python py; do
  command -v "$py" >/dev/null 2>&1 || continue
  cmd=$(printf '%s' "$payload" | "$py" -c 'import sys, json
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("command", ""), end="")
except Exception:
    pass' 2>/dev/null) || cmd=""
  [ -n "$cmd" ] && break
done

# بديل بلا اعتماديات — وهو المسار المعتاد على Windows، لأن python3/python
# غالبًا مجرد بدائل من Microsoft Store لا تُخرج شيئًا.
# ملاحظة: [^"\\] داخل قوسين يكسر grep في MSYS — الصيغة أدناه مختبَرة عليه.
if [ -z "$cmd" ]; then
  seg=$(printf '%s' "$payload" | tr -d '\n' \
    | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"]|\\")*"' | head -1)
  cmd=${seg#*:}; cmd=${cmd# }; cmd=${cmd#\"}; cmd=${cmd%\"}
fi

# لا أمر ⇒ لا حكم. المنع هنا يعطّل الأدوات بلا سبب.
[ -n "$cmd" ] || exit 0

block() { printf '🚫 مرفوض: %s\n' "$1" >&2; exit 2; }

# ---------- أوامر مدمّرة ----------
case "$cmd" in
  *migrate:fresh*|*db:wipe*|*"DROP TABLE"*|*"DROP DATABASE"*|*TRUNCATE*)
    block "أمر مدمّر لقاعدة البيانات. أخبر المستخدم واطلب تأكيدًا صريحًا مكتوبًا، وخذ نسخة احتياطية أولًا." ;;
  *"push --force"*|*"push -f"*)
    block "الدفع القسري ممنوع — قد يمحو عملًا سابقًا بلا رجعة." ;;
  *"reset --hard"*)
    block "reset --hard ممنوع. للتراجع استخدم سكيل /تراجع الذي يحفظ نسخة أولًا." ;;
esac

# ---------- الحذف الجماعي ----------
# git rm -r --force مسموح — يستخدمه /تراجع لمطابقة نقطة حفظ سابقة.
case "$cmd" in
  git\ rm\ *) : ;;
  *"rm -rf"*|*"rm -fr"*|*"rm -r -f"*|*"rm -f -r"*)
    block "الحذف الجماعي ممنوع." ;;
esac

# ---------- الأسرار ----------
case "$cmd" in
  *.env.example*|*.env.template*) : ;;
  *cat*.env*|*less*.env*|*more*.env*|*head*.env*|*tail*.env*|*strings*.env*|*type*.env*)
    block "طباعة محتوى .env ممنوعة — الأسرار لا تدخل المحادثة." ;;
  *"git add"*.env*|*"git commit"*.env*)
    block "ممنوع إدخال .env في Git." ;;
esac

# ---------- منع الرفع من فرع الإصدار ----------
case "$cmd" in
  *"git push"*)
    branch=$(git branch --show-current 2>/dev/null)
    if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
      block "الرفع من فرع الإصدار ممنوع. العمل يكون على فرع work، والنشر عبر /انشر."
    fi ;;
esac

exit 0
