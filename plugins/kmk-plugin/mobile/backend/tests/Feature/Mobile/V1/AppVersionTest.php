<?php

namespace Tests\Feature\Mobile\V1;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\ApiShape;
use Tests\TestCase;

class AppVersionTest extends TestCase
{
    use RefreshDatabase;

    public function test_supported_version_is_not_asked_to_update(): void
    {
        config(['mobile.platforms.android.min_supported' => '1.2.0']);

        $response = $this->getJson('/api/v1/app/version', [
            'X-Platform' => 'android',
            'X-App-Version' => '1.2.0',
        ]);

        $response->assertOk()->assertJsonPath('data.must_update', false);
        ApiShape::assertCompatible($response, 'v1', 'mobile.app-version');
    }

    public function test_old_version_is_told_to_update(): void
    {
        config(['mobile.platforms.android.min_supported' => '1.2.0']);

        $this->getJson('/api/v1/app/version', [
            'X-Platform' => 'android',
            'X-App-Version' => '1.1.9',
        ])->assertOk()->assertJsonPath('data.must_update', true);
    }

    public function test_old_version_is_rejected_on_other_endpoints(): void
    {
        config(['mobile.platforms.android.min_supported' => '2.0.0']);

        $this->actingAs(User::factory()->create(), 'sanctum')
            ->postJson('/api/v1/devices', ['token' => 'abc', 'platform' => 'android'], [
                'X-Platform' => 'android',
                'X-App-Version' => '1.0.0',
            ])
            ->assertStatus(426)
            ->assertJsonPath('success', false);
    }

    public function test_requests_without_app_version_are_not_blocked(): void
    {
        config(['mobile.platforms.android.min_supported' => '9.0.0']);

        $this->getJson('/api/v1/app/version')
            ->assertOk()
            ->assertJsonPath('data.must_update', false);
    }
}
