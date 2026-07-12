import 'package:flutter_test/flutter_test.dart';
import 'package:label_designer/src/logic/id_generator.dart';

void main() {
  test('generateElementId produces unique ids across many calls', () {
    final ids = {for (var i = 0; i < 1000; i++) generateElementId()};
    expect(ids, hasLength(1000));
  });

  test('generateElementId is non-empty and stable in shape', () {
    final id = generateElementId();
    expect(id, startsWith('el-'));
    expect(id.split('-'), hasLength(3));
  });

  test('generateLayerId produces unique, "layer-"-prefixed ids', () {
    final ids = {for (var i = 0; i < 1000; i++) generateLayerId()};
    expect(ids, hasLength(1000));
    expect(generateLayerId(), startsWith('layer-'));
  });

  test('generateId uses the given prefix', () {
    expect(generateId('foo'), startsWith('foo-'));
  });
}
