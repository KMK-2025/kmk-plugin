<?php

namespace App\Modules\Mobile\Services;

class AppVersionService
{
    /** @var list<string> */
    public const PLATFORMS = ['android', 'ios'];

    /**
     * @return array{platform: string|null, current: string|null, min_supported: string|null, latest: string|null, must_update: bool, store_url: string|null}
     */
    public function status(?string $platform, ?string $version): array
    {
        $platform = in_array($platform, self::PLATFORMS, true) ? $platform : null;

        /** @var array{min_supported?: string|null, latest?: string|null, store_url?: string|null} $settings */
        $settings = $platform === null ? [] : (array) config("mobile.platforms.{$platform}", []);

        $minimum = $settings['min_supported'] ?? null;

        return [
            'platform' => $platform,
            'current' => $version,
            'min_supported' => $minimum,
            'latest' => $settings['latest'] ?? null,
            'must_update' => $this->isBelow($version, $minimum),
            'store_url' => $settings['store_url'] ?? null,
        ];
    }

    /**
     * الطلبات التي لا تحمل رقم إصدار (الموقع مثلًا) مدعومة دائمًا.
     */
    public function isSupported(?string $platform, ?string $version): bool
    {
        return ! $this->status($platform, $version)['must_update'];
    }

    private function isBelow(?string $version, ?string $minimum): bool
    {
        if ($version === null || $version === '' || $minimum === null || $minimum === '') {
            return false;
        }

        return version_compare($version, $minimum, '<');
    }
}
