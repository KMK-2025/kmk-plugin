<?php

namespace Tests\Support;

use Illuminate\Testing\TestResponse;
use PHPUnit\Framework\Assert;

/**
 * حارس توافق الـ API.
 *
 * يحفظ «شكل» كل رد ناجح (المفاتيح وأنواعها) في tests/api-snapshots/<النسخة>/،
 * ويُفشل الاختبار إن حُذف حقل أو تغيّر نوعه في نسخة قائمة — لأن تطبيقات
 * قديمة في أيدي الناس ما زالت تعتمد عليه. الحقول الجديدة مسموحة وتُضاف
 * للشكل المحفوظ تلقائيًا.
 *
 * عند الفشل لا تعدّل الملف المحفوظ: ارفع النسخة بـ bump-api-version.sh.
 */
final class ApiShape
{
    private const LIST_KEY = '[]';

    /**
     * @param  TestResponse<\Symfony\Component\HttpFoundation\Response>  $response
     */
    public static function assertCompatible(TestResponse $response, string $version, string $name): void
    {
        $current = self::describe($response->json());
        $path = base_path("tests/api-snapshots/{$version}/{$name}.json");

        if (! is_file($path)) {
            self::write($path, $current);
            Assert::assertTrue(true);

            return;
        }

        $saved = json_decode((string) file_get_contents($path), true);
        $breaks = self::breaks($saved, $current, 'الرد');

        if ($breaks !== []) {
            Assert::fail(
                "تغيير يكسر التوافق في نسخة قائمة ({$version} · {$name}):\n- ".implode("\n- ", $breaks)
                ."\n\nلا تعدّل هذه النسخة ولا ملف الشكل المحفوظ. أعد الرد كما كان، ثم شغّل:\n"
                .'  bash .claude/scripts/bump-api-version.sh "سبب التغيير"'
                ."\nوانقل التغيير إلى النسخة الجديدة."
            );
        }

        self::write($path, self::merge($saved, $current));
        Assert::assertTrue(true);
    }

    private static function describe(mixed $value): mixed
    {
        if (is_array($value)) {
            if (array_is_list($value)) {
                return [self::LIST_KEY => $value === [] ? null : self::describe($value[0])];
            }

            $shape = [];
            foreach ($value as $key => $item) {
                $shape[(string) $key] = self::describe($item);
            }
            ksort($shape);

            return $shape;
        }

        return match (true) {
            $value === null => 'null',
            is_bool($value) => 'boolean',
            is_int($value), is_float($value) => 'number',
            default => 'string',
        };
    }

    /**
     * @return list<string>
     */
    private static function breaks(mixed $saved, mixed $current, string $path): array
    {
        // قيمة لم يُعرف نوعها بعد (كانت فارغة) أو فارغة الآن: لا حكم
        if ($saved === null || $saved === 'null' || $current === null || $current === 'null') {
            return [];
        }

        if (is_string($saved)) {
            if (! is_string($current)) {
                return ["تغيّر نوع «{$path}»: كان {$saved} وصار بنية مركّبة"];
            }

            return $saved === $current ? [] : ["تغيّر نوع «{$path}»: كان {$saved} وصار {$current}"];
        }

        if (! is_array($current)) {
            return ["تغيّر نوع «{$path}»: كان بنية مركّبة وصار {$current}"];
        }

        $savedIsList = self::isList($saved);
        $currentIsList = self::isList($current);

        if ($savedIsList || $currentIsList) {
            // القائمة الفارغة لا تُميَّز عن الكائن الفارغ في JSON المحوَّل
            $savedItem = $savedIsList ? $saved[self::LIST_KEY] : null;
            $currentItem = $currentIsList ? $current[self::LIST_KEY] : null;

            if ($savedIsList && $currentIsList) {
                return self::breaks($savedItem, $currentItem, $path.'[]');
            }

            $emptySide = $savedIsList ? $savedItem : $currentItem;

            return $emptySide === null ? [] : ["تغيّر نوع «{$path}»: بين قائمة وكائن"];
        }

        $breaks = [];
        foreach ($saved as $key => $savedValue) {
            if (! array_key_exists($key, $current)) {
                $breaks[] = "حُذف الحقل «{$path}.{$key}»";

                continue;
            }

            array_push($breaks, ...self::breaks($savedValue, $current[$key], "{$path}.{$key}"));
        }

        return $breaks;
    }

    private static function merge(mixed $saved, mixed $current): mixed
    {
        if ($saved === null || $saved === 'null') {
            return $current;
        }

        if ($current === null || $current === 'null' || is_string($saved) || ! is_array($current)) {
            return $saved;
        }

        if (self::isList($saved) || self::isList($current)) {
            if (! self::isList($saved)) {
                return $saved;
            }

            if (! self::isList($current)) {
                return $saved[self::LIST_KEY] === null ? $current : $saved;
            }

            return [self::LIST_KEY => self::merge($saved[self::LIST_KEY], $current[self::LIST_KEY])];
        }

        foreach ($current as $key => $value) {
            $saved[$key] = array_key_exists($key, $saved) ? self::merge($saved[$key], $value) : $value;
        }
        ksort($saved);

        return $saved;
    }

    private static function isList(mixed $shape): bool
    {
        return is_array($shape) && count($shape) === 1 && array_key_exists(self::LIST_KEY, $shape);
    }

    private static function write(string $path, mixed $shape): void
    {
        if (! is_dir(dirname($path))) {
            mkdir(dirname($path), 0755, true);
        }

        file_put_contents(
            $path,
            json_encode($shape, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)."\n"
        );
    }
}
