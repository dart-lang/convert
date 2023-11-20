// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'codepages/unicode_iso8859.g.dart';

/// The ISO-8859-2/Latin-2 (Eastern European) code page.
///
/// This is the authoritative mapping between ISO-8859-2 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-2.TXT).
final CodePage latin2 = CodePage._bmp('latin-2', iso8859_2);

/// The ISO-8859-3/Latin-3 (South European) code page.
///
/// This is the authoritative mapping between ISO-8859-3 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-3.TXT).
final CodePage latin3 = CodePage._bmp('latin-3', iso8859_3);

/// The ISO-8859-4/Latin-4 (North European) code page.
///
/// This is the authoritative mapping between ISO-8859-4 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-4.TXT).
final CodePage latin4 = CodePage._bmp('latin-4', iso8859_4);

/// The ISO-8859-5/Latin-Cyrillic code page.
///
/// This is the authoritative mapping between ISO-8859-5 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-5.TXT).
final CodePage latinCyrillic = CodePage._bmp('cyrillic', iso8859_5);

/// The ISO-8859-6/Latin-Arabic code page.
///
/// This is the authoritative mapping between ISO-8859-6 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-6.TXT).
final CodePage latinArabic = CodePage._bmp('arabic', iso8859_6);

/// The ISO-8859-7/Latin-Greek code page.
///
/// This is the authoritative mapping between ISO-8859-7 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-7.TXT).
final CodePage latinGreek = CodePage._bmp('greek', iso8859_7);

/// The ISO-8859-7/Latin-Hebrew code page.
///
/// This is the authoritative mapping between ISO-8859-8 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-8.TXT).
final CodePage latinHebrew = CodePage._bmp('hebrew', iso8859_8);

/// The ISO-8859-9/Latin-5 (Turkish) code page.
///
/// This is the authoritative mapping between ISO-8859-9 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-9.TXT).
final CodePage latin5 = CodePage._bmp('latin-5', iso8859_9);

/// The ISO-8859-10/Latin-6 (Nordic) code page.
///
/// This is the authoritative mapping between ISO-8859-10 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-10.TXT).
final CodePage latin6 = CodePage._bmp('latin-6', iso8859_10);

/// The ISO-8859-11/Latin-Thai code page.
///
/// This is the authoritative mapping between ISO-8859-11 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-11.TXT).
final CodePage latinThai = CodePage._bmp('tis620', iso8859_11);

/// The ISO-8859-13/Latin-6 (Baltic Rim) code page.
///
/// This is the authoritative mapping between ISO-8859-13 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-13.TXT).
final CodePage latin7 = CodePage._bmp('latin-7', iso8859_13);

/// The ISO-8859-14/Latin-8 (Celtic) code page.
///
/// This is the authoritative mapping between ISO-8859-14 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-14.TXT).
final CodePage latin8 = CodePage._bmp('latin-8', iso8859_14);

/// The ISO-8859-15/Latin-9 (Western European revised) code page.
///
/// This is the authoritative mapping between ISO-8859-15 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-15.TXT).
final CodePage latin9 = CodePage._bmp('latin-9', iso8859_15);

/// The ISO-8859-16/Latin-10 (South Eastern European) code page.
///
/// This is the authoritative mapping between ISO-8859-16 and
/// Unicode text, as [specified by the Unicode Consortium](
/// https://unicode.org/Public/MAPPINGS/ISO8859/8859-16.TXT).
final CodePage latin10 = CodePage._bmp('latin-10', iso8859_16);

/// A mapping between bytes and characters.
///
/// A code page is a way to map bytes to character.
/// As such, it can only represent 256 different characters.
class CodePage extends Encoding {
  @override
  final CodePageDecoder decoder;
  @override
  final String name;
  CodePageEncoder? _encoder;

  /// Creates a code page with the given name and characters.
  ///
  /// The [characters] string must contain 256 code points (runes)
  /// in the order of the bytes representing them.
  ///
  /// Any byte not defined by the code page should have a
  /// U+FFFD (invalid character) code point at its place in
  /// [characters].
  ///
  /// The name is used by [Encoding.name].
  factory CodePage(String name, String characters) = CodePage._general;

  /// Creates a code page with the characters of [characters].
  ///
  /// The [characters] must contain precisely 256 characters (code points).
  ///
  /// A U+FFFD (invalid character) entry in [characters] means that the
  /// corresponding byte does not have a definition in this code page.
  CodePage._general(this.name, String characters)
      : decoder = _createDecoder(characters);

