// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'sink.dart';

/// A [JsonSink] which builds a textual representation of the JSON structure.
///
/// The resulting string representation is a minimal JSON text with no
/// whitespace between tokens.
class JsonStringWriter implements JsonSink {
  final StringSink _sink;
  final bool _asciiOnly;
  String _separator = "";

  /// Creates a writer which writes the result into [target].
  ///
  /// When an entire JSON value has been written, [target]
  /// will contain the string representation.
  ///
  /// If [asciiOnly] is true, string values will escape any non-ASCII
  /// character. If not, only control characters are escaped.
  JsonStringWriter(StringSink target, {bool asciiOnly = false})
      : _sink = target,
        _asciiOnly = asciiOnly;

  void addBool(bool value) {
    _sink.write(_separator);
    _sink.write(value);
    _separator = ",";
  }

  void endArray() {
    _sink.write("]");
    _separator = ",";
  }

  void endObject() {
    _sink.write("}");
    _separator = ",";
  }

  void addKey(String key) {
    _sink.write(_separator);
    _writeString(_sink, key, _asciiOnly);
    _separator = ":";
  }

  void addNull() {
    _sink.write(_separator);
    _sink.write("null");
    _separator = ",";
  }

  void addNumber(num value) {
    _sink.write(_separator);
    _sink.write(value);
    _separator = ",";
  }

  void startArray() {
    _sink.write(_separator);
    _sink.write("[");
    _separator = "";
  }

  void startObject() {
    _sink.write(_separator);
    _sink.write("{");
    _separator = "";
  }

  void addString(String value) {
    _sink.write(_separator);
    _writeString(_sink, value, _asciiOnly);
    _separator = ",";
  }
}

/// A [JsonSink] which builds a pretty textual representation of the JSON.
///
/// The textual representation is spread on multiple lines and
/// the content of JSON arrays or objects are indented.
class JsonPrettyStringWriter implements JsonSink {
  final StringSink _sink;
  final bool _asciiOnly;
  final String _indentString;
  int _indent = 0;
  String _separator = "";

  /// Creates a writer which writes the result into [target].
  ///
  /// The [indentString] is used for indenting nested structures
  /// on new lines. If [indentString] is not pure whitespace,
  /// typically a single TAB character or a number of space characters,
  /// then the resulting text may not be valid JSON.
  ///
  /// If [asciiOnly] is true, string values will escape any non-ASCII
  /// character. If not, only control characters are escaped.
  JsonPrettyStringWriter(StringSink target, String indentString,
      {bool asciiOnly = false})
      : _sink = target,
        _indentString = indentString,
        _asciiOnly = asciiOnly;

  void _writeSeparator() {
    if (_separator != null) {
      _sink.write(_separator);
      _writeIndent();
    }
  }

  void _writeIndent() {
    _sink.write("\n");
    for (var i = 0; i < _indent; i++) {
      _sink.write(_indentString);
    }
  }

  void addBool(bool value) {
    _writeSeparator();
    _sink.write(value);
    _separator = ",";
  }

  void endArray() {
    _indent--;
    _writeIndent();
    _sink.write("]");
    _separator = ",";
  }

  void endObject() {
    _indent--;
    _writeIndent();
    _sink.write("}");
    _separator = ",";
  }

  void addKey(String key) {
    _writeSeparator();
    _writeString(_sink, key, _asciiOnly);
    _sink.write(": ");
    _separator = null;
  }

  void addNull() {
    _writeSeparator();
    _sink.write("null");
    _separator = ",";
  }

  void addNumber(num value) {
    _writeSeparator();
    _sink.write(value);
    _separator = ",";
  }

  void startArray() {
    _writeSeparator();
    _sink.write("[");
    _indent++;
    _separator = "";
  }

  void startObject() {
    _writeSeparator();
    _sink.write("{");
    _indent++;
    _separator = "";
  }

  void addString(String value) {
    _writeSeparator();
    _writeString(_sink, value, _asciiOnly);
    _separator = ",";
  }
}

void _writeString(StringSink _sink, String string, bool asciiOnly) {
  _sink.write('"');
  var start = 0;
  for (var i = 0; i < string.length; i++) {
    var char = string.codeUnitAt(i);
    if (char < 0x20 ||
        char == 0x22 ||
        char == 0x5c ||
        (asciiOnly && char > 0x7f)) {
      if (i > start) _sink.write(string.substring(start, i));
      switch (char) {
        case 0x08:
          _sink.write(r"\b");
          break;
        case 0x09:
          _sink.write(r"\t");
          break;
        case 0x0a:
          _sink.write(r"\n");
          break;
        case 0x0c:
          _sink.write(r"\f");
          break;
        case 0x0d:
          _sink.write(r"\r");
          break;
        case 0x22:
          _sink.write(r'\"');
          break;
        case 0x5c:
          _sink.write(r"\\");
          break;
        default:
          _sink.write(char < 256
              ? (char < 0x10 ? r"\u000" : r"\u00")
              : (char < 0x1000 ? r"\u0" : r"\u"));
          _sink.write(char.toRadixString(16));
      }
      start = i + 1;
    }
  }
  if (start < string.length) _sink.write(string.substring(start));
  _sink.write('"');
}
