#!/usr/bin/env bash
# ==========================================================
#  رفع نسخة الـ API
#  يُشغَّل آليًا عندما يكشف حارس التوافق (ApiShape) تغييرًا يكسر
#  نسخة قائمة. لا يُسأل صاحب المشروع — القرار للفحص لا للتقدير.
#
#  الاستخدام:  bash .claude/scripts/bump-api-version.sh "سبب الكسر بجملة واحدة"
#
#  ماذا يفعل:
#   1. ينشئ routes/api/v(N+1)/ بنسخة من مسارات النسخة السابقة —
#      فكل النقاط تبقى تشير إلى Controllers النسخة السابقة نفسها.
#   2. يوجّه تطبيق الجوال (إن وُجد) إلى النسخة الجديدة.
#   3. يسجّل النسخة وسببها في جدول النسخ بالعقد.
#  النسخة السابقة لا تُلمس: التطبيقات القديمة تواصل العمل عليها.
# ==========================================================
set -e

REASON="${1:-}"
if [ -z "$REASON" ]; then
  echo 'الاستخدام: bash .claude/scripts/bump-api-version.sh "سبب الكسر بجملة واحدة"'
  exit 1
fi

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

ROUTES="backend/routes/api"
[ -d "$ROUTES" ] || { echo "❌ لم أجد $ROUTES — شغّل السكربت من مجلد المشروع."; exit 1; }

LAST=$(ls -d "$ROUTES"/v[0-9]* 2>/dev/null | sed 's|.*/v||' | sort -n | tail -1)
[ -n "$LAST" ] || { echo "❌ لا توجد أي نسخة في $ROUTES"; exit 1; }
NEXT=$((LAST + 1))

mkdir "$ROUTES/v$NEXT"
cp "$ROUTES/v$LAST"/*.php "$ROUTES/v$NEXT"/ 2>/dev/null || touch "$ROUTES/v$NEXT/.gitkeep"
echo "✔ أُنشئت $ROUTES/v$NEXT (كل النقاط تشير إلى Controllers النسخة v$LAST)"

APP_VERSION="-"
MOBILE_CONFIG="mobile/lib/shared/api/api_config.dart"
if [ -f "$MOBILE_CONFIG" ]; then
  sed -i.bak "s/apiVersion = 'v$LAST'/apiVersion = 'v$NEXT'/" "$MOBILE_CONFIG" && rm -f "$MOBILE_CONFIG.bak"
  APP_VERSION=$(grep -m1 '^version:' mobile/pubspec.yaml | sed 's/version:[[:space:]]*//; s/+.*//' | tr -d '\r')
  echo "✔ تطبيق الجوال (الإصدار القادم بعد $APP_VERSION) يستخدم v$NEXT"
fi

CONTRACT="docs/api-contract.md"
if [ -f "$CONTRACT" ]; then
  ROW="| v$NEXT | $APP_VERSION | $(date +%Y-%m-%d) | $REASON |"
  awk -v row="$ROW" '/<!-- api-versions:end -->/ { print row } { print }' "$CONTRACT" > "$CONTRACT.tmp" && mv "$CONTRACT.tmp" "$CONTRACT"
  sed -i.bak "s/النسخة الأحدث: \*\*v$LAST\*\*/النسخة الأحدث: **v$NEXT**/" "$CONTRACT" && rm -f "$CONTRACT.bak"
  echo "✔ سُجّلت النسخة في $CONTRACT"
fi

cat <<EOF

التالي عليك (الوكيل) — لا تسأل صاحب المشروع عن شيء من هذا:
  1. أعد النقطة في v$LAST كما كانت تمامًا حتى يمر اختبارها القديم.
  2. أنشئ نسخة V$NEXT من Controller/Resource/Request للنقطة المتغيّرة فقط.
  3. عدّل سطر تلك النقطة في $ROUTES/v$NEXT/ ليشير إلى V$NEXT.
  4. اكتب اختبارها في tests/Feature/<Module>/V$NEXT/ مع ApiShape بالنسخة 'v$NEXT'.
  5. الموقع يبقى على v$LAST حتى تُنقل شاشاته — غيّر ثابت النسخة في frontend/src/shared/api عند نقلها.
EOF