  /// Creates a code page with characters from the basic multilingual plane.
  ///
  /// The basic multilingual plane (BMP) contains the first 65536 code points.
  /// As such, each character can be represented by a single UTF-16 code unit,
  /// which makes some operations more efficient.
  ///
  /// The [characters] must contain precisely 256 code points from the BMP
  /// which means that it should have length 256 and not contain any surrogates.
  ///
  /// A U+FFFD (invalid character) entry in [characters] means that the
  /// corresponding byte does not have a definition in this code page.
  CodePage._bmp(this.name, String characters)
      : decoder = _BmpCodePageDecoder(characters);

  /// The character associated with a particular byte in this code page.
  ///
  /// The [byte] must be in the range 0..255.
  /// The returned value should be a Unicode scalar value
  /// (a non-surrogate code point).
  ///
  /// If a code page does not have a defined character for a particular
  /// byte, it should return the Unicode invalid character (U+FFFD)
  /// instead.
  int operator [](int byte) => decoder._char(byte);

  /// Encodes [input] using `encoder.convert`.
  @override
  Uint8List encode(String input, {int? invalidCharacter}) =>
      encoder.convert(input, invalidCharacter: invalidCharacter);

  /// Decodes [bytes] using `encoder.convert`.
  @override
  String decode(List<int> bytes, {bool allowInvalid = false}) =>
      decoder.convert(bytes, allowInvalid: allowInvalid);

  @override
  CodePageEncoder get encoder => _encoder ??= decoder._createEncoder();
}

/// A code page decoder, converts from bytes to characters.
///
/// A code page assigns characters to a subset of byte values.
/// The decoder converts those bytes back to their characters.
abstract class CodePageDecoder implements Converter<List<int>, String> {
  /// Decodes a sequence of bytes into a string using a code page.
  ///
  /// The code page assigns one character to each byte.
  /// Values in [input] must be bytes (integers in the range 0..255).
  ///
  /// If [allowInvalid] is `true`, non-byte values in [input],
  /// or byte values not defined as a character in the code page,
  /// are emitted as U+FFFD (the Unicode invalid character).
  /// If [allowInvalid] is `false`, the default,
  /// the input values must be valid bytes with a defined mapping.
  @override
  String convert(List<int> input, {bool allowInvalid = false});

  CodePageEncoder _createEncoder();
  int _char(int byte);
}

/// Creates a decoder from [characters].
///
/// Recognizes if [characters] contains only characters in the BMP,
/// and creates a [_BmpCodePageDecoder] in that case.
CodePageDecoder _createDecoder(String characters) {
  var result = Uint32List(256);
  var i = 0;
  var allChars = 0;
  for (var char in characters.runes) {
    if (i >= 256) {
      throw ArgumentError.value(
          characters, 'characters', 'Must contain 256 characters');
    }
    result[i++] = char;
    allChars |= char;
  }
  if (i < 256) {
    throw ArgumentError.value(
        characters, 'characters', 'Must contain 256 characters');
  }
  if (allChars <= 0xFFFF) {
    // It's in the BMP.
    return _BmpCodePageDecoder(characters);
  }
  return _NonBmpCodePageDecoder._(result);
}

/// An input [ByteConversionSink] for decoders where each input byte can be be
/// considered independantly.
class _CodePageDecoderSink extends ByteConversionSink {
  final Sink<String> _output;
  final Converter<List<int>, String> _decoder;

  _CodePageDecoderSink(this._output, this._decoder);

  @override
  void add(List<int> chunk) {
    _output.add(_decoder.convert(chunk));
  }

  @override
  void close() {
    _output.close();
  }
}

/// Code page with non-BMP characters.
class _NonBmpCodePageDecoder extends Converter<List<int>, String>
    implements CodePageDecoder {
  final Uint32List _characters;
  _NonBmpCodePageDecoder(String characters) : this._(_buildMapping(characters));
  _NonBmpCodePageDecoder._(this._characters);

  @override
  int _char(int byte) => _characters[byte];

  static Uint32List _buildMapping(String characters) {
    var result = Uint32List(256);
    var i = 0;
    for (var char in characters.runes) {
      if (i >= 256) {
        throw ArgumentError.value(
            characters, 'characters', 'Must contain 256 characters');
      }
      result[i++] = char;
    }
    if (i < 256) {
      throw ArgumentError.value(
          characters, 'characters', 'Must contain 256 characters');
    }
    return result;
  }

  @override
  CodePageEncoder _createEncoder() {
    var result = <int, int>{};
    for (var i = 0; i < 256; i++) {
      var char = _characters[i];
      if (char != 0xFFFD) {
        result[char] = i;
      }
    }
    return CodePageEncoder._(result);
  }

  @override
  String convert(List<int> input, {bool allowInvalid = false}) {
    var buffer = Uint32List(input.length);
    for (var i = 0; i < input.length; i++) {
      var byte = input[i];
      if (byte & 0xff != byte) throw FormatException('Not a byte', input, i);
      buffer[i] = _characters[byte];
    }
    return String.fromCharCodes(buffer);
  }

  @override
  Sink<List<int>> startChunkedConversion(Sink<String> sink) =>
      _CodePageDecoderSink(sink, this);
}

