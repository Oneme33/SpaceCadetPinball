import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/dat/dat_file.dart';
import 'package:space_cadet/dat/msg_font.dart';
import 'package:space_cadet/dat/pinball_data.dart';
import 'package:space_cadet/game/table/camera_projection.dart';
import 'package:space_cadet/game/ui/cadet_car.dart';

/// Runs against the user's own PINBALL.DAT. Skipped when it is not
/// installed, because the file is not in the repository.
void main() {
  final file = File('assets/original/PINBALL.DAT');
  final skip = file.existsSync() ? null : 'original PINBALL.DAT not installed';
  late PinballData data;

  setUpAll(() {
    if (skip == null) data = PinballData.parse(file.readAsBytesSync());
  });

  test('rejects files that are not a PINBALL.DAT', () {
    expect(
      () => DatFile.parse(Uint8List(200)),
      throwsA(isA<DatFormatException>()),
    );
  });

  group('original PINBALL.DAT', skip: skip, () {
    test('header and screen', () {
      expect(data.dat.description, 'Space Cadet Table');
      expect(data.dat.groups, hasLength(541));
      expect(data.screenSize, (600, 416));
      expect(data.spriteOffset, (137, 2));
    });

    test('component list', () {
      final count = <ComponentType, int>{};
      for (final c in data.components) {
        count[c.type] = (count[c.type] ?? 0) + 1;
      }
      expect(data.components, hasLength(340));
      expect(count[ComponentType.bumper], 7);
      expect(count[ComponentType.popupTarget], 9);
      expect(count[ComponentType.soloTarget], 13);
      expect(count[ComponentType.sink], 4);
      expect(count[ComponentType.flipperLeft], 1);
      expect(count[ComponentType.flipperRight], 1);
      expect(count[ComponentType.plunger], 1);
      expect(count[ComponentType.drain], 1);
    });

    test('physics constants', () {
      expect(data.ballRadius, closeTo(0.3, 1e-6));
      expect(data.gravity.$1, closeTo(0, 1e-4));
      expect(data.gravity.$2, closeTo(25 * 0.479426, 1e-3));
      expect(data.gravityMult, closeTo(0.2, 1e-6));
      expect(data.ballSprites, hasLength(7));
    });

    test('bumpers are circles with a kicker', () {
      for (final b in data.components.where(
        (c) => c.type == ComponentType.bumper,
      )) {
        final s = b.states.first;
        expect(s.walls.single, isA<WallCircle>());
        expect(s.kicker.boost, greaterThan(0));
      }
    });

    test('every wall lies on the table', () {
      final poly = data.tableWalls.single as WallPolygon;
      expect(poly.points, [8, 15, -8, 15, -8, -14, 8, -14]);
      for (final c in data.components) {
        if (c.type == ComponentType.drain) continue; // spans the full width
        for (final w in c.states.expand((s) => s.walls)) {
          final pts = switch (w) {
            WallCircle(:final x, :final y) => [x, y],
            WallLine(:final x1, :final y1, :final x2, :final y2) => [
              x1,
              y1,
              x2,
              y2,
            ],
            WallPolygon(:final points) => points,
          };
          for (var i = 0; i < pts.length; i += 2) {
            expect(pts[i].abs(), lessThanOrEqualTo(8.5), reason: '${c.name}');
            expect(pts[i + 1], inInclusiveRange(-14.5, 15.5));
          }
        }
      }
    });

    test('camera puts the playfield on the table sprite', () {
      final cam = CameraProjection(data.camera);
      final t = data.tableBitmap;
      for (final (x, y) in [
        (8.0, 15.0),
        (-8.0, 15.0),
        (-8.0, -14.0),
        (8.0, -14.0),
      ]) {
        final p = cam.toScreen(x, y);
        expect(p.dx, inInclusiveRange(0, t.width), reason: '($x, $y)');
        expect(p.dy, inInclusiveRange(0, t.height), reason: '($x, $y)');
      }
      // +x is screen left, +y (drain) is screen down.
      expect(cam.toScreen(8, 0).dx, lessThan(cam.toScreen(-8, 0).dx));
      expect(cam.toScreen(0, 15).dy, greaterThan(cam.toScreen(0, -14).dy));
    });

    test('camera inverse maps back onto the table plane', () {
      final cam = CameraProjection(data.camera);
      for (final (x, y) in [(0.0, 0.0), (5.5, -10.0), (-7.0, 13.0)]) {
        final (bx, by) = cam.toTable(cam.toScreen(x, y));
        expect(bx, closeTo(x, 1e-3));
        expect(by, closeTo(y, 1e-3));
      }
    });

    test('depth map hides a ball under a ramp but not on open floor', () {
      final cam = CameraProjection(data.camera);
      final zmap = data.zMap(data.tableGroup)!;
      final c = data.camera;
      int norm(double d) =>
          d < c.zMin ? 0 : ((d - c.zMin) * c.zScaler).clamp(0, 0xFFFF).toInt();
      // Share of the ball's 5×5 centre pixels the table is in front of.
      double hidden(double x, double y) {
        final r = data.ballRadius;
        final p = cam.toScreen3(x, y, r);
        final depth = norm(cam.depth(x, y, r));
        var n = 0;
        for (var dy = -2; dy <= 2; dy++) {
          for (var dx = -2; dx <= 2; dx++) {
            if (zmap.at(p.dx.round() + dx, p.dy.round() + dy) <= depth) n++;
          }
        }
        return n / 25;
      }

      // Under the left ramp (planes up to z 1.3 around (3.5, -0.5)).
      expect(hidden(3.6, -0.6), greaterThan(0.5));
      // Open floor between the flippers' inlanes and on the main field.
      expect(hidden(0, 9), lessThan(0.1));
      expect(hidden(-2, -4), lessThan(0.1));
    });

    test('the cadet car is cut out without the logo or the stars', () {
      final car = CadetCar.fromScoreboard(data.scoreboardBitmap, data.palette);
      expect(car.contains(120, 120), isTrue, reason: 'car body');
      expect(car.contains(140, 70), isTrue, reason: 'helmet');
      expect(car.contains(135, 95), isTrue, reason: 'cadet');
      // The "e" of "Space" behind the dome, and the "Cadet" letters.
      var letters = 0;
      for (var y = CadetCar.top; y < 60; y++) {
        for (var x = 80; x < 110; x++) {
          if (car.contains(x, y)) letters++;
        }
      }
      expect(letters, lessThan(15));
      // Stars on the right, away from the car.
      expect(car.contains(190, 130), isFalse);
      // The see-through dome: glass where the letters show through, and
      // its rim along the grey line in the art.
      expect(CadetCar.inDome(140, 60), isTrue);
      expect(CadetCar.inDome(100, 50), isFalse);
      expect(CadetCar.domeDistance(140, 53).abs(), lessThan(1.5));
      expect(CadetCar.domeDistance(112, 60).abs(), lessThan(1.5));
      final rim = car.rimColor;
      expect((rim >> 24 & 0xff) - (rim >> 8 & 0xff), lessThan(30));
    });

    test('the plunger lane is on the right of the screen', () {
      final cam = CameraProjection(data.camera);
      final plunger = data.components.firstWhere(
        (c) => c.type == ComponentType.plunger,
      );
      final line = plunger.states.first.walls.single as WallLine;
      final p = cam.toScreen(line.x1, line.y1);
      expect(p.dx, greaterThan(data.tableBitmap.width * 0.75));
    });
  });

  group(
    'message font',
    () {
      final file = File('assets/original/PB_MSGFT.bin');
      test('reads the bitmap font and wraps as TTextBox does', () {
        final font = MsgFont.parse(file.readAsBytesSync());
        expect(font.glyphs.keys, containsAll([32, 65, 97, 122]));
        expect(font.height, greaterThan(8));
        const text = 'Hit Mission Targets To Select Mission';
        final lines = font.layout(text, 180, 200);
        expect(lines.length, greaterThan(1), reason: 'wraps in a narrow box');
        // Lines break at spaces, so every line starts at a word.
        for (final (start, _) in lines) {
          expect(start == 0 || text[start - 1] == ' ', isTrue);
        }
        // A box only one line high shows one line.
        expect(font.layout(text, 180, font.height), hasLength(1));
      });
    },
    skip: File('assets/original/PB_MSGFT.bin').existsSync()
        ? null
        : 'PB_MSGFT.bin not installed',
  );
}
