# دستور المشروع

## من تخاطب
صاحب هذا المشروع **ليس مبرمجًا**. هذه ليست تفصيلة جانبية — هي القاعدة التي تحكم كل تصرفاتك:

- تحدّث معه بالعربية، بلغة يومية بسيطة. أسماء الملفات والدوال والمتغيرات بالإنجليزية.
- **ممنوع** استخدام هذه الكلمات معه: API، endpoint، schema، migration، state، props، component، refactor، dependency، backend، frontend، module.
  استخدم بدلها: "الشاشة"، "المعلومات المحفوظة"، "الخدمة"، "شكل قاعدة البيانات"، "القسم".
- لا تعرض عليه كودًا إلا إذا طلبه صراحة. اعرض **النتيجة** لا الطريقة.
- عند أي قرار تقني، اشرح **الأثر عليه** لا التفاصيل: قل "هذا يخلي الصفحة تفتح أسرع" لا "هذا يقلل re-renders".
- إن أخطأ في المصطلح، لا تصحّحه — افهم قصده وأكمل.

---

## الفصل بين المعمار والتصميم — اقرأ هذا قبل أي شيء

هذا المشروع يفصل بين أمرين فصلًا تامًا:

| **المعمار** — ثابت، تحدّده الإضافة | **التصميم** — حرّ، يحدّده `/صمم` من صور المستخدم |
|---|---|
| بنية الموديولز والحدود بينها | تخطيط الصفحات وتركيبها |
| عقد الخدمات وشكل الردود | شكل التنقّل: قائمة جانبية؟ شريط علوي؟ تبويبات؟ لا شيء؟ |
| المصادقة والجلسة وحماية المسارات | الألوان والخطوط والمسافات والزوايا |
| بنية المسارات ونقطة تسجيلها | شكل كل مكوّن ومظهره |
| سلوك مكونات الحالات وخصائصها | شكل تلك المكونات |
| الصلاحيات والزرع والاختبارات والأمان | — |

**ممنوع منعًا باتًا أن تخترع تصميمًا.** لا تضف قائمة جانبية ولا شريطًا علويًا ولا لوحة
معلومات ولا ألوانًا ولا خطوطًا من عندك. صاحب النظام يضع صوره المرجعية في `docs/design/`
ثم يكتب `/صمم`، وهناك — وهناك فقط — تُتخذ قرارات الشكل.

إن طُلب منك بناء شاشة قبل `/صمم`، ابنِها **بلا تنسيق** واذكر له أن شكلها يأتي لاحقًا.

---

## الأساس التقني — موجود ويعمل، ولا يُعاد بناؤه

هذه الملفات جاهزة منذ إنشاء المشروع. **استخدمها ولا تنشئ بديلًا عنها.**
إن احتجت تعديل أحدها، اشرح السبب لصاحب المشروع واطلب موافقة صريحة أولًا.

### الخدمات
| الملف | ما يقدّمه |
|---|---|
| `app/Support/ApiResponse.php` | `success()` · `created()` · `error()` · `paginated()` — الغلاف الموحّد. لا تبنِ شكل رد يدويًا |
| `app/Support/Concerns/InteractsWithListQuery.php` | بحث وفرز وترقيم بقائمة أعمدة بيضاء |
| `bootstrap/app.php` | أسماء وسائط `permission`/`role`، وتحويل كل خطأ إلى الغلاف الموحّد |
| `app/Modules/Auth/` | **الموديول المرجعي** — قلّد بنيته حرفيًا في كل موديول تبنيه |
| `app/Models/User.php` | فيه `HasRoles` و `LogsActivity` و `$hidden` |
| `database/seeders/RolePermissionSeeder.php` | الأدوار والصلاحيات |
| `lang/ar/` | رسائل التحقق والأخطاء بالعربية |
| `tests/Pest.php` | `actingAsAdmin()` · `actingAsStaff()` |

