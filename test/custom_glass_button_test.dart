import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Note/shared/widgets/glass_widgets.dart';

void main() {
  test('defaults match the Note Detail glass button treatment', () {
    const button = CustomGlassButton(onPressed: null, child: SizedBox());

    expect(button.blur, 10);
    expect(button.opacity, 0.15);
    expect(button.thickness, 8);
  });
}
