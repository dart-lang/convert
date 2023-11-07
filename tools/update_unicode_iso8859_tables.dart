// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generator for tables for ISO-8859 code page encoding of Unicode text,
// using the [authoritative](https://unicode.org/Public/MAPPINGS/ISO8859/ReadMe.txt)
// Unicode Consortium character
// [mappings](https://unicode.org/Public/MAPPINGS/ISO8859/ "Mapping repository")
//
// Updates the definitions in `lib/src/codepages/unicode_iso8859.g.dart`,
// between the `// -- BEGIN GENERATED CONTENT --` and
// `// -- END GENERATED CONTENT --` markers, or inserts such a block at the
// end of the file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// The directory of this script. Used as base for other relative paths.
final String scriptDir = p.dirname(Platform.script.toFilePath());

/// The file containing the generated constants.
final String tableFilePath = p.join(
    scriptDir, '..', 'lib', 'src', 'codepages', 'unicode_iso8859.g.dart');

/// The base URI for the Unicode Consortium table files.
final baseUri = Uri.parse('https://unicode.org/Public/MAPPINGS/ISO8859/');

/// Path to a cache directory used to cache downloaded table files.
final cachePath = p.join(
    scriptDir, '..', '.dart_tool', 'iso8859_tool_http_cache', 'unicode.org');

/// Start-marker for generated content in the [tableFilePath] file.
///
/// Generation only changes content from this marker to the
/// [generatedContentTail] end marker.
const generatedContentLead = '// -- BEGIN GENERATED CONTENT --';

/// End-marker for generated content in the [tableFilePath] file.
///
/// Ends region started by [generatedContentLead].
const generatedContentTail = '// -- END GENERATED CONTENT --';

// Rebuild the tables used for ISO-8859 code pages.
void main(List<String> args) async {
  var tableFile = File(tableFilePath);
  if (!tableFile.existsSync()) {
    stderr.writeln('Cannot find file to generate into: $tableFile');
    stderr.writeln('Create file with proper copyright header and run again.');
  }
  var tableFileContent = tableFile.readAsStringSync();

  // Generate new declarations.
  var declarations = await generateTables();

  // Find generated content markers in existing file.
  var generatedContentMatch = RegExp('$generatedContentLead'
          r'.*\r?\n(?:// Generated.*\r?\n)?([^]*?\r?\n)'
          '$generatedContentTail'
          r'(.*\r?\n)?'
          r'|$')
      .firstMatch(tableFileContent)!;

  var existingDeclarations = generatedContentMatch[1] ?? '';
  if (declarations == existingDeclarations) {
    // If no change, no write.
    stderr.writeln('No changes');
    return;
  }
  var replacement = replacementString(declarations);
  // Guess file's newline, change to '\r\n' if necessary.
  if (Platform.isWindows && tableFileContent.contains('\r\n')) {
    replacement = replacement.replaceAll('\n', '\r\n');
  }
  tableFileContent = tableFileContent.replaceRange(
      generatedContentMatch.start, generatedContentMatch.end, replacement);
  tableFile.writeAsStringSync(tableFileContent);
  print('Written: $tableFile');
}

/// Shared HTTP client used by [fetchTable], initialized if needed.
///
/// Closed by [generateTables] when done fetching.
HttpClient? httpClient;

/// Fetches table file content, parses and builds constant string declarations.
Future<String> generateTables() async {
  // Used for caching fetched files.
  // Useful if running the script multiple times.
  var cacheDir = Directory(cachePath);
  if (!cacheDir.existsSync()) cacheDir.createSync(recursive: true);

  var buffer = StringBuffer();
  // For each ISO-8859-n, n > 1, fetch the table,
  // and generate a constant string corresponding to the mapping
  // into `buffer`.
  // There is no ISO-8859-12. Don't include ISO-8859-1,
  // since it's already included in `dart:convert`.
  for (var i = 2; i <= 16; i++) {
    if (i == 12) continue; // No ISO-8859-12.
    await generateTableFor(buffer, i);
  }

  httpClient?.close();
  return buffer.toString();
}

/// Generates the constant string for a single ISO-8859 code page.
Future<void> generateTableFor(StringSink buffer, int isoNumber) async {
  var (uri, content) = await fetchTable(isoNumber);
  var text = parseTable(isoNumber, content);
  buffer
    ..writeln()
    ..writeln('// Characters of ISO-8859-$isoNumber.')
    ..write('const iso8859_$isoNumber = // From $uri');
  // Write 8 chars per line, as Unicode escapes.
  for (var i = 0; i < text.length;) {
    var charsOnLine = nextRangeLength(text, i, 74);
    buffer.write('\n    \'');
    for (var c = 0; c < charsOnLine; c++) {
      writeChar(buffer, text.codeUnitAt(i + c));
    }
    i += charsOnLine;
    buffer.write('\'');
  }
  buffer.writeln(';');
}

// Code units that are encoded specially in the generated literals.
const specialChars = {
  0x08: r'\b',
  0x09: r'\t',
  0x0a: r'\n',
  0x0b: r'\v',
  0x0c: r'\f',
  0x0d: r'\r',
  0x24: r'\$',
  0x27: r"\'",
  0x7f: r'\x7F',
  0x5c: r'\\',
};

