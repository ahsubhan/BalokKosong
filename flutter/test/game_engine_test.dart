import 'package:balok_kosong/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

bool _canExit(PuzzleEngine engine, PuzzlePiece piece, int sign) {
  final travel = engine.maxTravel(piece, sign);
  return travel > 0 && engine.isOutside(piece, travel * sign);
}

bool _solveByRemovingEveryAvailablePiece(List<PuzzlePiece> source) {
  final engine = PuzzleEngine(source);
  while (engine.pieces.isNotEmpty) {
    PuzzlePiece? removable;
    for (final piece in engine.pieces) {
      if (_canExit(engine, piece, -1) || _canExit(engine, piece, 1)) {
        removable = piece;
        break;
      }
    }
    if (removable == null) return false;
    engine.pieces.remove(removable);
  }
  return true;
}

void main() {
  group('level integrity', () {
    for (var levelIndex = 0; levelIndex < totalLevels; levelIndex++) {
      test('level ${levelIndex + 1} is complete, valid, and solvable', () {
        final expected = levelPieceCount(levelIndex);
        final pieces = generateLevel(levelIndex + 1, expected);

        expect(pieces, hasLength(expected));
        expect(pieces.map((piece) => piece.id).toSet(), hasLength(expected));

        final occupied = <String>{};
        for (final piece in pieces) {
          expect(piece.length, inInclusiveRange(2, 7));
          expect(
            hasSquareFootprint(piece),
            isFalse,
            reason:
                'Balok ${piece.id} berbentuk sama lebar dan tinggi sehingga '
                'arah geraknya membingungkan',
          );
          for (final cell in pieceCells(piece)) {
            expect(cell.x, inInclusiveRange(0, boardCols - 1));
            expect(cell.y, inInclusiveRange(0, boardRows - 1));
            expect(
              occupied.add(cell.key),
              isTrue,
              reason: 'Balok ${piece.id} bertumpuk di ${cell.key}',
            );
          }
        }

        expect(
          _solveByRemovingEveryAvailablePiece(pieces),
          isTrue,
          reason: 'Level mengalami deadlock dan tidak dapat dikosongkan.',
        );
      });
    }

    test('generation is deterministic', () {
      final first = generateLevel(10, 100);
      final second = generateLevel(10, 100);
      expect(
        first
            .map(
              (piece) =>
                  '${piece.id}:${piece.x}:${piece.y}:${piece.direction}:'
                  '${piece.shape}:${piece.length}',
            )
            .toList(),
        second
            .map(
              (piece) =>
                  '${piece.id}:${piece.x}:${piece.y}:${piece.direction}:'
                  '${piece.shape}:${piece.length}',
            )
            .toList(),
      );
    });
  });

  test('all levels generate within a reasonable budget', () {
    final stopwatch = Stopwatch()..start();
    for (var levelIndex = 0; levelIndex < totalLevels; levelIndex++) {
      generateLevel(levelIndex + 1, levelPieceCount(levelIndex));
    }
    stopwatch.stop();
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 10)),
      reason: 'Pembuatan level terlalu lambat: ${stopwatch.elapsed}',
    );
  });

  test('new shapes unlock only at their intended levels', () {
    const basic = {PieceShape.i, PieceShape.l, PieceShape.j};
    const middle = {PieceShape.c, PieceShape.u, PieceShape.g};
    const advanced = {
      PieceShape.t,
      PieceShape.f,
      PieceShape.h,
      PieceShape.s,
      PieceShape.e,
    };

    expect(shapesForLevel(1).toSet(), equals(basic));
    expect(shapesForLevel(3).toSet(), equals(basic));
    expect(shapesForLevel(4).toSet(), containsAll({...basic, ...middle}));
    expect(shapesForLevel(7).toSet(), isNot(containsAll(advanced)));
    expect(
      shapesForLevel(8).toSet(),
      containsAll({...basic, ...middle, ...advanced}),
    );
    expect(shapesForLevel(10).toSet(), containsAll(advanced));
  });
}
