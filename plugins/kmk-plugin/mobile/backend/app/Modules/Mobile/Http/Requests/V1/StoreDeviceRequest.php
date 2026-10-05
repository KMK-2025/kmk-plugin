<?php

namespace App\Modules\Mobile\Http\Requests\V1;

use Illuminate\Foundation\Http\FormRequest;

class StoreDeviceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, list<string>>
     */
    public function rules(): array
    {
        return [
            'token' => ['required', 'string', 'max:512'],
            'platform' => ['required', 'string', 'in:android,ios'],
            'app_version' => ['nullable', 'string', 'max:20'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'token.required' => 'رمز الجهاز مطلوب.',
            'token.max' => 'رمز الجهاز أطول من المسموح.',
            'platform.required' => 'نوع الجهاز مطلوب.',
            'platform.in' => 'نوع الجهاز يجب أن يكون android أو ios.',
            'app_version.max' => 'رقم إصدار التطبيق أطول من المسموح.',
        ];
    }
}
