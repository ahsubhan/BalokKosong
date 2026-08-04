import 'package:balok_kosong/game_engine.dart';
import 'package:balok_kosong/native_game.dart';
import 'package:flutter_test/flutter_test.dart';

PuzzlePiece piece(String id, int x, int y) => PuzzlePiece(
  id: id,
  x: x,
  y: y,
  direction: 0,
  shape: PieceShape.i,
  length: 2,
  colorIndex: 0,
);

void main() {
  group('piece selection', () {
    test('exact horizontal block wins over overlapping padded neighbour', () {
      final target = piece('target', 5, 5);
      final leftNeighbour = piece('left', 3, 5);

      final selected = selectPuzzlePieceAt(
        pieces: [target, leftNeighbour],
        point: const Offset(5.1, 5.5),
        cellSize: 1,
        sensitiveTouch: true,
      );

      expect(selected?.id, 'target');
    });

    test('near miss selects the closest block', () {
      final left = piece('left', 1, 5);
      final right = piece('right', 5, 5);

      final selected = selectPuzzlePieceAt(
        pieces: [left, right],
        point: const Offset(4.7, 5.5),
        cellSize: 1,
        sensitiveTouch: true,
      );

      expect(selected?.id, 'right');
    });
  });

  group('wrong move accounting', () {
    test('minor drag without collision does not consume a mistake', () {
      expect(
        shouldRecordWrongMove(
          dragAttempted: true,
          collisionAttempted: false,
          moved: false,
        ),
        isFalse,
      );
    });

    test('blocked drag consumes a mistake', () {
      expect(
        shouldRecordWrongMove(
          dragAttempted: true,
          collisionAttempted: true,
          moved: false,
        ),
        isTrue,
      );
    });

    test('successful move never consumes a mistake', () {
      expect(
        shouldRecordWrongMove(
          dragAttempted: true,
          collisionAttempted: true,
          moved: true,
        ),
        isFalse,
      );
    });
  });
}
