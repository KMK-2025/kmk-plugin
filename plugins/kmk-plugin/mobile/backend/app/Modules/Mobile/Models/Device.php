<?php

namespace App\Modules\Mobile\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * جهاز مسجَّل لاستقبال الإشعارات. جدول تقني: لا يدخل سجل العمليات.
 *
 * @property int $id
 * @property int $user_id
 * @property string $token
 * @property string $platform
 * @property string|null $app_version
 * @property \Illuminate\Support\Carbon|null $last_seen_at
 */
class Device extends Model
{
    /** @var list<string> */
    protected $fillable = ['user_id', 'token', 'platform', 'app_version', 'last_seen_at'];

    /** @var list<string> */
    protected $hidden = ['token'];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return ['last_seen_at' => 'datetime'];
    }
}
