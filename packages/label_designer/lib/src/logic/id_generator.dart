import 'dart:math';

const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
final _random = Random();

/// A short, effectively-unique id prefixed with [prefix] (`'el'`,
/// `'layer'`, ...), combining the current time with a random suffix.
///
/// Good enough for editing a single in-memory document within one running
/// app session — `label_serialization` doesn't validate id uniqueness on
/// load, so this deliberately doesn't try to guarantee global uniqueness
/// across sessions/files either, just "won't collide with anything
/// already on screen".
String generateId(String prefix) {
  final suffix = List.generate(
    6,
    (_) => _alphabet[_random.nextInt(_alphabet.length)],
  ).join();
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$suffix';
}

/// A short, effectively-unique id for a new [LabelElement] or
/// `GroupElement` — see [generateId].
String generateElementId() => generateId('el');

/// A short, effectively-unique id for a new `LabelLayer` — see
/// [generateId].
String generateLayerId() => generateId('layer');
