import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/dat/pinball_data.dart';
import 'package:space_cadet/game/physics/physics_world.dart';
import 'package:space_cadet/game/table/parts/light_part.dart';
import 'package:space_cadet/game/table/space_cadet_table.dart';
import 'package:space_cadet/game/table/table_layout.dart';

/// `TLight` behaviour on a real light. Skipped without the DAT.
void main() {
  final file = File('assets/original/PINBALL.DAT');
  final skip = file.existsSync() ? null : 'original PINBALL.DAT not installed';
  setUpAll(PhysicsWorld.initialize);

  group('light', skip: skip, () {
    late PhysicsWorld physics;
    late SpaceCadetTable table;
    late LightPart light;

    setUp(() {
      final layout = TableLayout.fromData(
        PinballData.parse(file.readAsBytesSync()),
      );
      physics = PhysicsWorld(gravity: layout.gravity);
      table = SpaceCadetTable(physics, layout);
      light = table.light('lite84')!;
    });

    tearDown(() => physics.destroy());

    void run(double s) {
      for (var t = 0.0; t < s; t += 1 / 120) {
        physics.advance(1 / 120);
      }
    }

    test('all 140 lights exist and start off', () {
      final lights = table.parts.whereType<LightPart>().toList();
      expect(lights, hasLength(140));
      expect(lights.every((l) => l.frame == -1 && !l.isLit), isTrue);
    });

    test('on and off', () {
      light.turnOn();
      expect(light.frame, 0);
      light.turnOff();
      expect(light.frame, -1);
    });

    test('timed on returns to the steady state', () {
      light.turnOnTimed(0.1);
      expect(light.frame, 0);
      run(0.15);
      expect(light.frame, -1);
    });

    test('the flasher alternates and stops after its time', () {
      final frames = <int>{};
      light.flasherStartTimed(1);
      for (var i = 0; i < 100; i++) {
        physics.advance(1 / 120);
        frames.add(light.frame);
      }
      expect(frames, containsAll([0, -1]));
      run(0.5);
      expect(light.flasherOn, isFalse);
      expect(light.frame, -1);
    });

    test('flash then stay on', () {
      light.flasherStartTimedThenStayOn(0.5);
      run(0.6);
      expect(light.frame, 0);
      expect(light.lightOn, isTrue);
    });

    test('flash then stay off', () {
      light
        ..turnOn()
        ..flasherStartTimedThenStayOff(0.5);
      run(0.6);
      expect(light.frame, -1);
      expect(light.lightOn, isFalse);
    });
  });
}
