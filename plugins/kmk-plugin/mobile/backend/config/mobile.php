<?php

/*
 * إعدادات تطبيق الجوال.
 *
 * min_supported: أقل إصدار يُسمح له بالعمل. ارفعه لإجبار الإصدارات الأقدم
 *                على التحديث (مثلًا قبل حذف نسخة API قديمة).
 * latest:        آخر إصدار منشور — يُحدَّث مع كل نشر للتطبيق.
 * store_url:     رابط تنزيل الإصدار الأحدث.
 */

return [
    'platforms' => [
        'android' => [
            'min_supported' => '1.0.0',
            'latest' => '1.0.0',
            'store_url' => null,
        ],
        'ios' => [
            'min_supported' => '1.0.0',
            'latest' => '1.0.0',
            'store_url' => null,
        ],
    ],
];
