import 'dart:math' as math;
import 'dart:typed_data';

import 'dat_bitmap.dart';
import 'dat_file.dart';

/// Component types, as listed in the `table_objects` group.
enum ComponentType {
  wall(1000),
  plunger(1001),
  light(1002),
  flipperLeft(1003),
  flipperRight(1004),
  bumper(1005),
  popupTarget(1006),
  drain(1007),
  wall2(1010),
  blocker(1011),
  kickout(1012),
  gate(1013),
  kickback(1014),
  rollover(1015),
  oneway(1016),
  sink(1017),
  flagSpinner(1018),
  soloTarget(1019),
  lightRollover(1020),
  ramp(1021),
  hole(1022),
  demo(1023),
  tripwire(1024),
  lightGroup(1026),
  componentGroup(1028),
  kickoutNoLight(1029),
  lightBargraph(1030),
  sound(1031),
  timer(1032),
  textBox(1033);

  const ComponentType(this.code);
  final int code;

  static final _byCode = {for (final t in values) t.code: t};
  static ComponentType? fromCode(int code) => _byCode[code];

  bool get isWall => this == wall || this == wall2;
}

/// Collision geometry in table space.
sealed class WallShape {
  const WallShape();
}

class WallCircle extends WallShape {
  const WallCircle(this.x, this.y, this.radius);
  final double x, y, radius;
}

class WallLine extends WallShape {
  const WallLine(this.x1, this.y1, this.x2, this.y2);
  final double x1, y1, x2, y2;
}

/// Closed polygon; [points] is x0, y0, x1, y1, … without the repeated
/// first point.
class WallPolygon extends WallShape {
  const WallPolygon(this.points);
  final List<double> points;
  int get length => points.length ~/ 2;
}

/// Surface material. Defaults are the original's (`loader::default_vsi`).
class Material {
  const Material({this.smoothness = 0.95, this.elasticity = 0.6});
  final double smoothness;
  final double elasticity;
}

/// Kicker parameters: what a component does to the ball on a hard hit.
class Kicker {
  const Kicker({
    this.threshold = 9e10,
    this.boost = 0,
    this.throwBallMult,
    this.throwBallAngleMult,
    this.throwBallDirection,
  });
  final double threshold;
  final double boost;
  final double? throwBallMult;
  final double? throwBallAngleMult;
  final (double, double, double)? throwBallDirection;
}

/// One visual state of a component: its sprite and its physics.
class VisualState {
  const VisualState({
    required this.group,
    this.bitmap,
    this.zMap,
    this.walls = const [],
    this.material = const Material(),
    this.kicker = const Kicker(),
    this.collisionMask = 1,
  });

  final int group;
  final Bitmap8? bitmap;
  final ZMap? zMap;
  final List<WallShape> walls;
  final Material material;
  final Kicker kicker;
  final int collisionMask;
}

class Component {
  Component({
    required this.type,
    required this.group,
    required this.name,
    required this.states,
    this.attributes = const {},
  });

  final ComponentType type;
  final int group;
  final String? name;
  final List<VisualState> states;

  /// Float attributes of the first state, by code, without the code
  /// itself (e.g. 407 = timer, 601 = ball position, 1300 = ramp planes).
  final Map<int, List<double>> attributes;
}

/// The perspective camera from `camera_info` plus the projection centre
/// from the `table` group (attribute 700).
class CameraInfo {
  const CameraInfo({
    required this.matrix,
    required this.d,
    required this.zMin,
    required this.zScaler,
    required this.centerX,
    required this.centerY,
  });

  /// 3 × 4, row-major.
  final List<double> matrix;
  final double d, zMin, zScaler, centerX, centerY;
}

/// PINBALL.DAT interpreted: components, geometry, camera, art.
///
/// Mirrors the decompilation's `loader` semantics:
/// - a component's group carries ShortValue 200; extra visual states follow
///   it directly, each carrying ShortValue 201;
/// - the state count is ShortArray `[100, n, …]`;
/// - attributes are FloatArrays keyed by their first value (600 = walls,
///   500 = ball radius, 305 = gravity, …).
class PinballData {
  PinballData._(this.dat);

  final DatFile dat;

  static PinballData parse(Uint8List bytes) =>
      PinballData._(DatFile.parse(bytes));

