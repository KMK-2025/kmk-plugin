<?php

namespace App\Modules\Mobile\Http\Controllers\V1;

use App\Http\Controllers\Controller;
use App\Modules\Mobile\Services\AppVersionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AppVersionController extends Controller
{
    public function show(Request $request, AppVersionService $versions): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $versions->status(
                $request->headers->get('X-Platform'),
                $request->headers->get('X-App-Version'),
            ),
            'message' => null,
        ]);
    }
}
