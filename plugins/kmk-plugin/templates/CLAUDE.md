# دستور المشروع

## من تخاطب
صاحب هذا المشروع **ليس مبرمجًا**. هذه ليست تفصيلة جانبية — هي القاعدة التي تحكم كل تصرفاتك:

- تحدّث معه بالعربية، بلغة يومية بسيطة. أسماء الملفات والدوال والمتغيرات بالإنجليزية.
- **ممنوع** استخدام هذه الكلمات معه: API، endpoint، schema، migration، state، props، component، refactor، dependency، backend، frontend، module.
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
**جودة الواجهة:** ESLint · Prettier · Vitest · Testing Library
**الخدمات:** Laravel 11 · MySQL 8 · Sanctum · spatie/laravel-permission · spatie/laravel-activitylog
**جودة الخدمات:** Pest · Pint · Larastan

---

## البنية المعمارية — موديولز إلزامية

النظام مقسوم إلى **موديولز**: كل قسم وظيفي (فواتير، موظفون، عملاء…) وحدة مستقلة كاملة في الخدمات والواجهة معًا، بنفس الاسم الإنجليزي في الجهتين.

### الخدمات — `backend/app/Modules/<Module>/`
```
app/Modules/Invoices/
├── Http/
│   ├── Controllers/V1/InvoiceController.php
│   ├── Requests/V1/{StoreInvoiceRequest,UpdateInvoiceRequest}.php
│   └── Resources/V1/InvoiceResource.php
├── Models/Invoice.php
├── Services/InvoiceService.php
└── Policies/                     ← عند الحاجة
routes/api/v1/invoices.php        ← مسارات الموديول (تُحمَّل تلقائيًا)
database/migrations/              ← مركزية، مرتّبة زمنيًا لكل النظام
database/seeders/InvoiceSeeder.php
tests/Feature/Invoices/V1/
```

### الواجهة — `frontend/src/features/<feature>/`
```
src/
├── app/                          ← نقطة الدخول والراوتر والمزوّدات
├── features/invoices/
│   ├── pages/                    ← القائمة، النموذج، التفاصيل
│   ├── components/               ← مكونات خاصة بهذا الموديول فقط
│   ├── hooks/
│   ├── services/invoices.service.ts
│   ├── types/
│   └── index.ts                  ← الصادرات العامة الوحيدة
├── shared/
│   ├── api/                      ← عميل Axios ورقم النسخة — المكان الوحيد
│   ├── components/{ui,table,form,feedback}
│   ├── hooks/ · store/ · types/ · utils/ · constants/
├── locales/ · styles/ · assets/
```

### قواعد الحدود — تُفحص في كل مراجعة
- **ممنوع** أن يستورد موديول من داخل موديول آخر. التواصل فقط عبر `features/<x>/index.ts`.
- ما يحتاجه موديولان أو أكثر مكانه `shared/` (واجهة) أو Service مشترك يُستدعى عبر واجهته العامة (خدمات).
- **ممنوع** كود وظيفي خارج الموديولز: لا Controller في `app/Http/Controllers` ولا صفحة خارج `src/features`. الاستثناء الوحيد: المصادقة في `app/Modules/Auth`.
- حذف موديول = حذف مجلديه + ملف مساراته. إن انكسر شيء آخر فهذا خرق حدود يجب إصلاحه.

---

## نسخ الـ API — إلزامية من اليوم الأول

- كل مسار تحت `/api/v1/...`. ملفات المسارات في `routes/api/v1/` و Controllers/Requests/Resources داخل namespace `V1`.
- الواجهة تقرأ رقم النسخة من ثابت واحد في `shared/api/client.ts` — **ممنوع** كتابة `/v1/` يدويًا في أي service.
- **نسخة جديدة فقط عند كسر التوافق:** حذف أو إعادة تسمية حقل في الرد، تغيير شكل الرد، تغيير معنى سلوك قائم.
- **الإضافات لا تكسر:** حقل جديد في الرد، نقطة جديدة، معامل اختياري جديد — كلها تدخل في النسخة الحالية.
- عند إنشاء `V2` لنقطة: تُنسخ النقطة المتغيرة فقط إلى namespace `V2`، ويشير ملف `routes/api/v2/` للنقاط غير المتغيرة إلى Controllers `V1` نفسها.
- **ممنوع حذف أو تعديل سلوك نسخة قديمة** ما دامت أي شاشة تستهلكها. تُحذف فقط بعد انتقال الواجهة بالكامل وبموافقة صاحب المشروع.
- كل نسخة موثّقة في `docs/api-contract.md` تحت عنوانها.