class _BmpCodePageDecoder extends Converter<List<int>, String>
    implements CodePageDecoder {
  final String _characters;
  _BmpCodePageDecoder(String characters) : _characters = characters {
    if (characters.length != 256) {
      throw ArgumentError.value(characters, 'characters',
          'Must contain 256 characters. Was ${characters.length}');
    }
  }

  @override
  int _char(int byte) => _characters.codeUnitAt(byte);

  @override
  String convert(List<int> bytes, {bool allowInvalid = false}) {
    if (allowInvalid) return _convertAllowInvalid(bytes);
    var count = bytes.length;
    var codeUnits = Uint16List(count);
    for (var i = 0; i < count; i++) {
      var byte = bytes[i];
      if (byte != byte & 0xff) {
        throw FormatException('Not a byte value', bytes, i);
      }
      var character = _characters.codeUnitAt(byte);
      if (character == 0xFFFD) {
        throw FormatException('Not defined in this code page', bytes, i);
      }
      codeUnits[i] = character;
    }
    return String.fromCharCodes(codeUnits);
  }

  @override
  Sink<List<int>> startChunkedConversion(Sink<String> sink) =>
      _CodePageDecoderSink(sink, this);

  String _convertAllowInvalid(List<int> bytes) {
    var count = bytes.length;
    var codeUnits = Uint16List(count);
    for (var i = 0; i < count; i++) {
      var byte = bytes[i];
      int character;
      if (byte == byte & 0xff) {
        character = _characters.codeUnitAt(byte);
      } else {
        character = 0xFFFD;
      }
      codeUnits[i] = character;
    }
    return String.fromCharCodes(codeUnits);
  }

  @override
  CodePageEncoder _createEncoder() => CodePageEncoder._bmp(_characters);
}

/// Encoder for a code page.
///
/// Converts a string into bytes where each byte represents that character
/// according to the code page definition.
class CodePageEncoder extends Converter<String, List<int>> {
  final Map<int, int> _encoding;

  CodePageEncoder._bmp(String characters)
      : _encoding = _createBmpEncoding(characters);

  CodePageEncoder._(this._encoding);

  static Map<int, int> _createBmpEncoding(String characters) {
    var encoding = <int, int>{};
    for (var i = 0; i < characters.length; i++) {
      var char = characters.codeUnitAt(i);
      if (char != 0xFFFD) encoding[characters.codeUnitAt(i)] = i;
    }
    return encoding;
  }

  /// Converts input to the byte encoding in this code page.
  ///
  /// If [invalidCharacter] is supplied, it must be a byte value
  /// (in the range 0..255).
  ///
  /// If [input] contains characters that are not available
  /// in this code page, they are replaced by the [invalidCharacter] byte,
  /// and then [invalidCharacter] must have been supplied.
  @override
  Uint8List convert(String input, {int? invalidCharacter}) {
    if (invalidCharacter != null) {
      RangeError.checkValueInInterval(
          invalidCharacter, 0, 255, 'invalidCharacter');
    }
    var count = input.length;
    var result = Uint8List(count);
    var j = 0;
    for (var i = 0; i < count; i++) {
      var char = input.codeUnitAt(i);
      var byte = _encoding[char];
      nullCheck:
      if (byte == null) {
        // Check for surrogate.
        var offset = i;
        if (char & 0xFC00 == 0xD800 && i + 1 < count) {
          var next = input.codeUnitAt(i + 1);
          if ((next & 0xFC00) == 0xDC00) {
            i = i + 1;
            char = 0x10000 + ((char & 0x3ff) << 10) + (next & 0x3ff);
            byte = _encoding[char];
            if (byte != null) break nullCheck;
          }
        }
        byte = invalidCharacter ??
            (throw FormatException(
                'Not a character in this code page', input, offset));
      }
      result[j++] = byte;
    }
    return Uint8List.sublistView(result, 0, j);
  }
}
