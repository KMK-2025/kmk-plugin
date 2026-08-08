# دستور المشروع

## من تخاطب
صاحب هذا المشروع **ليس مبرمجًا**. هذه ليست تفصيلة جانبية — هي القاعدة التي تحكم كل تصرفاتك:

- تحدّث معه بالعربية، بلغة يومية بسيطة. أسماء الملفات والدوال والمتغيرات بالإنجليزية.
- **ممنوع** استخدام هذه الكلمات معه: API، endpoint، schema، migration، state، props، component، refactor، dependency، backend، frontend.
  استخدم بدلها: "الشاشة"، "المعلومات المحفوظة"، "الخدمة"، "شكل قاعدة البيانات"، "القسم".
- لا تعرض عليه كودًا إلا إذا طلبه صراحة. اعرض **النتيجة** لا الطريقة.
- عند أي قرار تقني، اشرح **الأثر عليه** لا التفاصيل: قل "هذا يخلي الصفحة تفتح أسرع" لا "هذا يقلل re-renders".
- إن أخطأ في المصطلح، لا تصحّحه — افهم قصده وأكمل.

## الوثائق المرجعية
- المتطلبات: `docs/spec.md`
- عقد الخدمات: `docs/api-contract.md`
- نظام التصميم: `docs/design-system.md`

اقرأ الملف المناسب قبل أي مهمة تخصه. **لا تخترع حقلًا أو مسارًا غير موجود في العقد.**

## التقنيات — لا تُضاف مكتبة خارج هذه القائمة قبل أن تشرح السبب وتنتظر موافقة صريحة
**الواجهة:** React 18 · TypeScript · Vite · Bootstrap 5 (RTL) · React Router · Axios · TanStack Query · React Hook Form · Zod · Zustand · i18next · react-hot-toast
**الخدمات:** Laravel 11 · MySQL 8 · Sanctum · spatie/laravel-permission · Pest · Pint

## قواعد الواجهة
- الاتجاه الأساسي RTL. استورد `bootstrap.rtl.min.css` قبل `theme.css`.
- **ممنوع:** `margin-left/right` · `padding-left/right` · `text-align: left/right` · `left`/`right`.
  **استخدم:** `margin-inline-start/end` · `padding-inline-start/end` · `text-align: start/end` · `inset-inline-start/end`.
- **ممنوع** نص عربي داخل مكوّن. كل النصوص في `src/locales/ar.json` عبر `t('key')`، ونفس المفاتيح في `en.json`.
- **ممنوع** ألوان أو مسافات ثابتة. من `src/styles/theme.css` فقط.
- **ممنوع** Inline styles إلا لقيمة تُحسب وقت التشغيل.
- كل مكوّن: ملف واحد، غرض واحد، أقل من 200 سطر. إن تجاوزها فقسّمه.
- كل صفحة بيانات تعرض الحالات الخمس: Loading · Success · Empty · Error · Unauthorized — عبر `src/components/feedback/`.
- كل استدعاء خدمة عبر `src/services/`. **ممنوع** Axios داخل مكوّن.
- كل صفحة تُفحص على عرض 375px قبل اعتبارها منتهية.

## قواعد الخدمات
- شكل موحّد لكل استجابة:
  - نجاح: `{ "success": true, "data": ..., "message": null }`
  - خطأ: `{ "success": false, "data": null, "message": "...", "errors": {...} }`
- Controller نحيف: التحقق في FormRequest، المنطق في Service عند التعقيد، الإخراج في Resource.
- كل نقطة محمية بـ Permission عبر spatie. **التحقق في الخادم إلزامي** — إخفاء الأزرار في الواجهة تحسين تجربة فقط.
- رسائل تحقق عربية. أسماء الجداول جمع، الأعمدة snake_case، الترميز `utf8mb4_unicode_ci`.

## قواعد العمل
- قبل أي مهمة متوسطة أو كبيرة: **اعرض الخطة بلغة بسيطة وانتظر الموافقة.**
- لا تعدّل ملفات خارج نطاق المهمة.
- لا تلمس `.env`. لا ترفع مباشرة إلى `main`.
- بعد أي تعديل واجهة: `npx tsc --noEmit`. بعد أي تعديل خدمات: `./vendor/bin/pint && php artisan test`.
- **لا تقل "تم بنجاح" قبل أن يجرّبه المستخدم بنفسه.** قل: "خلص — اكتب `/جرب` وشوفه بعينك".
- إن وجدت تكرارًا لكود موجود، توقف واقترح إعادة الاستخدام.
- إن لم تعرف السبب، **قل إنك لا تعرف** وابحث. لا تخمّن ولا تعدّل عشوائيًا.

## عند نهاية أي مهمة
اختم دائمًا باقتراح الخطوة التالية بأمر واحد يكتبه، مثل: `/جرب` أو `/انشر تجربة`.

## الأوامر
```bash
cd frontend && npm run dev        # تشغيل الواجهة
cd frontend && npx tsc --noEmit   # فحص الأنواع
cd backend  && php artisan serve  # تشغيل الخدمات
cd backend  && php artisan migrate
cd backend  && php artisan test
```