### الواجهة
| الملف | ما يقدّمه |
|---|---|
| `src/shared/api/client.ts` | `http.get/post/put/del` و `API_VERSION`. **المكان الوحيد** الذي يعرف رقم النسخة. ممنوع `axios` خارجه وممنوع كتابة `/v1/` يدويًا |
| `src/shared/api/types.ts` | `ApiEnvelope` · `Paginated<T>` · `ListParams` |
| `src/shared/forms/applyServerErrors.ts` | يحوّل خطأ 422 إلى أخطاء حقول بسطر واحد |
| `src/shared/store/auth.store.ts` | الجلسة و `hasPermission()` |
| `src/shared/hooks/useListParams.ts` · `useListQuery.ts` | حالة أي قائمة (صفحة، بحث مؤجّل، فرز) — بلا شكل |
| `src/shared/components/feedback/StateBoundary.tsx` | **الحالات الخمس في مكوّن واحد** |
| `src/app/router.tsx` · `ProtectedRoute.tsx` | بنية المسارات والحماية |
| `src/features/auth/` | **الموديول المرجعي** للواجهة |

### نقاط الإضافة الثلاث — الملفات الوحيدة من الأساس التي يجوز لبناء موديول أن يعدّلها
1. `frontend/src/app/routes.tsx` — صف لكل شاشة جديدة
2. `backend/database/seeders/RolePermissionSeeder.php` — صلاحيات القسم الجديد
3. `frontend/src/locales/ar.json` و `en.json` — نصوص القسم

وملفان يملكهما `/صمم` وحده: `src/app/RootLayout.tsx` و `src/styles/theme.css`.

---

## الوثائق المرجعية
- المتطلبات: `docs/spec.md`
- عقد الخدمات: `docs/api-contract.md`
- نظام التصميم: `docs/design-system.md` (فارغ حتى يملأه `/صمم`)

اقرأ الملف المناسب قبل أي مهمة تخصه. **لا تخترع حقلًا أو مسارًا غير موجود في العقد.**

## التقنيات — لا تُضاف مكتبة خارج هذه القائمة قبل أن تشرح السبب وتنتظر موافقة صريحة
**الواجهة:** React 19 · TypeScript · Vite 6 · Bootstrap 5 (RTL) · React Router 7 · Axios · TanStack Query · React Hook Form · Zod 3 · Zustand · i18next · react-hot-toast
**جودة الواجهة:** ESLint · Prettier · Vitest · Testing Library
**الخدمات:** Laravel 12 · MySQL 8 · Sanctum · spatie/laravel-permission · spatie/laravel-activitylog
**جودة الخدمات:** Pest · Pint · Larastan

الإصدارات مثبّتة في `package.json` و `composer.json`. لا ترفعها بلا سبب وموافقة.

---

## البنية المعمارية — موديولز إلزامية

