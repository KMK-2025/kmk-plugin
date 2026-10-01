# سوق إضافات: kmk-marketplace

إضافة واحدة تُدير بناء أنظمة إدارية عربية RTL بأمر واحد، موجّهة لمستخدمين لا يعرفون البرمجة.

## التثبيت

```
/plugin marketplace add KMK-2025/kmk-plugin
/plugin install kmk-plugin@kmk-marketplace
```

## الاستخدام

```
/start متجري
```

يفحص البيئة، يصلح ما ينقص، ينشئ المشروع كاملًا، ويثبّت داخله ثمانية أوامر:

`/idea` · `/apply-design` · `/build-web` · `/test` · `/share-link` · `/deploy` · `/fix` · `/go-back`

## البنية

```
.claude-plugin/marketplace.json     ← فهرس السوق
plugins/kmk-plugin/
├── .claude-plugin/plugin.json      ← تعريف الإضافة
├── skills/start/SKILL.md            ← الأمر الوحيد في الإضافة
├── hooks/hooks.json                ← ربط حاجز الأمان
├── scripts/
│   ├── doctor.sh                   ← فحص البيئة (يكتشف XAMPP والإضافات الناقصة)
│   ├── setup-project.sh            ← إنشاء المشروع — حتمي لا توليدي
│   ├── guard.sh                    ← منع الأوامر المدمّرة
│   └── autosave.sh                 ← حفظ تلقائي بعد كل مهمة
└── templates/                      ← يُنسخ إلى كل مشروع جديد
    ├── CLAUDE.md
    ├── .claude/{skills,agents,launch.json,settings.json}
    ├── docs/
    └── .github/workflows/
```

## المبدأ المعماري

**الإضافة تشحن السكربت، والسكيل يشغّله.**

الإنشاء حتمي (سكربت واحد بترتيب ثابت)، والتشخيص والتعامل مع الأعطال محادثة. هذا يمنع اختلاف الناتج بين متدرب وآخر، ويجعل الفشل يقع في نقطة واحدة معروفة بدل مشروع نصف مبني.

**الأوامر الثمانية تُنسخ داخل المشروع ولا تبقى في الإضافة.** فائدتان: المشروع يعمل على أي جهاز بلا الإضافة، والأوامر تُكتب بأسمائها المجرّدة `/build-web` بدل صيغة مركّبة.

## التحديث

عدّل هنا وادفع إلى GitHub، والمستخدمون يحدّثون بـ `/plugin marketplace update`.

⚠️ المشاريع المُنشأة سابقًا **لا تتحدث تلقائيًا** — نسخها من `templates/` مجمّدة لحظة الإنشاء. لتحديث مشروع قائم، أعد نسخ `templates/.claude/skills/` فوقه.
