import 'dart:math' as math;

const int boardCols = 28;
const int boardRows = 42;

enum PieceShape { i, l, j, t, f, z }

class GridCell {
  const GridCell(this.x, this.y);
  final int x;
  final int y;

  String get key => '$x,$y';
}

class PuzzlePiece {
  PuzzlePiece({
    required this.id,
    required this.x,
    required this.y,
    required this.direction,
    required this.shape,
    required this.length,
    required this.colorIndex,
  });

  final String id;
  int x;
  int y;
  final int direction;
  final PieceShape shape;
  final int length;
  final int colorIndex;

  bool get horizontal => direction == 0 || direction == 180;

  PuzzlePiece copy() => PuzzlePiece(
    id: id,
    x: x,
    y: y,
    direction: direction,
    shape: shape,
    length: length,
    colorIndex: colorIndex,
  );
}

List<GridCell> _baseCells(PieceShape shape, int length) {
  final line = List.generate(length, (index) => GridCell(index, 0));
  final mid = math.max(1, (length - 1) ~/ 2);
  return switch (shape) {
    PieceShape.i => line,
    PieceShape.l => [...line, GridCell(length - 1, 1)],
    PieceShape.j => [const GridCell(0, 1), ...line],
    PieceShape.t => [...line, GridCell(mid, 1)],
    PieceShape.f => [
      ...line,
      GridCell(mid, 1),
      GridCell(math.min(length - 1, mid + 1), 1),
    ],
    PieceShape.z => [
      ...line,
      GridCell(mid, -1),
      GridCell(math.max(0, mid - 1), 1),
    ],
  };
}

GridCell _rotate(GridCell cell, int direction) => switch (direction) {
  0 => cell,
  90 => GridCell(-cell.y, cell.x),
  180 => GridCell(-cell.x, -cell.y),
  _ => GridCell(cell.y, -cell.x),
};

List<GridCell> pieceCells(PuzzlePiece piece, {int dx = 0, int dy = 0}) {
  return _baseCells(piece.shape, piece.length).map((cell) {
    final rotated = _rotate(cell, piece.direction);
    return GridCell(piece.x + rotated.x + dx, piece.y + rotated.y + dy);
  }).toList();
}

class _Lcg {
  _Lcg(this.seed);
  int seed;

  double next() {
    seed = (seed * 1664525 + 1013904223) & 0xffffffff;
    return seed / 4294967296;
  }
}

const _shapeOrder = [
  PieceShape.i,
  PieceShape.l,
  PieceShape.j,
  PieceShape.t,
  PieceShape.f,
  PieceShape.z,
  PieceShape.l,
  PieceShape.t,
];

List<PuzzlePiece> generateLevel(int seedLevel, int requestedCount) {
  final random = _Lcg(5849 + seedLevel * 941);
  var best = <PuzzlePiece>[];
  for (
    var restart = 0;
    restart < 80 && best.length < requestedCount;
    restart++
  ) {
    final pieces = <PuzzlePiece>[];
    final used = <String>{};
    for (var index = 0; index < requestedCount; index++) {
      final shape = _shapeOrder[(index + seedLevel) % _shapeOrder.length];
      final length = shape == PieceShape.i
          ? 2 + ((index + seedLevel) % 6)
          : 3 + ((index * 3 + seedLevel) % 5);
      var placed = false;
      for (var attempt = 0; attempt < 700 && !placed; attempt++) {
        final x = (random.next() * boardCols).floor();
        final y = (random.next() * boardRows).floor();
        final horizontal = random.next() > .5;
        final direction = horizontal
            ? (x < boardCols / 2 ? 180 : 0)
            : (y < boardRows / 2 ? 270 : 90);
        final probe = PuzzlePiece(
          id: '$seedLevel-$index',
          x: x,
          y: y,
          direction: direction,
          shape: shape,
          length: length,
          colorIndex: (index + seedLevel) % 7,
        );
        final own = pieceCells(probe);
        if (own.any(
          (cell) =>
              cell.x < 0 ||
              cell.x >= boardCols ||
              cell.y < 0 ||
              cell.y >= boardRows ||
              used.contains(cell.key),
        )) {
          continue;
        }
        used.addAll(own.map((cell) => cell.key));
        pieces.add(probe);
        placed = true;
      }
      if (!placed) break;
    }
    if (pieces.length > best.length) best = pieces;
  }
  return best;
}

int levelPieceCount(int levelIndex) {
  return 8 + (((levelIndex + 3) * 92) / 19).round();
}

class PuzzleEngine {
  PuzzleEngine(List<PuzzlePiece> source)
    : pieces = source.map((piece) => piece.copy()).toList();

  final List<PuzzlePiece> pieces;

  Set<String> occupiedExcept(PuzzlePiece ignored) {
    return {
      for (final piece in pieces)
        if (piece.id != ignored.id)
          for (final cell in pieceCells(piece)) cell.key,
    };
  }

  bool canPlace(
    PuzzlePiece piece,
    int dx,
    int dy, {
    bool allowOutside = false,
  }) {
    final occupied = occupiedExcept(piece);
    for (final cell in pieceCells(piece, dx: dx, dy: dy)) {
      final inside =
          cell.x >= 0 &&
          cell.x < boardCols &&
          cell.y >= 0 &&
          cell.y < boardRows;
      if (!inside && !allowOutside) return false;
      if (inside && occupied.contains(cell.key)) return false;
    }
    return true;
  }

  int maxTravel(PuzzlePiece piece, int sign) {
    final limit = piece.horizontal
        ? boardCols + piece.length
        : boardRows + piece.length;
    var step = 0;
    for (var candidate = 1; candidate <= limit; candidate++) {
      final dx = piece.horizontal ? candidate * sign : 0;
      final dy = piece.horizontal ? 0 : candidate * sign;
      if (!canPlace(piece, dx, dy, allowOutside: true)) break;
      step = candidate;
      if (pieceCells(piece, dx: dx, dy: dy).every(
        (cell) =>
            cell.x < 0 ||
            cell.x >= boardCols ||
            cell.y < 0 ||
            cell.y >= boardRows,
      )) {
        break;
      }
    }
    return step;
  }

  bool isOutside(PuzzlePiece piece, int delta) {
    final dx = piece.horizontal ? delta : 0;
    final dy = piece.horizontal ? 0 : delta;
    return pieceCells(piece, dx: dx, dy: dy).every(
      (cell) =>
          cell.x < 0 ||
          cell.x >= boardCols ||
          cell.y < 0 ||
          cell.y >= boardRows,
    );
  }

  void commit(PuzzlePiece piece, int delta) {
    if (piece.horizontal) {
      piece.x += delta;
    } else {
      piece.y += delta;
    }
  }
}
