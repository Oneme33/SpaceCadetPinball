import 'dart:typed_data';

/// Reads the string table (`RT_STRING`) of a Windows PE executable: the
/// original game's messages, by resource id. Only the first language found
/// for each block is used.
///
/// Format: a resource directory tree in the `.rsrc` section (type → name →
/// language → data). String ids are stored in blocks of 16: block n holds
/// ids (n − 1) · 16 … (n − 1) · 16 + 15, each as a UTF-16 length-prefixed
/// string.
Map<int, String> readPeStrings(Uint8List exe) {
  final d = ByteData.sublistView(exe);
  int u16(int o) => d.getUint16(o, Endian.little);
  int u32(int o) => d.getUint32(o, Endian.little);

  if (exe.length < 0x40 || u16(0) != 0x5A4D) {
    throw const FormatException('not an MZ executable');
  }
  final pe = u32(0x3C);
  if (u32(pe) != 0x00004550) throw const FormatException('no PE header');
  final sections = u16(pe + 6);
  final optSize = u16(pe + 20);
  final opt = pe + 24;
  final magic = u16(opt);
  final dirBase = opt + (magic == 0x20B ? 112 : 96);
  final rsrcRva = u32(dirBase + 2 * 8);
  if (rsrcRva == 0) return const {};

  // Section table: map RVAs to file offsets.
  final table = opt + optSize;
  int? rsrcFile;
  late int rsrcSectionRva;
  for (var i = 0; i < sections; i++) {
    final s = table + i * 40;
    final va = u32(s + 12), size = u32(s + 8), raw = u32(s + 20);
    if (rsrcRva >= va && rsrcRva < va + (size == 0 ? u32(s + 16) : size)) {
      rsrcFile = raw + (rsrcRva - va);
      rsrcSectionRva = va;
      final rawBase = raw;
      int toFile(int rva) => rawBase + (rva - rsrcSectionRva);
      return _readStrings(d, rsrcFile, toFile);
    }
  }
  return const {};
}

Map<int, String> _readStrings(
  ByteData d,
  int root,
  int Function(int rva) toFile,
) {
  int u16(int o) => d.getUint16(o, Endian.little);
  int u32(int o) => d.getUint32(o, Endian.little);

  /// Entries of a resource directory at [dir]: (id, offset, isDirectory).
  List<(int, int, bool)> entries(int dir) {
    final count = u16(dir + 12) + u16(dir + 14);
    return [
      for (var i = 0; i < count; i++)
        () {
          final e = dir + 16 + i * 8;
          final id = u32(e), target = u32(e + 4);
          return (id, root + (target & 0x7FFFFFFF), target & 0x80000000 != 0);
        }(),
    ];
  }

  const rtString = 6;
  final out = <int, String>{};
  for (final (type, typeDir, isDir) in entries(root)) {
    if (type != rtString || !isDir) continue;
    for (final (block, nameDir, isNameDir) in entries(typeDir)) {
      if (!isNameDir) continue;
      final langs = entries(nameDir);
      if (langs.isEmpty) continue;
      final dataEntry = langs.first.$2;
      final offset = toFile(u32(dataEntry));
      final size = u32(dataEntry + 4);
      var p = offset;
      final end = offset + size;
      for (var i = 0; i < 16 && p + 2 <= end; i++) {
        final len = u16(p);
        p += 2;
        if (len > 0) {
          final units = [for (var k = 0; k < len; k++) u16(p + k * 2)];
          out[(block - 1) * 16 + i] = String.fromCharCodes(units);
        }
        p += len * 2;
      }
    }
  }
  return out;
}
