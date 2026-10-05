<?php

namespace Tests\Feature\Mobile\V1;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\ApiShape;
use Tests\TestCase;

class DeviceTest extends TestCase
{
    use RefreshDatabase;

    public function test_signed_in_user_can_register_a_device(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/devices', [
            'token' => 'device-token-1',
            'platform' => 'android',
            'app_version' => '1.0.0',
        ]);

        $response->assertCreated()->assertJsonPath('data.platform', 'android');
        $this->assertDatabaseHas('devices', ['user_id' => $user->id, 'token' => 'device-token-1']);
        ApiShape::assertCompatible($response, 'v1', 'mobile.devices.store');
    }

    public function test_registering_the_same_device_twice_keeps_one_record(): void
    {
        $user = User::factory()->create();
        $payload = ['token' => 'device-token-1', 'platform' => 'android'];

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/devices', $payload)->assertCreated();
        $this->actingAs($user, 'sanctum')->postJson('/api/v1/devices', $payload)->assertCreated();

        $this->assertDatabaseCount('devices', 1);
    }

    public function test_device_registration_requires_sign_in(): void
    {
        $this->postJson('/api/v1/devices', ['token' => 'x', 'platform' => 'android'])
            ->assertUnauthorized();
    }

    public function test_device_registration_validates_platform_with_arabic_message(): void
    {
        $this->actingAs(User::factory()->create(), 'sanctum')
            ->postJson('/api/v1/devices', ['token' => 'x', 'platform' => 'windows'])
            ->assertUnprocessable()
            ->assertJsonPath('errors.platform.0', 'نوع الجهاز يجب أن يكون android أو ios.');
    }
}
