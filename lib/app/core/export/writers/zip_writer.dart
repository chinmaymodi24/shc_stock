import 'dart:convert';
import 'dart:typed_data';

// ─────────────────────────────────────────────────────────────────────────────
// Minimal ZIP writer — the container an .xlsx actually is.
//
// Entries are stored uncompressed (method 0). A spreadsheet export is a few
// hundred KB of XML at worst and every reader accepts a stored entry, so
// pulling in a compression library for it would buy nothing. Keeping this
// pure Dart is what lets the whole export stack ship without a new package
// (and therefore without a full app rebuild).
// ─────────────────────────────────────────────────────────────────────────────

class ZipEntry {
  final String path;
  final Uint8List bytes;
  const ZipEntry(this.path, this.bytes);

  factory ZipEntry.text(String path, String content) =>
      ZipEntry(path, Uint8List.fromList(utf8.encode(content)));
}

/// CRC-32 (IEEE 802.3) — required in every ZIP local header.
class Crc32 {
  static final Uint32List _table = _buildTable();

  static Uint32List _buildTable() {
    final table = Uint32List(256);
    for (var i = 0; i < 256; i++) {
      var c = i;
      for (var k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
      }
      table[i] = c;
    }
    return table;
  }

  static int compute(List<int> data) {
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc = _table[(crc ^ byte) & 0xFF] ^ (crc >> 8);
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}

/// Packs [entries] into a ZIP archive.
Uint8List buildZip(List<ZipEntry> entries) {
  final out = _ByteWriter();
  final directory = <_CentralRecord>[];

  for (final entry in entries) {
    final nameBytes = utf8.encode(entry.path);
    final crc = Crc32.compute(entry.bytes);
    final offset = out.length;

    out.uint32(0x04034b50); // local file header signature
    out.uint16(20); // version needed to extract
    out.uint16(0x0800); // general purpose flags — UTF-8 names
    out.uint16(0); // compression method: stored
    out.uint16(0); // last mod time
    out.uint16(0x21); // last mod date — 1 Jan 1996, a fixed, valid stamp
    out.uint32(crc);
    out.uint32(entry.bytes.length);
    out.uint32(entry.bytes.length);
    out.uint16(nameBytes.length);
    out.uint16(0); // extra field length
    out.bytes(nameBytes);
    out.bytes(entry.bytes);

    directory.add(_CentralRecord(nameBytes, crc, entry.bytes.length, offset));
  }

  final directoryStart = out.length;
  for (final record in directory) {
    out.uint32(0x02014b50); // central directory header signature
    out.uint16(20); // version made by
    out.uint16(20); // version needed
    out.uint16(0x0800);
    out.uint16(0);
    out.uint16(0);
    out.uint16(0x21);
    out.uint32(record.crc);
    out.uint32(record.size);
    out.uint32(record.size);
    out.uint16(record.name.length);
    out.uint16(0); // extra
    out.uint16(0); // comment
    out.uint16(0); // disk number
    out.uint16(0); // internal attrs
    out.uint32(0); // external attrs
    out.uint32(record.offset);
    out.bytes(record.name);
  }
  final directorySize = out.length - directoryStart;

  out.uint32(0x06054b50); // end of central directory
  out.uint16(0);
  out.uint16(0);
  out.uint16(directory.length);
  out.uint16(directory.length);
  out.uint32(directorySize);
  out.uint32(directoryStart);
  out.uint16(0); // comment length

  return out.toBytes();
}

class _CentralRecord {
  final List<int> name;
  final int crc;
  final int size;
  final int offset;
  const _CentralRecord(this.name, this.crc, this.size, this.offset);
}

class _ByteWriter {
  final BytesBuilder _builder = BytesBuilder(copy: false);
  int _length = 0;

  int get length => _length;

  void bytes(List<int> value) {
    _builder.add(value);
    _length += value.length;
  }

  void uint16(int value) => bytes([value & 0xFF, (value >> 8) & 0xFF]);

  void uint32(int value) => bytes([
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ]);

  Uint8List toBytes() => _builder.toBytes();
}
