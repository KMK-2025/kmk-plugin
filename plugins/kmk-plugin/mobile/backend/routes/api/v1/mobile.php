<?php

use App\Modules\Mobile\Http\Controllers\V1\AppVersionController;
use App\Modules\Mobile\Http\Controllers\V1\DeviceController;
use App\Modules\Mobile\Http\Middleware\EnsureSupportedAppVersion;
use Illuminate\Support\Facades\Route;

// مستثناة من حارس الإصدار: الإصدار القديم يحتاجها ليعرف أن عليه التحديث
Route::get('app/version', [AppVersionController::class, 'show'])
    ->withoutMiddleware(EnsureSupportedAppVersion::class)
    ->name('mobile.app-version');

Route::post('devices', [DeviceController::class, 'store'])
    ->middleware('auth:sanctum')
    ->name('mobile.devices.store');