  late final Palette palette = Palette.fromEntry(
    dat.byName('background')!.field(DatFieldType.palette)!,
  );

  /// The virtual screen: `table_size`, 600 × 416.
  late final (int, int) screenSize = () {
    final s = dat.byName('table_size')!.field(DatFieldType.shortArray)!.shorts;
    return (s[0], s[1]);
  }();

  late final int tableGroup = dat.indexOf('table');

  /// Playfield sprite, drawn at screen (0, 0).
  late final Bitmap8 tableBitmap = bitmap(tableGroup)!;

  /// Scoreboard sprite, drawn at its own (x, y).
  late final Bitmap8 scoreboardBitmap = bitmap(dat.indexOf('background'))!;

  /// Component sprites are drawn at their (x, y) minus this.
  (int, int) get spriteOffset => (tableBitmap.x, tableBitmap.y);

  late final CameraInfo camera = () {
    final f = dat.byName('camera_info')!.field(DatFieldType.floatArray)!.floats;
    final center = floatAttribute(tableGroup, 0, 700)!;
    return CameraInfo(
      matrix: List.unmodifiable(f.sublist(0, 12)),
      d: f[12],
      zMin: f[13],
      zScaler: f[14],
      centerX: center[0],
      centerY: center[1],
    );
  }();

  /// Gravity in table space, as `TTableLayer` computes it from attribute
  /// 305 [magnitude, tilt, direction].
  late final (double, double) gravity = () {
    final a = floatAttribute(tableGroup, 0, 305) ?? [25.0, 0.5, 1.570796];
    final (mult, tilt, dir) = (a[0], a[1], a[2]);
    return (
      math.cos(dir) * math.sin(tilt) * mult,
      math.sin(dir) * math.sin(tilt) * mult,
    );
  }();

  /// Attribute 701: speed-dependent damping in the table's field effect.
  late final double gravityMult = floatAttribute(tableGroup, 0, 701)?[0] ?? 0.2;

  /// The table's own wall: its outer boundary.
  late final List<WallShape> tableWalls = walls(tableGroup, 0);

  late final int ballGroup = dat.indexOf('ball');
  late final double ballRadius = floatAttribute(ballGroup, 0, 500)![0];

  /// Ball sprites by depth: state i is used while its depth is at most the
  /// actual depth (see `TBall::Repaint`). Depth points are table-space
  /// vectors (attribute 501).
  late final List<(Bitmap8, (double, double, double))> ballSprites = [
    for (var i = 0; i < visualStateCount(ballGroup); i++)
      (
        bitmap(stateGroup(ballGroup, i))!,
        () {
          final v = floatAttribute(ballGroup, i, 501)!;
          return (v[0], v[1], v[2]);
        }(),
      ),
  ];

  late final List<Component> components = () {
    final objects = dat.byName('table_objects')!;
    final list = <Component>[];
    for (final entry in objects.fields(DatFieldType.shortArray)) {
      final a = entry.shorts;
      if (a.isEmpty || a[0] != 1025) continue;
      for (var i = 1; i + 1 < a.length; i += 2) {
        final type = ComponentType.fromCode(a[i]);
        if (type == null) {
          throw DatFormatException('unknown component type ${a[i]}');
        }
        list.add(_component(type, a[i + 1]));
      }
    }
    return List<Component>.unmodifiable(list);
  }();

  Component _component(ComponentType type, int group) {
    final count = visualStateCount(group);
    return Component(
      type: type,
      group: group,
      name: dat.groups[group].name,
      states: [for (var s = 0; s < count; s++) _state(group, s)],
      attributes: {
        for (final e in dat.groups[group].fields(DatFieldType.floatArray))
          if (e.floats case final f when f.isNotEmpty)
            f[0].floor(): List.unmodifiable(f.sublist(1)),
      },
    );
  }

