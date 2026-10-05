<?php

namespace App\Modules\Mobile\Services;

use App\Modules\Mobile\Models\Device;
use Illuminate\Support\Facades\Log;

/**
 * نقطة الإرسال الوحيدة للإشعارات — أي موديول يريد إشعار مستخدم يستدعيها.
 *
 * الإرسال الفعلي عبر Firebase يُفعَّل بعد ربط مشروع Firebase (يحتاج حساب
 * صاحب المشروع). إلى ذلك الحين تُسجَّل الإشعارات في السجل فقط، فيُبنى
 * ويُختبر كل ما يعتمد عليها دون انتظار.
 */
class PushNotifier
{
    /**
     * @param  array<string, string>  $data
     * @return int عدد الأجهزة المستهدفة
     */
    public function send(int $userId, string $title, string $body, array $data = []): int
    {
        $devices = Device::query()->where('user_id', $userId)->count();

        Log::info('push.queued', [
            'user_id' => $userId,
            'title' => $title,
            'body' => $body,
            'data' => $data,
            'devices' => $devices,
        ]);

        return $devices;
    }
}
