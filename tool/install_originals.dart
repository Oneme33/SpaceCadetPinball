// Copies the user's own original game files into assets/original/, where
// the game loads them from. That folder is git-ignored: the files are
// Microsoft/Cinematronics property and must never be committed.
//
//   dart run tool/install_originals.dart [source-folder]   (default: original/)
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:space_cadet/dat/pinball_data.dart';

void main(List<String> args) {
  final source = Directory(args.isEmpty ? 'original' : args.first);
  final target = Directory('assets/original')..createSync(recursive: true);
  File? find(String name) {
    for (final e in source.listSync()) {
      if (e is File &&
          e.uri.pathSegments.last.toUpperCase() == name.toUpperCase()) {
        return e;
      }
    }
    return null;
  }

  final dat = find('PINBALL.DAT');
  if (dat == null) {
    stderr.writeln('PINBALL.DAT not found in ${source.path}');
    exit(1);
  }
  // Fails loudly on a damaged or wrong file instead of at game start.
  final data = PinballData.parse(dat.readAsBytesSync());
  print(
    'PINBALL.DAT ok: ${data.dat.groups.length} groups, '
    '${data.components.length} components',
  );

  var copied = 0;
  for (final e in source.listSync()) {
    if (e is! File) continue;
    final name = e.uri.pathSegments.last.toUpperCase();
    if (name == 'PINBALL.DAT' || name == 'FONT.DAT' || name.endsWith('.WAV')) {
      e.copySync('${target.path}/$name');
      copied++;
    }
  }
  print('Copied $copied files to ${target.path}/');
}
