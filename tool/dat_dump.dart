// Dumps the raw entries of named groups (and their extra visual states).
//
//   dart run tool/dat_dump.dart a_flip1 plunger …
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:space_cadet/dat/dat_file.dart';
import 'package:space_cadet/dat/pinball_data.dart';

void main(List<String> names) {
  final data = PinballData.parse(
    File('original/PINBALL.DAT').readAsBytesSync(),
  );
  for (final name in names) {
    final g = data.dat.indexOf(name);
    if (g < 0) {
      print('$name: not found');
      continue;
    }
    final states = data.visualStateCount(g);
    for (var s = 0; s < states; s++) {
      final sg = data.stateGroup(g, s);
      if (sg < 0) continue;
      print('$name state $s (group $sg)');
      for (final e in data.dat.groups[sg].entries) {
        final v = switch (e.type) {
          DatFieldType.shortValue => '${e.shortValue}',
          DatFieldType.shortArray => '${e.shorts}',
          DatFieldType.floatArray =>
            '${e.floats.map((f) => f.toStringAsFixed(3)).toList()}',
          DatFieldType.groupName || DatFieldType.string => e.text,
          _ => '${e.length} bytes',
        };
        print('  ${e.type.name}: $v');
      }
    }
  }
}
