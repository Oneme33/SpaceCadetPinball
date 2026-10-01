// Builds the HD graphics: every bitmap in PINBALL.DAT, upscaled 4× with
// Real-ESRGAN (realesrgan-x4plus), into assets/original/hd/ (git-ignored,
// like the originals it is made from).
//
//   dart run tool/make_hd.dart --esrgan path/to/realesrgan-ncnn-vulkan
//
// Real-ESRGAN: https://github.com/xinntao/Real-ESRGAN (release v0.2.5.0,
// realesrgan-ncnn-vulkan for your platform). The models folder must sit
// next to the executable.
//
// Transparent pixels get the colour of their nearest opaque neighbour
// before upscaling, so edges do not pick up a dark fringe; transparency
// itself is upscaled by the model along with the colours.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:space_cadet/dat/dat_bitmap.dart';
import 'package:space_cadet/dat/dat_file.dart';
import 'package:space_cadet/dat/pinball_data.dart';

const scale = 4;

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

  final r = Process.runSync(esrgan.path, [
    '-i', src.path, //
    '-o', out.path,
    '-n', 'realesrgan-x4plus',
    '-s', '$scale',
    '-f', 'png',
    '-m', '${esrgan.parent.path}/models',
  ]);
  if (r.exitCode != 0) {
    stderr.writeln(r.stderr);
    exit(1);
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
