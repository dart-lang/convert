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
// `// -- END GENERATED CONTENT --` markers,
// or inserts such a block at the end of the file.
//
// Specify the directory containing the files, with their original file name,
// as the first argument to this script, or create and download them to the
// default directory `../.dart_tool/unicode_iso8859_tables/`.

import 'dart:io';

import 'package:path/path.dart' as p;

/// The directory of this script. Used as base for other relative paths.
final String scriptDir = p.dirname(Platform.script.toFilePath());

/// The file containing the generated constants.
final String tableFilePath = p.join(
    scriptDir, '..', 'lib', 'src', 'codepages', 'unicode_iso8859.g.dart');

final String tableDirectoryDefaultPath =
    p.join(scriptDir, '..', '.dart_tool', 'unicode_iso8859_tables');

/// The base URI for the Unicode Consortium table files.
const baseUri = 'https://unicode.org/Public/MAPPINGS/ISO8859/';

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
  Directory tablePath;
  if (args.isNotEmpty) {
    tablePath = Directory(args.first);
  } else {
    tablePath = Directory(tableDirectoryDefaultPath);
  }
  if (!tablePath.existsSync()) {
    var scriptName = p.basename(Platform.script.toFilePath());

    stderr
      ..writeln('Usage: dart $scriptName <path-to-downloaded-tables>')
      ..writeln('')
      ..writeln('  The path should be to a directory containing the files')
      ..writeln('  of $baseUri');
    exit(1);
  }

  var tableFile = File(tableFilePath);
  if (!tableFile.existsSync()) {
    stderr
      ..writeln('Cannot find file to generate into: $tableFile')
      ..writeln('Create file with proper copyright header and run again.');
    exit(1);
  }
  var tableFileContent = tableFile.readAsStringSync();

  // Generate new declarations.
  // Reads table files, parses them, and creates new constant declarations.
  var declarations = await generateTables(tablePath);

  // Find generated content markers in existing file.
  //
  // Matches everything from [generatedContentLead] to the end of the
  // line containing [generatedContentTail].
  // Has a submatch for the lines after a first "// Generated" comment
  // line (which contains the generated date), to be checked against
  // newly generated content, to see if there is any change.
  var generatedContentMatch = RegExp('$generatedContentLead'
          r'.*\r?\n(?:// Generated.*\r?\n)?([^]*?\r?\n)'
          '$generatedContentTail'
          r'(.*\r?\n)?'
          r'|$')
      .firstMatch(tableFileContent)!;

  var existingDeclarations = generatedContentMatch[1] ?? '';
  // Whether the existing content contains windows line endings.
  var windowsLineEndings = existingDeclarations.contains('\r\n');
  if (windowsLineEndings) {
    existingDeclarations = existingDeclarations.replaceAll('\r\n', '\n');
  }
  if (declarations == existingDeclarations) {
    // If no change, don't write the file, to retain the prior generation
    // date and time.
    stderr.writeln('No changes');
    return;
  }
  // Add markers before and after the declarations.
  var replacement = wrapInGeneratedContentMarkers(declarations);
  // Convert to the detected line endings of the input, if necessary.
  if (windowsLineEndings) {
    replacement = replacement.replaceAll('\n', '\r\n');
  }
  tableFileContent = tableFileContent.replaceRange(
      generatedContentMatch.start, generatedContentMatch.end, replacement);
  tableFile.writeAsStringSync(tableFileContent);
  print('Written: $tableFile');
}

/// Fetches table file content, parses and builds constant string declarations.
Future<String> generateTables(Directory tablePath) async {
  var buffer = StringBuffer();
  // For each ISO-8859-n, n > 1, read the table,
  // and generate a constant string corresponding to the mapping
  // into `buffer`.
  // There is no ISO-8859-12. Don't include ISO-8859-1,
  // since it's already included in `dart:convert`.
  for (var i = 2; i <= 16; i++) {
    if (i == 12) continue; // No ISO-8859-12.
    generateTableFor(buffer, tablePath, i);
  }
  return buffer.toString();
}

/// Generates the constant string for a single ISO-8859 code page.
void generateTableFor(StringSink buffer, Directory tablePath, int isoNumber) {
  var fileName = "8859-$isoNumber.TXT";
  var tableFile = File(p.join(tablePath.path, fileName));
  if (!tableFile.existsSync()) {
    stderr.writeln('Cannot read required table file: ${tableFile.path}');
    exit(1);
  }
  var content = tableFile.readAsStringSync();

  var versionMatch = tableVersionRE.firstMatch(content);
  if (versionMatch == null) {
    throw FormatException(
        'Missing header fields, table version and format', content);
  }
  if (versionMatch[2] != expectedTableFormat) {
    throw FormatException('Unexpected format: $versionMatch[2]', content);
  }
  var version = versionMatch[1];
  var text = parseTable(isoNumber, content);
  buffer
    ..writeln()
    ..writeln('// Characters of ISO-8859-$isoNumber.')
    ..writeln('// Mapping table version: $version')
    ..write('const iso8859_$isoNumber = // From $baseUri$fileName');
  // Write 8 chars per line, as Unicode escapes.
  const charsPerLine = 8;
  for (var i = 0; i < text.length;) {
    buffer.write(
        '\n    /* 0x${hex(i, 2)}..0x${hex(i + charsPerLine - 1, 2)} */ \'');
    for (var c = 0; c < charsPerLine; c++) {
      buffer
        ..write(r'\u')
        ..write(hex(text.codeUnitAt(i + c), 4));
    }
    buffer.write('\'');
    i += charsPerLine;
  }
  buffer.writeln(';');
}

/// Formats positive integer as [digits]-digit base 16, left-padded with `0`.
String hex(int number, int digits) =>
    number.toRadixString(16).toUpperCase().padLeft(digits, '0');

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

/// Pattern matching the table version and format headers in the table format.
final tableVersionRE = RegExp(
    multiLine: true,
    r'^#\s+Table version:\s+(\d+\.\d+)\s*'
    r'^#\s+Table format:\s*(\w.*\w)\s*$');

/// The format of the tables currently supported.
///
/// Bail out if something else is encountered.
const expectedTableFormat = 'Format A';

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
  for (var i = 0; i < 160; i++) {
    if (encoding[i] != i) {
      stderr.writeln(
          'Info: ISO-8859-$expectedNumber not a superset of ASCII+Controls.\n'
          '  First difference: 0x${hex(i, 2)} = U+${hex(encoding[i], 4)}');
    }
  }
  if (count != 256) {
    stderr.writeln(
        'Info: ISO-8859-$expectedNumber mapping not complete, no mapping for '
        '0x${encoding.indexOf(replacementChar).toRadixString(16)}'
        '${count < 255 ? ' and ${255 - count} other' : ''}');
  }
  return String.fromCharCodes(encoding);
}

/// Builds the complete replacement for the generated section.
///
/// Wraps the generated declarations created by [generateTables]
/// in new generated content markers and a "generated when and by"
/// comment, which can replace the existing generated content section
/// of the table file.
String wrapInGeneratedContentMarkers(String declarations) => '''
$generatedContentLead
// Generated (${nowTime()}) by tools/update_unicode_iso8859_tables.dart
$declarations$generatedContentTail
''';

/// The current time, to the minute.
///
/// The returned strings has the format 'YYYY-MM-DDTHH:mm',
/// which is the first 16 characters of [DateTime.toIso8601String].
String nowTime() => DateTime.now().toIso8601String().substring(0, 16);
