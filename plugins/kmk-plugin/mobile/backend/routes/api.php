<?php

use App\Modules\Mobile\Http\Middleware\EnsureSupportedAppVersion;
use Illuminate\Support\Facades\Route;

// تحميل مسارات كل نسخة تلقائيًا — كل موديول ملف مستقل في routes/api/v<N>/
foreach (glob(__DIR__.'/api/v*', GLOB_ONLYDIR) ?: [] as $versionDir) {
    $version = basename($versionDir);

    Route::prefix($version)
        ->name($version.'.')
        ->middleware(['throttle:60,1', EnsureSupportedAppVersion::class])
        ->group(function () use ($versionDir) {
            foreach (glob($versionDir.'/*.php') ?: [] as $routeFile) {
                require $routeFile;
            }
        });
}
