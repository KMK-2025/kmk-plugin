<?php

namespace App\Modules\Mobile\Http\Middleware;

use App\Modules\Mobile\Services\AppVersionService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * يرفض طلبات إصدارات التطبيق الأقدم من «أقل إصدار مدعوم» برمز 426،
 * فيعرض التطبيق شاشة «حدّث التطبيق» بدل أن يتعامل مع بيانات لا يفهمها.
 */
class EnsureSupportedAppVersion
{
    public function __construct(private readonly AppVersionService $versions) {}

    /**
     * @param  Closure(Request): Response  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $platform = $request->headers->get('X-Platform');
        $version = $request->headers->get('X-App-Version');

        if (! $this->versions->isSupported($platform, $version)) {
            return response()->json([
                'success' => false,
                'data' => $this->versions->status($platform, $version),
                'message' => 'هذا الإصدار من التطبيق لم يعد مدعومًا. حدّث التطبيق للمتابعة.',
                'errors' => null,
            ], 426);
        }

        return $next($request);
    }
}
