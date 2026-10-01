#!/usr/bin/env bash
# حفظ تلقائي — ينشئ نقطة حفظ بعد كل مهمة تنتهي بتغييرات.
# الهدف: المستخدم غير المبرمج لا يحتاج تعلّم Git — يكفيه /go-back.
# لتعطيله: احذف قسم "Stop" من .claude/settings.json

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# لا تحفظ إن لم يتغير شيء
[ -z "$(git status --porcelain)" ] && exit 0

git add -A >/dev/null 2>&1

# لا تحفظ ملفات الأسرار أبدًا
git reset -q -- '*.env' '*/.env' 2>/dev/null

git commit -q -m "حفظ تلقائي: $(date '+%Y-%m-%d %H:%M')" >/dev/null 2>&1
exit 0