---

## التسمية — قياسية بلا اجتهادات

| العنصر | القاعدة | مثال |
|---|---|---|
| موديول خدمات | StudlyCase جمع | `Invoices`, `WorkOrders` |
| موديول واجهة | kebab-case جمع | `invoices`, `work-orders` |
| Class / Component / Type | StudlyCase / PascalCase | `InvoiceService`, `InvoiceTable.tsx` |
| دوال ومتغيرات | camelCase | `totalAmount`, `fetchInvoices` |
| Hook | `use` + camelCase | `useInvoices.ts` |
| Service واجهة | `<feature>.service.ts` | `invoices.service.ts` |
| ثوابت | UPPER_SNAKE_CASE | `MAX_UPLOAD_MB` |
| Boolean | تبدأ بـ `is/has/can` | `isPaid`, `canEdit` |
| معالجات الأحداث | `handle` + الفعل | `handleSubmit` |
| جداول | snake_case جمع | `work_orders` |
| أعمدة | snake_case | `total_amount` |
| مسارات API | kebab-case جمع | `/api/v1/work-orders` |
| صلاحيات | `<entity>.<action>` | `invoices.create` |
| مفاتيح الترجمة | نقاط حسب الموديول | `invoices.form.saveButton` |

ممنوع الاختصارات الغامضة (`usr`, `inv`, `tmp`) — الاسم الكامل دائمًا.

---

## الأمان — إلزامي في كل موديول، يُفحص قبل كل نشر

1. **كل نقطة API** محمية بـ Sanctum + `permission:` عبر spatie. التحقق في الخادم إلزامي — إخفاء الأزرار في الواجهة تحسين تجربة فقط.
2. **Rate limiting:** الدخول `throttle:5,1` والـ API العام `throttle:60,1`. لا نقطة بلا حد.
3. **التوكن ينتهي:** صلاحية Sanctum أسبوع واحد (`expiration = 10080`)، لا توكنات أبدية.
4. **كلمات السر:** عبر `Password::min(8)->mixedCase()->numbers()` برسالة عربية.
5. **سجل العمليات:** كل Model يستخدم `LogsActivity` من spatie/activitylog — من فعل ماذا ومتى، دائمًا.
6. **CORS مقفول:** `allowed_origins` يقرأ `FRONTEND_URL` من env فقط. ممنوع `*` نهائيًا.
7. **الملفات المرفوعة:** تحقق من النوع (`mimes`) والحجم (`max`) في FormRequest، والتخزين باسم مولّد (`hashName`) — ممنوع الوثوق باسم الملف القادم من المستخدم.
8. **لا تسريب:** الحقول الحساسة في `$hidden`، ممنوع ظهور password أو token في أي Resource، و `APP_DEBUG=false` في الإنتاج مع ردّ الخطأ بالشكل الموحّد بلا تفاصيل داخلية.
9. **قاعدة البيانات:** Eloquent/Query Builder فقط مع مدخلات المستخدم. ممنوع دمج نصوص في SQL خام.
10. **الأسرار** في `.env` فقط — لا تُقرأ ولا تُعدَّل ولا تُطبع في السجلات.

---

## قواعد الواجهة
- الاتجاه الأساسي RTL. استورد `bootstrap.rtl.min.css` قبل `theme.css`.
- **ممنوع:** `margin-left/right` · `padding-left/right` · `text-align: left/right` · `left`/`right`.
  **استخدم:** `margin-inline-start/end` · `padding-inline-start/end` · `text-align: start/end` · `inset-inline-start/end`.
