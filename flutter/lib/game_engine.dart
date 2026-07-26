import 'dart:math' as math;

const int boardCols = 28;
const int boardRows = 42;
const int totalLevels = 10;

enum PieceShape { i, l, j, c, u, g, t, f, h, s, e }

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
  List<GridCell> row(int y, {int from = 0, int? to}) => [
    for (var x = from; x <= (to ?? length - 1); x++) GridCell(x, y),
  ];

  List<GridCell> column(int x, int from, int to) => [
    for (var y = from; y <= to; y++) GridCell(x, y),
  ];

  final line = row(0);
  final mid = math.max(1, (length - 1) ~/ 2);
  return switch (shape) {
    PieceShape.i => line,
    PieceShape.l => [...line, GridCell(length - 1, 1)],
    PieceShape.j => [const GridCell(0, 1), ...line],
    PieceShape.c => [...row(0), const GridCell(0, 1), ...row(2)],
    PieceShape.u => [
      ...column(0, 0, 1),
      ...column(length - 1, 0, 1),
      ...row(2),
    ],
    PieceShape.g => [
      ...row(0),
      const GridCell(0, 1),
      ...row(2),
      GridCell(length - 1, 1),
      GridCell(math.max(1, length - 2), 1),
    ],
    PieceShape.t => [...line, GridCell(mid, 1)],
    PieceShape.f => [
      ...row(0),
      ...row(2, from: 1, to: math.max(1, length - 2)),
      ...column(0, 1, 4),
    ],
    PieceShape.h => [
      ...column(0, 0, 4),
      ...column(length - 1, 0, 4),
      ...row(2, from: 1, to: length - 2),
    ],
    PieceShape.s => [
      ...row(0, from: 1),
      GridCell(length - 1, 1),
      ...row(2),
      const GridCell(0, 3),
      ...row(4, to: length - 2),
    ],
    PieceShape.e => [
      ...row(0),
      ...row(2),
      ...row(4),
      const GridCell(0, 1),
      const GridCell(0, 3),
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

bool hasSquareFootprint(PuzzlePiece piece) {
  final cells = pieceCells(piece);
  final width =
      cells.map((cell) => cell.x).reduce(math.max) -
      cells.map((cell) => cell.x).reduce(math.min) +
      1;
  final height =
      cells.map((cell) => cell.y).reduce(math.max) -
      cells.map((cell) => cell.y).reduce(math.min) +
      1;
  return width == height;
}

class _Lcg {
  _Lcg(this.seed);
  int seed;

  double next() {
    seed = (seed * 1664525 + 1013904223) & 0xffffffff;
    return seed / 4294967296;
  }
}

const _basicShapeOrder = [
  PieceShape.i,
  PieceShape.i,
  PieceShape.l,
  PieceShape.j,
  PieceShape.i,
  PieceShape.l,
  PieceShape.i,
  PieceShape.j,
];

const _middleShapeOrder = [
  ..._basicShapeOrder,
  PieceShape.i,
  PieceShape.l,
  PieceShape.j,
  PieceShape.c,
  PieceShape.u,
  PieceShape.g,
];

const _advancedShapeOrder = [
  ..._middleShapeOrder,
  ..._basicShapeOrder,
  PieceShape.t,
  PieceShape.f,
  PieceShape.h,
  PieceShape.s,
  PieceShape.e,
];

List<PieceShape> shapesForLevel(int levelNumber) {
  final safeLevel = levelNumber.clamp(1, totalLevels);
  if (safeLevel <= 3) return _basicShapeOrder;
  if (safeLevel <= 7) return _middleShapeOrder;
  return _advancedShapeOrder;
}

int _lengthForShape(PieceShape shape, int index, int levelNumber) {
  var length = switch (shape) {
    PieceShape.i => 2 + ((index + levelNumber) % 6),
    PieceShape.l || PieceShape.j => 3 + ((index * 3 + levelNumber) % 4),
    _ => 3 + ((index + levelNumber) % 2),
  };
  final shapeCheck = PuzzlePiece(
    id: 'shape-check',
    x: 0,
    y: 0,
    direction: 0,
    shape: shape,
    length: length,
    colorIndex: 0,
  );
  if (hasSquareFootprint(shapeCheck)) {
    length = shape == PieceShape.g ? length + 1 : math.max(2, length - 1);
  }
  return length;
}

PuzzlePiece? _enterFromEdge({
  required String id,
  required PieceShape shape,
  required int length,
  required int colorIndex,
  required Set<String> occupied,
  required _Lcg random,
}) {
  final direction = switch ((random.next() * 4).floor()) {
    0 => 0,
    1 => 90,
    2 => 180,
    _ => 270,
  };
  final origin = PuzzlePiece(
    id: id,
    x: 0,
    y: 0,
    direction: direction,
    shape: shape,
    length: length,
    colorIndex: colorIndex,
  );
  final relative = pieceCells(origin);
  final minX = relative.map((cell) => cell.x).reduce(math.min);
  final maxX = relative.map((cell) => cell.x).reduce(math.max);
  final minY = relative.map((cell) => cell.y).reduce(math.min);
  final maxY = relative.map((cell) => cell.y).reduce(math.max);
  final fromLowSide = random.next() > .5;

  var x = 0;
  var y = 0;
  var stepX = 0;
  var stepY = 0;
  if (origin.horizontal) {
    final minAnchorY = -minY;
    final maxAnchorY = boardRows - 1 - maxY;
    if (maxAnchorY < minAnchorY) return null;
    y = minAnchorY + (random.next() * (maxAnchorY - minAnchorY + 1)).floor();
    x = fromLowSide ? -maxX - 1 : boardCols - minX;
    stepX = fromLowSide ? 1 : -1;
  } else {
    final minAnchorX = -minX;
    final maxAnchorX = boardCols - 1 - maxX;
    if (maxAnchorX < minAnchorX) return null;
    x = minAnchorX + (random.next() * (maxAnchorX - minAnchorX + 1)).floor();
    y = fromLowSide ? -maxY - 1 : boardRows - minY;
    stepY = fromLowSide ? 1 : -1;
  }

  PuzzlePiece? deepest;
  final travelLimit = boardCols + boardRows + length + 12;
  for (var step = 0; step < travelLimit; step++) {
    final probe = PuzzlePiece(
      id: id,
      x: x,
      y: y,
      direction: direction,
      shape: shape,
      length: length,
      colorIndex: colorIndex,
    );
    final cells = pieceCells(probe);
    final collides = cells.any((cell) {
      final inside =
          cell.x >= 0 &&
          cell.x < boardCols &&
          cell.y >= 0 &&
          cell.y < boardRows;
      return inside && occupied.contains(cell.key);
    });
    if (collides) break;

    final fullyInside = cells.every(
      (cell) =>
          cell.x >= 0 &&
          cell.x < boardCols &&
          cell.y >= 0 &&
          cell.y < boardRows,
    );
    if (fullyInside) deepest = probe;

    final completelyPastBoard = origin.horizontal
        ? (fromLowSide
              ? cells.every((cell) => cell.x >= boardCols)
              : cells.every((cell) => cell.x < 0))
        : (fromLowSide
              ? cells.every((cell) => cell.y >= boardRows)
              : cells.every((cell) => cell.y < 0));
    if (completelyPastBoard) break;
    x += stepX;
    y += stepY;
  }
  return deepest;
}

List<PuzzlePiece> generateLevel(int levelNumber, int requestedCount) {
  final safeLevel = levelNumber.clamp(1, totalLevels);
  final shapeOrder = shapesForLevel(safeLevel);
  final random = _Lcg(5849 + safeLevel * 941);
  var best = <PuzzlePiece>[];
  for (
    var restart = 0;
    restart < 80 && best.length < requestedCount;
    restart++
  ) {
    final pieces = <PuzzlePiece>[];
    final used = <String>{};
    for (var index = 0; index < requestedCount; index++) {
      final preferredShape =
          shapeOrder[(index + safeLevel) % shapeOrder.length];
      var placed = false;
      final candidates = preferredShape == PieceShape.i
          ? const [PieceShape.i]
          : [preferredShape, PieceShape.i];
      for (final shape in candidates) {
        final length = shape == preferredShape
            ? _lengthForShape(shape, index, safeLevel)
            : 2 + ((index + safeLevel) % 3);
        for (var attempt = 0; attempt < 700 && !placed; attempt++) {
          final probe = _enterFromEdge(
            id: '$safeLevel-$index',
            shape: shape,
            length: length,
            colorIndex: (index + safeLevel) % 7,
            occupied: used,
            random: random,
          );
          if (probe == null) continue;
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
        if (placed) break;
      }
      if (!placed) break;
    }
    if (pieces.length > best.length) best = pieces;
  }
  return best;
}

int levelPieceCount(int levelIndex) {
  final safeIndex = levelIndex.clamp(0, totalLevels - 1);
  return 23 + ((safeIndex * 77) / (totalLevels - 1)).round();
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
