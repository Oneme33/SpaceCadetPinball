// Builds the HD graphics: every bitmap in PINBALL.DAT, upscaled 4× with
// Real-ESRGAN into assets/original/hd/ (git-ignored, like the originals it
// is made from). The table and its parts use the general model
// (realesrgan-x4plus); the scoreboard's cartoon art uses the anime model,
// which keeps its logo and the cadet crisp. Score digits are not used in
// HD: they stay classic.
//
//   dart run tool/make_hd.dart --esrgan path/to/realesrgan-ncnn-vulkan [--python python3]
//
// The lamps and the ball are done by tool/hd_small_sprites.py instead:
// ESRGAN turns a lamp of a few pixels into a rectangle and the small balls
// square. Round lamps are redrawn round, other lamps go through xBRZ, the
// ball keeps its own picture, smoothly scaled and cut to a circle.
//
// Real-ESRGAN: https://github.com/xinntao/Real-ESRGAN (release v0.2.5.0,
// realesrgan-ncnn-vulkan for your platform). The models folder must sit
// next to the executable.
//
// Transparent pixels get the colour of their nearest opaque neighbour
// before upscaling, so edges do not pick up a dark fringe; transparency
// itself is upscaled by the model along with the colours.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:space_cadet/dat/dat_bitmap.dart';
import 'package:space_cadet/dat/dat_file.dart';
import 'package:space_cadet/dat/pinball_data.dart';

const scale = 4;

/// Groups drawn as cartoons rather than rendered 3D: the scoreboard.
const animeGroups = ['background'];

void main(List<String> args) {
  final i = args.indexOf('--esrgan');
  if (i < 0 || i + 1 >= args.length) {
    stderr.writeln('usage: dart run tool/make_hd.dart --esrgan <path>');
    exit(64);
  }
  final esrgan = File(args[i + 1]);
  if (!esrgan.existsSync()) {
    stderr.writeln('${esrgan.path} not found');
    exit(66);
  }

  final data = PinballData.parse(
    File('original/PINBALL.DAT').readAsBytesSync(),
  );
  final src = Directory('build/hd/src')..createSync(recursive: true);
  final out = Directory('build/hd/out')..createSync(recursive: true);
  for (final f in [...src.listSync(), ...out.listSync()]) {
    f.deleteSync();
  }

  var count = 0;
  for (final g in data.dat.groups) {
    final e = g.field(DatFieldType.bitmap8);
    if (e == null) continue;
    final b = Bitmap8.fromEntry(e);
    if (b.width == 0 || b.height == 0) continue;
    File('${src.path}/g${g.index}.png')
        .writeAsBytesSync(img.encodePng(_bleed(b, data.palette)));
    count++;
  }
  print('Extracted $count bitmaps; upscaling ×$scale…');

  void upscale(String input, String output, String model) {
    final r = Process.runSync(esrgan.path, [
      '-i', input, //
      '-o', output,
      '-n', model,
      '-s', '$scale',
      '-f', 'png',
      '-m', '${esrgan.parent.path}/models',
    ]);
    if (r.exitCode != 0) {
      stderr.writeln(r.stderr);
      exit(1);
    }
  }

  upscale(src.path, out.path, 'realesrgan-x4plus');
  // Cartoon art: the anime model, over the general result.
  for (final name in animeGroups) {
    final g = data.dat.indexOf(name);
    if (g < 0) continue;
    upscale(
      '${src.path}/g$g.png',
      '${out.path}/g$g.png',
      'realesrgan-x4plus-anime',
    );
  }

  // Lamps of a few pixels: xBRZ rounds them, ESRGAN makes rectangles.
  final python = args.contains('--python')
      ? args[args.indexOf('--python') + 1]
      : 'python3';
  // Which groups are lamps (every state of a light) and the ball.
  final groups = File('build/hd/groups.json')
    ..writeAsStringSync(
      jsonEncode({
        'lamps': [
          for (final c in data.components)
            if (c.type == ComponentType.light)
              for (var i = 0; i < c.states.length; i++)
                data.stateGroup(c.group, i),
        ],
        'balls': [
          for (var i = 0; i < data.ballSprites.length; i++)
            data.stateGroup(data.ballGroup, i),
        ],
      }),
    );
  final small = Process.runSync(python, [
    'tool/hd_small_sprites.py',
    src.path,
    out.path,
    groups.path,
    '$scale',
  ]);
  if (small.exitCode == 0) {
    stdout.write(small.stdout);
  } else {
    stderr.writeln(
      'Small sprites stay ESRGAN (needs `pip install xbrz.py Pillow`): '
      '${small.stderr}',
    );
  }

  final hd = Directory('assets/original/hd')..createSync(recursive: true);
  var written = 0;
  for (final f in out.listSync().whereType<File>()) {
    f.copySync('${hd.path}/${f.uri.pathSegments.last}');
    written++;
  }
  print('Wrote $written HD bitmaps to ${hd.path}/');
}

/// RGBA image of [b]; transparent pixels take the colour of the nearest
/// opaque pixel (a few passes of dilation), alpha stays 0.
img.Image _bleed(Bitmap8 b, Palette palette) {
  final rgba = b.toRgba(palette);
  final im = img.Image.fromBytes(
    width: b.width,
    height: b.height,
    bytes: rgba.buffer,
    numChannels: 4,
  );
  for (var pass = 0; pass < 3; pass++) {
    final copy = im.clone();
    for (var y = 0; y < b.height; y++) {
      for (var x = 0; x < b.width; x++) {
        if (copy.getPixel(x, y).a != 0) continue;
        for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final nx = x + dx, ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= b.width || ny >= b.height) continue;
          final n = copy.getPixel(nx, ny);
          if (n.a == 0 && n.r == 0 && n.g == 0 && n.b == 0) continue;
          im.setPixelRgba(x, y, n.r, n.g, n.b, 0);
          break;
        }
      }
    }
  }
  return im;
}