  VisualState _state(int group, int state) {
    final g = stateGroup(group, state);
    if (g < 0) return VisualState(group: group);
    var material = const Material();
    var kicker = const Kicker();
    var mask = 0;
    final shorts = dat.groups[g].field(DatFieldType.shortArray)?.shorts;
    if (shorts != null) {
      for (var i = 0; i + 1 < shorts.length;) {
        final (code, value) = (shorts[i], shorts[i + 1]);
        switch (code) {
          case 300:
            material = _material(value);
          case 400:
            kicker = _kicker(value);
          case 602:
            mask |= 1 << value;
          case 1500:
            i += 7;
        }
        i += 2;
      }
    }
    final zEntry = dat.groups[g].field(DatFieldType.zMap);
    return VisualState(
      group: g,
      bitmap: bitmap(g),
      zMap: zEntry == null ? null : ZMap.fromEntry(zEntry),
      walls: walls(group, state),
      material: material,
      kicker: kicker,
      collisionMask: mask == 0 ? 1 : mask,
    );
  }

  Material _material(int group) {
    var smoothness = 0.95, elasticity = 0.6;
    final f = dat.groups[group].field(DatFieldType.floatArray)?.floats;
    if (f != null) {
      for (var i = 0; i + 1 < f.length; i += 2) {
        switch (f[i].floor()) {
          case 301:
            smoothness = f[i + 1];
          case 302:
            elasticity = f[i + 1];
        }
      }
    }
    return Material(smoothness: smoothness, elasticity: elasticity);
  }

  Kicker _kicker(int group) {
    var threshold = 9e10, boost = 0.0;
    double? throwMult, angleMult;
    (double, double, double)? direction;
    final f = dat.groups[group].field(DatFieldType.floatArray)?.floats;
    if (f != null) {
      for (var i = 0; i < f.length;) {
        final code = f[i].floor();
        if (code == 404) {
          direction = (f[i + 1], f[i + 2], f[i + 3]);
          i += 4;
          continue;
        }
        final v = f[i + 1];
        switch (code) {
          case 401:
            threshold = v;
          case 402:
            boost = v;
          case 403:
            throwMult = v;
          case 405:
            angleMult = v;
        }
        i += 2;
      }
    }
    return Kicker(
      threshold: threshold,
      boost: boost,
      throwBallMult: throwMult,
      throwBallAngleMult: angleMult,
      throwBallDirection: direction,
    );
  }

  // --- loader primitives --------------------------------------------------

  /// `[100, n, …]` in the group's ShortArray, else 1.
  int visualStateCount(int group) {
    if (group < 0) return 0;
    final s = dat.groups[group].field(DatFieldType.shortArray)?.shorts;
    return s != null && s.length > 1 && s[0] == 100 ? s[1] : 1;
  }

  /// Group holding visual [state] of [group], or -1.
  int stateGroup(int group, int state) {
    if (group < 0) return -1;
    if (state == 0) return group;
    if (state >= visualStateCount(group)) return -1;
    final g = group + state;
    final v = dat.groups[g].field(DatFieldType.shortValue)?.shortValue;
    return v == 201 ? g : -1;
  }

  /// The FloatArray of state [state] whose first value is [code], without
  /// that first value.
  Float32List? floatAttribute(int group, int state, int code) {
    final g = stateGroup(group, state);
    if (g < 0) return null;
    for (final e in dat.groups[g].fields(DatFieldType.floatArray)) {
      final f = e.floats;
      if (f.isNotEmpty && f[0].floor() == code) return f.sublist(1);
    }
    return null;
  }

  ZMap? zMap(int group) {
    if (group < 0) return null;
    final e = dat.groups[group].field(DatFieldType.zMap);
    return e == null ? null : ZMap.fromEntry(e);
  }

  Bitmap8? bitmap(int group) {
    if (group < 0) return null;
    final e = dat.groups[group].field(DatFieldType.bitmap8);
    return e == null ? null : Bitmap8.fromEntry(e);
  }

  /// Walls (attribute 600) of a visual state, decoded like
  /// `TEdgeSegment::install_wall`: 1 point = circle, 2 = line, more =
  /// closed polygon whose last point repeats the first.
  List<WallShape> walls(int group, int state) {
    final f = floatAttribute(group, state, 600);
    if (f == null || f.isEmpty) return const [];
    final n = f[0].floor();
    switch (n) {
      case 1:
        return [WallCircle(f[1], f[2], f[3])];
      case 2:
        return [WallLine(f[1], f[2], f[3], f[4])];
      default:
        return [WallPolygon(List.unmodifiable(f.sublist(1, 1 + 2 * (n - 1))))];
    }
  }
}
