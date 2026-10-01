// Prints a summary of PINBALL.DAT, for analysis and verification.
//
//   dart run tool/dat_info.dart [path/to/PINBALL.DAT]
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:space_cadet/dat/pinball_data.dart';

void main(List<String> args) {
  final path = args.isEmpty ? 'original/PINBALL.DAT' : args.first;
  final data = PinballData.parse(File(path).readAsBytesSync());
  final dat = data.dat;
  print('${dat.appName} — ${dat.description}: ${dat.groups.length} groups');
  print(
    'screen ${data.screenSize}  table sprite '
    '${data.tableBitmap.width}×${data.tableBitmap.height} '
    'offset ${data.spriteOffset}',
  );
  final c = data.camera;
  print(
    'camera d=${c.d} center=(${c.centerX}, ${c.centerY}) '
    'zMin=${c.zMin} zScaler=${c.zScaler}\n  matrix=${c.matrix}',
  );
  print('gravity ${data.gravity}  gravityMult ${data.gravityMult}');
  print(
    'ball radius ${data.ballRadius}, ${data.ballSprites.length} sprites: '
    '${data.ballSprites.map((s) => '${s.$1.width}px@${s.$2}').join(', ')}',
  );
  print('table walls ${data.tableWalls.map(_wall).join(' ')}');
  for (final comp in data.components) {
    if (comp.type.name.startsWith('light') || comp.type.name == 'sound') {
      continue;
    }
    final s = comp.states.first;
    final bmp = s.bitmap;
    print(
      '${comp.type.name.padRight(14)} ${(comp.name ?? '#${comp.group}').padRight(14)}'
      ' states ${comp.states.length}'
      '${bmp == null ? '' : '  sprite ${bmp.width}×${bmp.height}@(${bmp.x},${bmp.y})'}'
      '  e=${s.material.elasticity.toStringAsFixed(2)} '
      's=${s.material.smoothness.toStringAsFixed(2)}'
      '${s.kicker.boost != 0 ? ' boost=${s.kicker.boost} thr=${s.kicker.threshold}' : ''}'
      '  mask=${s.collisionMask}  ${s.walls.map(_wall).join(' ')}',
    );
  }
}

String _wall(WallShape w) => switch (w) {
  WallCircle(:final x, :final y, :final radius) =>
    'circle(${x.toStringAsFixed(2)},${y.toStringAsFixed(2)} r${radius.toStringAsFixed(2)})',
  WallLine(:final x1, :final y1, :final x2, :final y2) =>
    'line(${x1.toStringAsFixed(2)},${y1.toStringAsFixed(2)}→${x2.toStringAsFixed(2)},${y2.toStringAsFixed(2)})',
  WallPolygon() => 'poly${w.length}',
};
