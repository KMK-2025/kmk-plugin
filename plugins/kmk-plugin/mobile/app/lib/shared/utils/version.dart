/// يقارن رقمي إصدار مثل 1.4.0 و 1.10.2. الناتج سالب إن كان [a] أقدم من [b].
int compareVersions(String a, String b) {
  final left = _parts(a);
  final right = _parts(b);

  for (var i = 0; i < 3; i++) {
    final difference = left[i] - right[i];
    if (difference != 0) {
      return difference;
    }
  }

  return 0;
}

/// هل الإصدار [current] ما زال مدعومًا بالنظر إلى أقل إصدار مدعوم [minimum]؟
bool isVersionSupported(String current, String? minimum) {
  if (minimum == null || minimum.isEmpty) {
    return true;
  }

  return compareVersions(current, minimum) >= 0;
}

List<int> _parts(String version) {
  final core = version.split('+').first.split('-').first;
  final numbers = core.split('.').map((part) => int.tryParse(part) ?? 0).toList();

  while (numbers.length < 3) {
    numbers.add(0);
  }

  return numbers;
}
