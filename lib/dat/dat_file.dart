import 'dart:convert';
import 'dart:typed_data';

/// Entry types in a `PARTOUT(4.0)RESOURCE` file (3D Pinball's PINBALL.DAT).
///
/// Format reference: the MIT-licensed decompilation
/// k4zmu2a/SpaceCadetPinball (`partman.cpp`). This parser is our own code.
enum DatFieldType {
  shortValue, // 0
  bitmap8, // 1
  unknown2, // 2
  groupName, // 3
  unknown4, // 4
  palette, // 5
  unknown6, // 6
  unknown7, // 7
  unknown8, // 8
  string, // 9
  shortArray, // 10
  floatArray, // 11
  zMap, // 12
}

class DatFormatException implements Exception {
  DatFormatException(this.message);
  final String message;
  @override
  String toString() => 'DatFormatException: $message';
}

/// One raw entry of a group. [data] is a view into the file buffer.
class DatEntry {
  const DatEntry(this.type, this.data);

  final DatFieldType type;
  final ByteData data;

  int get length => data.lengthInBytes;

  int get shortValue => data.getInt16(0, Endian.little);

  Int16List get shorts {
    final list = Int16List(length ~/ 2);
    for (var i = 0; i < list.length; i++) {
      list[i] = data.getInt16(i * 2, Endian.little);
    }
    return list;
  }

  Float32List get floats {
    final list = Float32List(length ~/ 4);
    for (var i = 0; i < list.length; i++) {
      list[i] = data.getFloat32(i * 4, Endian.little);
    }
    return list;
  }

  /// Zero-terminated Latin-1 string.
  String get text {
    final bytes = data.buffer.asUint8List(data.offsetInBytes, length);
    final end = bytes.indexOf(0);
    return latin1.decode(end < 0 ? bytes : bytes.sublist(0, end));
  }
}

/// A group: a component, one of its visual states, a sound, a light…
class DatGroup {
  DatGroup(this.index, this.entries);

  final int index;
  final List<DatEntry> entries;

  /// The [n]th entry of [type], or null.
  DatEntry? field(DatFieldType type, [int n = 0]) {
    var seen = 0;
    for (final e in entries) {
      if (e.type == type && seen++ == n) return e;
    }
    return null;
  }

  Iterable<DatEntry> fields(DatFieldType type) =>
      entries.where((e) => e.type == type);

  String? get name => field(DatFieldType.groupName)?.text;
}

/// The parsed file: a flat list of groups.
class DatFile {
  DatFile._(this.appName, this.description, this.groups);

  static const signature = 'PARTOUT(4.0)RESOURCE';
  static const _headerSize = 183;

  /// Fixed sizes per field type; -1 means a uint32 length prefix follows.
  static const _fixedSize = [2, -1, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];

  final String appName;
  final String description;
  final List<DatGroup> groups;

  late final Map<String, int> _byName = {
    for (final g in groups) ?g.name: g.index,
  };

  /// Group index by name, or -1.
  int indexOf(String name) => _byName[name] ?? -1;

  DatGroup? byName(String name) {
    final i = indexOf(name);
    return i < 0 ? null : groups[i];
  }

  static DatFile parse(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    if (bytes.length < _headerSize) {
      throw DatFormatException('file too short');
    }
    String cstr(int offset, int len) {
      final raw = bytes.sublist(offset, offset + len);
      final end = raw.indexOf(0);
      return latin1.decode(end < 0 ? raw : raw.sublist(0, end));
    }

    if (cstr(0, 21) != signature) {
      throw DatFormatException('not a $signature file');
    }
    final appName = cstr(21, 50);
    final description = cstr(71, 100);
    final groupCount = data.getUint16(175, Endian.little);
    final unknown = data.getUint16(181, Endian.little);

    var p = _headerSize + unknown;
    int u8() => bytes[p++];
    int u32() {
      final v = data.getUint32(p, Endian.little);
      p += 4;
      return v;
    }

    final groups = <DatGroup>[];
    for (var g = 0; g < groupCount; g++) {
      final count = u8();
      final entries = <DatEntry>[];
      for (var e = 0; e < count; e++) {
        final typeIndex = u8();
        if (typeIndex >= DatFieldType.values.length) {
          throw DatFormatException('unknown field type $typeIndex in group $g');
        }
        final fixed = _fixedSize[typeIndex];
        final size = fixed >= 0 ? fixed : u32();
        if (p + size > bytes.length) {
          throw DatFormatException('entry runs past end of file in group $g');
        }
        entries.add(
          DatEntry(
            DatFieldType.values[typeIndex],
            ByteData.sublistView(bytes, p, p + size),
          ),
        );
        p += size;
      }
      groups.add(DatGroup(g, entries));
    }
    if (p != bytes.length) {
      throw DatFormatException('${bytes.length - p} trailing bytes');
    }
    return DatFile._(appName, description, groups);
  }
}