كل قسم وظيفي (فواتير، موظفون، عملاء…) وحدة مستقلة كاملة في الخدمات والواجهة معًا،
بنفس الاسم الإنجليزي في الجهتين.

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
tests/Feature/Invoices/V1/
```

### الواجهة — `frontend/src/features/<feature>/`
```
src/features/invoices/
├── pages/                        ← القائمة، النموذج، التفاصيل
├── components/                   ← مكونات خاصة بهذا الموديول فقط
├── hooks/
├── services/invoices.service.ts
├── types/
└── index.ts                      ← الصادرات العامة الوحيدة
```

### قواعد الحدود — تُفحص آليًا في `npm run check`
- **ممنوع** أن يستورد موديول من داخل موديول آخر. التواصل فقط عبر `features/<x>/index.ts`.
  (قاعدة `no-restricted-imports` ترفض المخالفة.)
- **ممنوع** `axios` خارج `shared/api/client.ts`.
- ما يحتاجه موديولان أو أكثر مكانه `shared/` (واجهة) أو Service مشترك (خدمات).
- **ممنوع** كود وظيفي خارج الموديولز، باستثناءات مذكورة صراحةً:
  `app/Models/User.php` · `app/Support/` · `bootstrap/app.php` · `database/seeders/` · `app/Providers/`.
- حذف موديول = حذف مجلديه + ملف مساراته + صفّه في `routes.tsx`.

---

## نسخ الـ API — إلزامية من اليوم الأول

- كل مسار تحت `/api/v1/...`. ملفات المسارات في `routes/api/v1/` و Controllers/Requests/Resources داخل namespace `V1`.
- الواجهة تقرأ رقم النسخة من `API_VERSION` في `shared/api/client.ts` — **ممنوع** كتابة `/v1/` يدويًا.
- **نسخة جديدة فقط عند كسر التوافق:** حذف أو إعادة تسمية حقل، تغيير شكل الرد، تغيير معنى سلوك قائم.
- **الإضافات لا تكسر:** حقل جديد، نقطة جديدة، معامل اختياري جديد — كلها تدخل في النسخة الحالية.
- عند إنشاء `V2` لنقطة: تُنسخ النقطة المتغيرة فقط، ويشير ملف `routes/api/v2/` للنقاط غير المتغيرة إلى Controllers `V1` نفسها.
- **ممنوع حذف أو تعديل سلوك نسخة قديمة** ما دامت أي شاشة تستهلكها.
- كل نسخة موثّقة في `docs/api-contract.md`.

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

1. **كل نقطة API** محمية بـ `auth:sanctum` + `permission:` عبر spatie. التحقق في الخادم إلزامي — إخفاء الأزرار في الواجهة تحسين تجربة فقط.
2. **Rate limiting:** الدخول `throttle:5,1` والـ API العام `throttle:60,1`. لا نقطة بلا حد.
3. **التوكن ينتهي:** صلاحية Sanctum أسبوع (`SANCTUM_TOKEN_EXPIRATION`)، لا توكنات أبدية.
4. **كلمات السر:** `Password::defaults()` مضبوطة في `AppServiceProvider` (8 أحرف، حالتان، أرقام).
5. **سجل العمليات:** كل Model يستخدم `LogsActivity` — من فعل ماذا ومتى.
6. **CORS مقفول:** `allowed_origins` يقرأ `FRONTEND_URL` فقط. ممنوع `*` نهائيًا.
7. **الملفات المرفوعة:** `mimes` و `max` في FormRequest، والتخزين بـ `hashName()`.
8. **لا تسريب:** الحقول الحساسة في `$hidden`، وممنوع password أو token في أي Resource، و `APP_DEBUG=false` في الإنتاج.
9. **قاعدة البيانات:** Eloquent/Query Builder فقط مع مدخلات المستخدم. ممنوع دمج نصوص في SQL خام. أعمدة الفرز من قائمة بيضاء (`InteractsWithListQuery`).
10. **الأسرار** في `.env` فقط — لا تُقرأ ولا تُطبع في السجلات.

> **قرار موثّق — المدير يتجاوز الصلاحيات:** `Gate::before` في `AppServiceProvider` يمرّر دور
> `admin` من كل بوابة. هذا مقصود: بدونه لا يستطيع صاحب النظام فتح أول قسم يُبنى له.
> الأثر: اختبار 403 يجب أن يُكتب على `actingAsStaff()` لا على المدير. **لا تحذفه.**

> **قرار موثّق — التوكن في localStorage:** المصادقة بتوكن `Bearer`. البديل (كوكي + جلسة)
> يضيف تعقيدًا لا يستطيع صاحب النظام تشخيصه عند عطله. الخطر مخفَّف بأن كل نص يمرّ
> بـ `t()` وReact يهرّب المخرجات افتراضيًا.

---

## قواعد الواجهة
- الاتجاه RTL مضبوط مسبقًا في `index.html` و `main.tsx`. لا تعِد ضبطه.
- **ممنوع:** `margin-left/right` · `padding-left/right` · `text-align: left/right` · `left`/`right`.
  **استخدم:** `margin-inline-start/end` · `padding-inline-start/end` · `text-align: start/end` · `inset-inline-start/end`.
  (`npm run check` يرفض المخالفة آليًا.)
- **ممنوع** نص عربي داخل مكوّن. كل النصوص في `src/locales/ar.json` عبر `t('key')`، ونفس المفاتيح في `en.json`. (يُفحص آليًا.)
  رسائل Zod تُبنى داخل المكوّن بـ `t()` — انظر `features/auth/pages/LoginRoute.tsx`.
- **ممنوع** ألوان أو مسافات ثابتة. من `src/styles/theme.css` فقط، بعد أن يملأه `/صمم`.
- **ممنوع** Inline styles إلا لقيمة تُحسب وقت التشغيل.
- كل مكوّن: ملف واحد، غرض واحد، أقل من 200 سطر.
- **الحالات الخمس عبر `StateBoundary`** — لفّ محتوى كل شاشة بيانات به وتتحقّق القاعدة كلها.
- كل استدعاء خدمة عبر `features/<feature>/services/` مستخدمًا `http` من `shared/api`.
- النماذج: React Hook Form + Zod، رسائل من الترجمة، و `disabled` أثناء الإرسال.
- إمكانية الوصول: label لكل حقل، تنقّل بلوحة المفاتيح، تباين كافٍ.
- Lazy loading لكل صفحة (`lazy()` في `routes.tsx`). كل صفحة تُفحص على عرض 375px.

## قواعد الخدمات
- **كل رد عبر `ApiResponse`** — لا تبنِ الشكل يدويًا:
  - عنصر واحد: `ApiResponse::success(new XResource($x))`
  - قائمة: `ApiResponse::paginated($paginator, XResource::class)` → `data: { items, meta }`
  - خطأ: يتولّاه `bootstrap/app.php` تلقائيًا
- Controller نحيف: التحقق في FormRequest، المنطق في Service، الإخراج في Resource. أطول من 100 سطر = منطق في المكان الخطأ.
- رسائل تحقق عربية عبر `messages()` أو `lang/ar/validation.php`.
- الترميز `utf8mb4_unicode_ci`، وفهرس على كل عمود يُستخدم في البحث أو الفرز.
- ممنوع استعلام N+1 — استخدم `with()` دائمًا للعلاقات المعروضة.
- الاختبارات تعمل على قاعدة منفصلة (`phpunit.xml`) — لن تمسّ بيانات صاحب النظام.

---

## بوابات الجودة — لا يُسلَّم عمل قبل مرورها كلها

**الخدمات:**
```bash
cd backend && ./vendor/bin/pint && ./vendor/bin/phpstan analyse && php artisan test
```
**الواجهة:**
```bash
cd frontend && npm run check    # tsc + eslint + prettier + RTL + الترجمة + vitest
```

- اختبار Pest لكل نقطة API: نجاح · فشل تحقق · 401 · 403. النقطة بلا اختبار = غير موجودة.
  استخدم `actingAsAdmin()` و `actingAsStaff()` — والنمط المرجعي في `tests/Feature/Auth/V1/`.
- Vitest لكل مكوّن فيه منطق. اختبر **السلوك لا الشكل** — حتى لا تسقط الاختبارات عندما يعيد `/صمم` التصميم.
- إن فشلت أي بوابة: أصلح ثم أعد التشغيل. **ممنوع** تعطيل قاعدة فحص أو تجاوزها للتسليم.

## قواعد العمل
- قبل أي مهمة متوسطة أو كبيرة: **اعرض الخطة بلغة بسيطة وانتظر الموافقة.**
- لا تعدّل ملفات خارج نطاق المهمة، ولا تلمس موديولًا غير الذي تعمل فيه إلا عبر حدوده العامة.
- لا تلمس `.env`. لا ترفع مباشرة إلى `main` — العمل على فرع `work`.
- **لا تقل "تم بنجاح" قبل أن يجرّبه المستخدم بنفسه.** قل: "خلص — اكتب `/جرب` وشوفه بعينك".
- إن وجدت تكرارًا لكود موجود، توقف واقترح إعادة الاستخدام.
- إن لم تعرف السبب، **قل إنك لا تعرف** وابحث. لا تخمّن ولا تعدّل عشوائيًا.

## عند نهاية أي مهمة
اختم دائمًا باقتراح الخطوة التالية بأمر واحد يكتبه، مثل: `/جرب` أو `/انشر تجربة`.

## الأوامر
```bash
cd frontend && npm run dev              # تشغيل الواجهة → localhost:5173
cd frontend && npm run check            # كل فحوصات الواجهة
cd backend  && php artisan serve        # تشغيل الخدمات → localhost:8000
cd backend  && php artisan migrate
cd backend  && php artisan db:seed --class=RolePermissionSeeder
cd backend  && ./vendor/bin/pint && ./vendor/bin/phpstan analyse && php artisan test
```
بيانات الدخول للتجربة: `admin@test.com` / `password` · وللاختبار بصلاحيات محدودة: `staff@test.com` / `password`
