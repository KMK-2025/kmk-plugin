<?php

namespace App\Modules\Mobile\Http\Controllers\V1;

use App\Http\Controllers\Controller;
use App\Modules\Mobile\Http\Requests\V1\StoreDeviceRequest;
use App\Modules\Mobile\Models\Device;
use Illuminate\Http\JsonResponse;

class DeviceController extends Controller
{
    public function store(StoreDeviceRequest $request): JsonResponse
    {
        /** @var array{token: string, platform: string, app_version?: string|null} $data */
        $data = $request->validated();

        $device = Device::query()->updateOrCreate(
            ['token' => $data['token']],
            [
                'user_id' => $request->user()?->getAuthIdentifier(),
                'platform' => $data['platform'],
                'app_version' => $data['app_version'] ?? $request->headers->get('X-App-Version'),
                'last_seen_at' => now(),
            ],
        );

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $device->id,
                'platform' => $device->platform,
                'app_version' => $device->app_version,
            ],
            'message' => null,
        ], 201);
    }
}
