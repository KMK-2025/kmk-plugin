<!-- kmk:mobile -->
---

## الجوال — `Mobile`

> **الموديول:** `app/Modules/Mobile` ↔ `mobile/lib/shared/{app_version,push}`
> **المسارات:** `routes/api/v1/mobile.php`
> كل طلب من التطبيق يحمل الترويستين `X-App-Version` (مثل `1.4.0`) و `X-Platform` (`android` أو `ios`).
> طلب من إصدار أقدم من «أقل إصدار مدعوم» يُرفض بـ `426` في كل النقاط عدا `GET /app/version`.

### GET /app/version
**الصلاحية:** بلا تسجيل دخول
**الرد:**
```json
{
  "success": true,
  "data": {
    "platform": "android",
    "current": "1.2.0",
    "min_supported": "1.0.0",
    "latest": "1.4.0",
    "must_update": false,
    "store_url": null
  }
}
```

### POST /devices
**الصلاحية:** مسجّل دخول
**المدخلات:** `token` (مطلوب، رمز الإشعارات) · `platform` (مطلوب: `android` أو `ios`) · `app_version` (اختياري)
**الرد (201):** `{ id, platform, app_version }`
