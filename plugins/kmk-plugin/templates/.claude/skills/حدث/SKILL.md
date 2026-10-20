---
name: حدث
description: يحدّث أوامر المشروع ووكلاءه من نسخة الإضافة المثبّتة، ويعرض الفرق قبل الكتابة. استخدمه عند تحديث الإضافة أو عند ظهور أمر جديد.
disable-model-invocation: true
---

# تحديث أوامر المشروع

## النسخة الحالية
```!
echo "نسخة الأساس في هذا المشروع:"
cat .kmk-shell-version 2>/dev/null || echo "غير معروفة (مشروع أُنشئ بنسخة قديمة)"
echo
echo "الأوامر الموجودة:"
ls -1 .claude/skills 2>/dev/null | sed 's|^|  /|'
```

---

## لماذا هذا الأمر موجود

أوامر المشروع **نسخة مجمّدة** لحظة إنشائه. تحديث الإضافة بـ
`/plugin marketplace update` لا يصل إلى المشاريع القائمة. هذا الأمر يجسر الفرق.

---

## ما يُحدَّث وما لا يُحدَّث

| يُحدَّث | لا يُمسّ أبدًا |
|---|---|
| `.claude/skills/` — الأوامر | `src/features/**` — أقسامك |
| `.claude/agents/` — الوكلاء | `app/Modules/**` — أقسامك |
| `.claude/hooks/` — الحواجز | `src/styles/theme.css` — تصميمك |
| `CLAUDE.md` — الدستور (باقتراح) | `src/app/RootLayout.tsx` — تصميمك |
| | `docs/spec.md` · `docs/api-contract.md` · `docs/design-system.md` |
| | `.env` وقاعدة البيانات |

**الأساس التقني (`shared/api`, `app/Support`, …) لا يُحدَّث تلقائيًا.** قد يكون صاحب
المشروع عدّله بموافقة، والكتابة فوقه تكسر مشروعًا يعمل. إن كانت في الإضافة إصلاحات
مهمة له، اعرضها عليه **واحدًا واحدًا** واطلب موافقة على كل منها.

---

## الخطوات

### 1. تأكد أن الإضافة مثبّتة ومحدَّثة
إن لم يكن `${CLAUDE_PLUGIN_ROOT}` متاحًا، فالإضافة غير مثبّتة في هذه الجلسة. أخبره:
> "محتاج الإضافة تكون مثبّتة عشان أحدّث. اكتب `/plugin marketplace update` أول، وبعدين ارجع لهنا."

### 2. احفظ نقطة رجوع
```bash
git add -A && git commit -q -m "قبل تحديث الأوامر" || true
git tag -f "before-update-$(date +%Y%m%d-%H%M)"
```

### 3. اعرض الفرق قبل الكتابة
قارن `${CLAUDE_PLUGIN_ROOT}/templates/.claude/` بما في المشروع، ثم اعرض عليه
**بلغة بسيطة** — لا مخرجات `diff`:

> "في تحديثات جاهزة:
> · أمرين جداد: `/وين-وصلنا` و `/بيانات`
> · تحسين على `/تراجع` — صار يحذف الملفات الزايدة صح
> · الحاجز صار يفرق بين قراءة ملف الأسرار وكتابته
>
> ما راح ألمس: أقسامك ولا تصميمك ولا بياناتك.
>
> أكمل؟"

### 4. انسخ بعد موافقته
```bash
cp -R "${CLAUDE_PLUGIN_ROOT}/templates/.claude/skills/."  .claude/skills/
cp -R "${CLAUDE_PLUGIN_ROOT}/templates/.claude/agents/."  .claude/agents/
cp -R "${CLAUDE_PLUGIN_ROOT}/templates/.claude/hooks/."   .claude/hooks/
chmod +x .claude/hooks/*.sh
cp "${CLAUDE_PLUGIN_ROOT}/starter/VERSION" .kmk-shell-version
```

⚠️ **إن كانت أسماء أوامره لاتينية** (استُخدم `switch-to-latin.sh`)، فالنسخ يعيدها
عربية. لاحظ ذلك وأعد تشغيل السكربت بعد النسخ.

### 5. `CLAUDE.md` باقتراح لا بكتابة
قد يكون أضاف إليه قواعد خاصة بمشروعه. اعرض عليه الفروق المهمة واسأله عن كل واحدة،
ولا تكتب فوقه كاملًا.

### 6. تحقّق
```bash
cd frontend && npm run check
cd backend && ./vendor/bin/phpstan analyse && php artisan test
```

ثم:
> "تم التحديث ✅ أوامرك الجديدة: <القائمة>
> لو صار شي غريب، اكتب `/تراجع` واختر «قبل تحديث الأوامر»."
