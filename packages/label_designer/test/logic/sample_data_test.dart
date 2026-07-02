import 'package:flutter_test/flutter_test.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer/src/logic/sample_data.dart';

void main() {
  test('uses defaultValue when present', () {
    final data = buildSampleData(const [
      LabelVariable(name: 'produto', defaultValue: 'Parafuso'),
    ]);
    expect(data, {'produto': 'Parafuso'});
  });

  test('falls back to a type-appropriate empty value', () {
    final data = buildSampleData(const [
      LabelVariable(name: 'a', type: VariableType.string),
      LabelVariable(name: 'b', type: VariableType.number),
      LabelVariable(name: 'c', type: VariableType.boolean),
    ]);
    expect(data['a'], '');
    expect(data['b'], 0);
    expect(data['c'], false);
  });

  test('date variables without a default fall back to a DateTime', () {
    final data = buildSampleData(const [
      LabelVariable(name: 'validade', type: VariableType.date),
    ]);
    expect(data['validade'], isA<DateTime>());
  });

  test('empty variable list produces an empty map', () {
    expect(buildSampleData(const []), isEmpty);
  });
}
