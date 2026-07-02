import 'package:label_core/label_core.dart';
import 'package:label_history/label_history.dart';
import 'package:test/test.dart';

LabelDocument _blankDocument({List<LabelElement> elements = const []}) =>
    LabelDocument.blank(name: 'Doc').copyWith(elements: elements);

const _rect = RectangleElement(
  id: 'r-1',
  name: 'Rect',
  position: Point(x: 1, y: 1),
  size: Size2D(width: 10, height: 10),
  layerId: 'layer-1',
);

const _text = TextElement(
  id: 't-1',
  name: 'Texto',
  position: Point.zero(),
  size: Size2D(width: 30, height: 10),
  layerId: 'layer-1',
  content: 'Antes',
);

void main() {
  group('MoveCommand', () {
    test('execute moves the element, undo restores its original position', () {
      final document = _blankDocument(elements: [_rect]);
      final command = MoveCommand(
        elementId: 'r-1',
        from: _rect.position,
        to: const Point(x: 5, y: 5),
      );

      final moved = command.execute(document);
      expect(moved.elements.single.position, const Point(x: 5, y: 5));

      final restored = command.undo(moved);
      expect(restored.elements.single.position, _rect.position);
    });
  });

  group('ResizeCommand', () {
    test('execute resizes the element, undo restores its original size', () {
      final document = _blankDocument(elements: [_rect]);
      final command = ResizeCommand(
        elementId: 'r-1',
        from: _rect.size,
        to: const Size2D(width: 20, height: 20),
      );

      final resized = command.execute(document);
      expect(resized.elements.single.size, const Size2D(width: 20, height: 20));

      final restored = command.undo(resized);
      expect(restored.elements.single.size, _rect.size);
    });
  });

  group('RotateCommand', () {
    test(
      'execute rotates the element, undo restores its original rotation',
      () {
        final document = _blankDocument(elements: [_rect]);
        final command = RotateCommand(elementId: 'r-1', from: 0, to: 90);

        final rotated = command.execute(document);
        expect(rotated.elements.single.rotation, 90);

        final restored = command.undo(rotated);
        expect(restored.elements.single.rotation, 0);
      },
    );
  });

  group('ChangePropertyCommand', () {
    test('execute/undo toggle a type-specific property via apply', () {
      final document = _blankDocument(elements: [_text]);
      final command = ChangePropertyCommand<String>(
        elementId: 't-1',
        oldValue: 'Antes',
        newValue: 'Depois',
        apply: (element, value) =>
            (element as TextElement).copyWith(content: value),
      );

      final changed = command.execute(document);
      expect((changed.elements.single as TextElement).content, 'Depois');

      final restored = command.undo(changed);
      expect((restored.elements.single as TextElement).content, 'Antes');
    });
  });

  group('AddCommand', () {
    test('execute appends the element, undo removes it again', () {
      final document = _blankDocument();
      final command = AddCommand(element: _rect);

      final added = command.execute(document);
      expect(added.elements.single, _rect);

      final restored = command.undo(added);
      expect(restored.elements, isEmpty);
    });

    test('execute inserts into a group when parentId is set', () {
      const group = GroupElement(
        id: 'g-1',
        name: 'Group',
        position: Point.zero(),
        size: Size2D(width: 20, height: 20),
        layerId: 'layer-1',
        children: [],
      );
      final document = _blankDocument(elements: [group]);
      final command = AddCommand(element: _rect, parentId: 'g-1');

      final added = command.execute(document);
      final resultGroup = added.elements.single as GroupElement;
      expect(resultGroup.children.single, _rect);
    });
  });

  group('ChangeDocumentCommand', () {
    test('execute/undo toggle a document-level field via apply', () {
      final document = _blankDocument();
      final command = ChangeDocumentCommand<String>(
        oldValue: document.name,
        newValue: 'Novo nome',
        apply: (doc, value) => doc.copyWith(name: value),
      );

      final changed = command.execute(document);
      expect(changed.name, 'Novo nome');

      final restored = command.undo(changed);
      expect(restored.name, document.name);
    });
  });

  group('CompositeCommand', () {
    test('execute runs sub-commands in order; undo reverses that order', () {
      final other = _rect.copyWith(id: 'r-2', name: 'Rect 2');
      final document = _blankDocument(elements: [_rect, other]);
      final command = CompositeCommand([
        MoveCommand(
          elementId: 'r-1',
          from: _rect.position,
          to: const Point(x: 9, y: 9),
        ),
        MoveCommand(
          elementId: 'r-2',
          from: other.position,
          to: const Point(x: 8, y: 8),
        ),
      ]);

      final moved = command.execute(document);
      expect(moved.elements[0].position, const Point(x: 9, y: 9));
      expect(moved.elements[1].position, const Point(x: 8, y: 8));

      final restored = command.undo(moved);
      expect(restored.elements[0].position, _rect.position);
      expect(restored.elements[1].position, other.position);
    });

    test('an empty CompositeCommand is a no-op', () {
      final document = _blankDocument(elements: [_rect]);
      const command = CompositeCommand([]);
      expect(command.execute(document), document);
      expect(command.undo(document), document);
    });
  });

  group('DeleteCommand', () {
    test(
      'capture + execute removes a top-level element; undo restores its index',
      () {
        final other = _rect.copyWith(id: 'r-2', name: 'Rect 2');
        final document = _blankDocument(elements: [_rect, other]);
        final command = DeleteCommand.capture(document, 'r-1');

        final deleted = command.execute(document);
        expect(deleted.elements.map((e) => e.id), ['r-2']);

        final restored = command.undo(deleted);
        expect(restored.elements.map((e) => e.id), ['r-1', 'r-2']);
      },
    );

    test(
      'capture + execute + undo round-trips an element nested in a group',
      () {
        final group = GroupElement(
          id: 'g-1',
          name: 'Group',
          position: const Point.zero(),
          size: const Size2D(width: 20, height: 20),
          layerId: 'layer-1',
          children: [
            _rect,
            _rect.copyWith(id: 'r-2'),
          ],
        );
        final document = _blankDocument(elements: [group]);
        final command = DeleteCommand.capture(document, 'r-1');

        final deleted = command.execute(document);
        final deletedGroup = deleted.elements.single as GroupElement;
        expect(deletedGroup.children.map((e) => e.id), ['r-2']);

        final restored = command.undo(deleted);
        final restoredGroup = restored.elements.single as GroupElement;
        expect(restoredGroup.children.map((e) => e.id), ['r-1', 'r-2']);
      },
    );

    test('capture throws ArgumentError when the id does not exist', () {
      final document = _blankDocument();
      expect(
        () => DeleteCommand.capture(document, 'missing'),
        throwsArgumentError,
      );
    });
  });
}
