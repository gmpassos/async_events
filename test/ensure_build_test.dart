@TestOn('vm')
@Timeout(Duration(minutes: 2))
@Tags(['build', 'slow'])
library;

import 'package:build_verify/build_verify.dart';
import 'package:test/test.dart';

void main() {
  test('ensure_build', expectBuildClean);
}