/// Write a single code unit into a string literal.
///
/// Writes all code units above 0xFF as `\uHHHH`.
/// Writes all printable ASCII codes as themselves,
/// possibly escaped.
/// Writes characters that have escapes, like `\n`, as those.
/// The remaining code units in the 0x00..0xFF range are written as `\xHH`
void writeChar(StringSink buffer, int charCode) {
  if (specialChars[charCode] case var s?) {
    buffer.write(s);
  } else if (charCode >= 0x20 && charCode < 0x7f) {
    buffer.writeCharCode(charCode);
  } else if (charCode <= 0xFF) {
    buffer
      ..write(charCode < 0x10 ? r'\x0' : r'\x')
      ..write(charCode.toRadixString(16).toUpperCase());
  } else {
    buffer
      ..write(r'\u')
      ..write(charCode.toRadixString(16).toUpperCase().padLeft(4, '0'));
  }
}

/// Find the number of characters that fits in a single-line string literal.
///
/// Finds the largest number of characters starting from [from],
/// which is a power of 2, and where the characters representation,
/// as written by [writeChar], fits within [maxLength] characters.
int nextRangeLength(String text, int from, int maxLength) {
  var best = 8;
  assert(best * 6 <= maxLength);
  var length = 0;
  var count = 0;
  for (var i = from; i < text.length; i++) {
    var c = text.codeUnitAt(i);
    length += specialChars[c]?.length ??
        (c < 0x20 // Low-ACSII control code: \xHH
            ? 4
            : c < 0x7f // Other visible ASCII: itself.
                ? 1
                : c < 0x100 // 0x7f..0xff: \xHH
                    ? 4
                    : 6); // Above: /uHHHH.
    count += 1;
    if (length > maxLength) return best;
    var isPowerOf2 = count & (count - 1) == 0;
    if (isPowerOf2 && count > best) best = count;
  }
  return count; // Rest of string.
}

/// Fetches table file content for ISO-8859-*n*.
///
/// Either from cache, or using an HTTP request.
Future<(Uri, String)> fetchTable(int n) async {
  var fileName = '8859-$n.TXT';
  var uri = baseUri.resolve(fileName);
  var filePath = p.join(cachePath, fileName);
  var file = File(filePath);

  String content;
  if (file.existsSync()) {
    content = file.readAsStringSync();
  } else {
    content = await httpGetString(uri);
    file.writeAsStringSync(content);
  }
  return (uri, content);
}

/// Pattern matching a table file line for a character mapping.
///
/// Matched format, on a line:
/// ```
/// 0xHH<tab>0xHHHH<tab># text
/// ```
///
/// The captures are:
/// - 1: The byte, as two hex digits
/// - 2: The corresponding code unit, as four hex digits.
final tableCharMappingRE =
    RegExp(multiLine: true, r'^0x([\dA-F]{2})\t0x([\dA-F]{4})(?:\t#.*)?$');

/// Parses table content.
///
/// Assumed to start with the file name, '# 8859-n.TXT`.
/// All other lines either start with `#` or has the form
/// ```
/// 0xHH<tab>0xHHHH<tab># text
/// ```
/// Those line define the mapping.
///
/// Not all code-pages define characters for all bytes.
/// The bytes that have no corresponding code point are mapped to U+FFFD,
/// the replacement character.
String parseTable(int expectedNumber, String table) {
  // Unicode consortium mapping table.
  if (!table.startsWith('# 8859-$expectedNumber.TXT')) {
    throw FormatException('Not table for ISO-8859-$expectedNumber', table, 0);
  }

  const replacementChar = 0xFFFD;
  var encoding = List<int>.filled(256, replacementChar);
  var count = 0;
  for (var mapping in tableCharMappingRE.allMatches(table)) {
    var byte = int.parse(mapping[1]!, radix: 16);
    var char = int.parse(mapping[2]!, radix: 16);
    if (encoding[byte] != replacementChar) {
      throw FormatException(
          'Duplicate mapping, already mapped to '
          '0x${encoding[byte].toRadixString(16)}',
          table,
          mapping.start);
    }
    encoding[byte] = char;
    count++;
  }
  if (count != 256) {
    stderr.writeln(
        'ISO-8859-$expectedNumber mapping not complete, no mapping for '
        '0x${encoding.indexOf(replacementChar).toRadixString(16)}'
        '${count < 255 ? ' and ${255 - count} other' : ''}');
  }
  return String.fromCharCodes(encoding);
}

/// Fetches text response for an HTTP request for [uri].
///
/// Nothing fancy accepted, must return [HttpStatus.ok].
Future<String> httpGetString(Uri uri) async {
  var client = httpClient ??= HttpClient();
  var request = await client.getUrl(uri);
  var response = await request.close();
  if (response.statusCode != HttpStatus.ok) {
    throw HttpException('Cannot fetch (${response.statusCode})', uri: uri);
  }
  // ignore: unnecessary_await_in_return
  return await response.transform(const Utf8Decoder()).join();
}

/// Builds the complete replacement for the generated section.
///
/// Wraps the generated declarations created by [generateTables]
/// in new generated content markers and a "generated when and by"
/// comment, which can replace the existing generated content section
/// of the table file.
String replacementString(String declarations) => '''
$generatedContentLead
// Generated (${nowTime()}) by tools/update_unicode_iso8859_tables.dart
$declarations$generatedContentTail
''';

/// The current time, to the minute.
///
/// The returned strings has the format 'YYYY-MM-DDTHH:mm',
/// which is the first 16 characters of [DateTime.toIso8601String].
String nowTime() => DateTime.now().toIso8601String().substring(0, 16);