- **ممنوع** نص عربي داخل مكوّن. كل النصوص في `src/locales/ar.json` عبر `t('key')`، ونفس المفاتيح في `en.json`.
- **ممنوع** ألوان أو مسافات ثابتة. من `src/styles/theme.css` فقط.
- **ممنوع** Inline styles إلا لقيمة تُحسب وقت التشغيل.
- كل مكوّن: ملف واحد، غرض واحد، أقل من 200 سطر. إن تجاوزها فقسّمه.
- كل صفحة بيانات تعرض الحالات الخمس: Loading · Success · Empty · Error · Unauthorized — عبر `shared/components/feedback/`.
- كل استدعاء خدمة عبر `features/<feature>/services/` مستخدمًا عميل `shared/api`. **ممنوع** Axios داخل مكوّن.
- النماذج: React Hook Form + Zod، رسائل عربية، ومنع الضغط المتكرر على الحفظ.
- إمكانية الوصول: label لكل حقل، تنقّل بلوحة المفاتيح، تباين كافٍ.
- Lazy loading لكل صفحة. كل صفحة تُفحص على عرض 375px قبل اعتبارها منتهية.

## قواعد الخدمات
- شكل موحّد لكل استجابة:
  - نجاح: `{ "success": true, "data": ..., "message": null }`
  - خطأ: `{ "success": false, "data": null, "message": "...", "errors": {...} }`
- Controller نحيف: التحقق في FormRequest، المنطق في Service، الإخراج في Resource. Controller أطول من 100 سطر = منطق في المكان الخطأ.
- رسائل تحقق عربية. الترميز `utf8mb4_unicode_ci`، وفهرس على كل عمود يُستخدم في البحث أو الفرز.
- ممنوع استعلام N+1 — استخدم `with()` دائمًا للعلاقات المعروضة.

---

## بوابات الجودة — لا يُسلَّم عمل قبل مرورها كلها

**الخدمات:**
```bash
cd backend && ./vendor/bin/pint && ./vendor/bin/phpstan analyse && php artisan test
```
**الواجهة:**
```bash
cd frontend && npm run check    # tsc + eslint + prettier + vitest
```

- اختبار Pest لكل نقطة API: نجاح · فشل تحقق · رفض بلا صلاحية. النقطة بلا اختبار = غير موجودة.
- Vitest لكل مكوّن فيه منطق (حسابات، شروط عرض، تحقق) — ليس للمكونات الشكلية البحتة.
- إن فشلت أي بوابة: أصلح ثم أعد التشغيل. **ممنوع** تعطيل قاعدة فحص أو تجاوزها للتسليم.

## قواعد العمل
- قبل أي مهمة متوسطة أو كبيرة: **اعرض الخطة بلغة بسيطة وانتظر الموافقة.**
- لا تعدّل ملفات خارج نطاق المهمة، ولا تلمس موديولًا غير الذي تعمل فيه إلا عبر حدوده العامة.
- لا تلمس `.env`. لا ترفع مباشرة إلى `main`.
- **لا تقل "تم بنجاح" قبل أن يجرّبه المستخدم بنفسه.** قل: "خلص — اكتب `/جرب` وشوفه بعينك".
- إن وجدت تكرارًا لكود موجود، توقف واقترح إعادة الاستخدام.
- إن لم تعرف السبب، **قل إنك لا تعرف** وابحث. لا تخمّن ولا تعدّل عشوائيًا.

## عند نهاية أي مهمة
اختم دائمًا باقتراح الخطوة التالية بأمر واحد يكتبه، مثل: `/جرب` أو `/انشر تجربة`.

## الأوامر
```bash
cd frontend && npm run dev              # تشغيل الواجهة
cd frontend && npm run check            # كل فحوصات الواجهة
cd backend  && php artisan serve        # تشغيل الخدمات
cd backend  && php artisan migrate
cd backend  && ./vendor/bin/pint && ./vendor/bin/phpstan analyse && php artisan test
```
