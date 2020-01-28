// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:typed_data";

import '../sink/sink.dart';
import "byte_reader.dart";
import "object_reader.dart";
import "string_reader.dart";

export "string_reader.dart" show StringSlice;

/// A JSON reader which provides pull-based access to individual JSON tokens.
///
/// The JSON reader is intended to scan JSON source text from start to end.
/// It provides access to the next token, an individual value or the
/// start of a JSON object or array. Inside an object or array, it allows
/// iterating through the entries or elements, or skipping to the end.
/// It also allows completely skipping the next JSON value, which recursively
/// skips objects and arrays.
///
/// * `expect` methods predict the type of the next value,
///   and throws if that kind of value is not the next found.
///   This consumes the value for non-composite values
///   and prepares for iterating elements or entries for object or arrays.
///   Examples: [expectString], [expectObject].
/// * `try` methods checks whether the next value is of the expected
///   kind, and if so, it works like the correspod `expect` method.
///   If not, the return value represents this failure in some way
///   appropriate to the return type (a `null` value if the `expect` method
///   returns a value, a boolean `true`/`false` if the `expect` method
///   is a `void` method).
///   Examples: [tryString], [tryInt], [tryArray].
/// * `check` methods checks whther the next value is of the expected
///   type, but does not consume (or parse) it.
///   There are no `checkInt` or `checkDouble` methods, only a [checkNum],
///   because distinguishing the two will require parsing.
///
/// Methods may throw a [FormatException]. If that happens, the state
/// of the scanner is unspecified, and it should not be used again.
///
/// The `expect` functions will throw if the next value is not of the
/// expected kind.
/// Both `expect` and `try` functions, and the iteration functions, *may*
/// throw if the input is not valid JSON. Some errors prevent further progress,
/// others may be ignored.
/// The [check] functions never throw.
///
/// When an array has been entered using [expectArray] or [tryArray],
/// the individual elements should be iterated using [hasNext].
/// Example:
/// ```dart
/// var json = JsonReader.fromString(source);
/// // I know it's a list of strings.
/// var result = <String>[];
/// json.expectArray();
/// while (json.hasNext()) {
///   result.add(json.expectString());
/// }
/// ```
/// When [hasNext] returns true, the scanner is in position to
/// read the next value in the array.
/// When [hasNext] returns false, the scanner has exited the
/// array.
/// You can also stop the array iteration at any time by
/// calling [skipArray]. This will ignore any further values
/// in the array and exit it.
///
/// When an object has been entered using [expectObject] or [tryObject],
/// it can be iterated using [nextKey].
/// Example:
/// ```dart
/// var json = JsonReader.fromString(source);
/// // I know it's an object with string values
/// var result = <String, String>{};
/// json.expectObject();
/// String key;
/// while ((key = json.nextKey()) != null) {
///   result[key] = json.expectString();
/// }
/// ```
/// When [nextKey] returns a string, the scanner is in position to
/// read the corresponding value in the object.
/// When [nextKey] returns `null`, the scanner has exited the
/// object.
/// You can also stop the array iteration at any time by
/// calling [skipObject]. This will ignore any further keys or values
/// in the object and exit it.
///
/// Correct nesting of arrays or objects is handled by the caller.
/// The scanner may not maintain any state except how far it has
/// come in the input.
/// Calling methods out of order will is unspecified behavior.
///
/// The [skipAnyValue] will skip the next value completely, even if it's
/// an object or array.
/// The [expectAnyValueSource] will skip the next value completely,
/// but return a representation of the *source* of that value
/// in a format corresponding to the original source,
/// as determined by the reader implementation.
///
/// A scanner is not necessarily *validating*.
/// If the input is not valid JSON, the behavior is unspecified.
abstract class JsonReader<SourceSlice> {
  /// Creates a JSON reader from a string containing JSON source.
  ///
  /// Returns a [StringSlice] from [expectAnyValueSource].
  static JsonReader<StringSlice> fromString(String source) =>
      JsonStringReader(source);

  /// Creates a JSON reader from a UTF-8 encoded JSON source
  ///
  /// Returns a [Uint8List] view from [expectAnyValueSource].
  static JsonReader<Uint8List> fromUtf8(Uint8List source) =>
      JsonByteReader(source);

  /// Creates a JSON reader from a JSON-like object structure.
  ///
  /// A JSON-like object structure is either a number, string,
  /// boolean or null value, or a list of JSON-like object
  /// structures, or a map from strings to JSON-like object
  /// structures.
  ///
  /// Returns the actual JSON-like object from [expectAnyValueSource].
  static JsonReader<Object> fromObject(Object source) =>
      JsonObjectReader(source);

  /// Consumes the next value which must be `null`.
  void expectNull();

  /// Consumes the next value if it is `null`.
  ///
  /// Returns `true` if a `null` was consumed and `false` if not.
  bool tryNull();

  /// Whether the next value is null.
  bool checkNull();

  /// Consumes the next value which must be `true` or `false`.
  bool expectBool();

  /// The next value, if it is `true` or `false`.
  ///
  /// If the next value is a boolean, then it is
  /// consumed and returned.
  /// Returns `null` and does not consume anything
  /// if there is no next value or the next value
  /// is not a boolean.
  bool /*?*/ tryBool();

  /// Whether the next value is a boolean.
  bool checkBool();

  /// The next value, which must be a number.
  ///
  /// The next value must be a valid JSON number.
  /// It is returned as an [int] if the number
  /// has no decimal point or exponent, otherwise
  /// as a [double] (as if parsed by [num.parse]).
  num expectNum();

  /// The next value, if it is a number.
  ///
  /// If the next value is a valid JSON number,
  /// it is returned as an [int] if the number
  /// has no decimal point or exponent, otherwise
  /// as a [double] (as if parsed by [num.parse]).
  /// Returns `null` if the next value is not a number.
  num /*?*/ tryNum();

  /// Whether the next value is a number.
  bool checkNum();

  /// Return the next value which must be an integer.
  ///
  /// The next value must be a valid JSON number
  /// with no decimal point or exponent.
  /// It is returned as an [int] (as if parsed by [int.parse]).
  int expectInt();

  /// Return the next value if it is an integer.
  ///
  /// If the next value is a valid JSON number
  /// with no decimal point or exponent,
  /// it is returned as an [int] (as if parsed by [int.parse]).
  /// Returns `null` if the next value is not an integer.
  int /*?*/ tryInt();

  /// The next value, which must be a number.
  ///
  /// The next value must be a valid JSON number.
  /// It is returned as a [double] (as if parsed by [double.parse]).
  double expectDouble();

  /// The next value, if it is a number.
  ///
  /// If the next value is a valid JSON number,
  /// it is returned as a [double] (as if parsed by [double.parse]).
  /// Returns `null` if the next value is not a number.
  double /*?*/ tryDouble();

  /// The next value, which must be a string.
  String expectString();

  /// The next value, if it is a string.
  ///
  /// If the next value is a valid JSON string,
  /// it is returned as a string value.
  /// Returns `null` if the next value is not a string.
  String /*?*/ tryString();

  /// Whether the next value is a string.
  bool checkString();

  /// Enters the next value, which must be an array.
  ///
  /// The array should then be iterated using [hasNext] or [skipArray].
  void expectArray();

  /// Enters the next value if it is an array.
  ///
  /// Returns `true` if the scanner entered an array
  /// and `false` if not.
  ///
  /// The entered array should then be iterated using
  /// [hasNext] or [skipArray].
  bool tryArray();

  /// Whether the next value is an array.
  bool checkArray();

  /// Find the next array element in the current array.
  ///
  /// Must be called either after entering an array
  /// using [expectArray] or [tryArray]
  /// or after scanning an array element.
  ///
  /// Returns true if there are more elements,
  /// and prepares the scanner for scanning the next
  /// array element. This element must then be
  /// consumed ([expectInt], etc) or skipped ([skipAnyValue])
  /// before this function can be called again.
  ///
  /// Returns false if there is no next element,
  /// and this also exits the array.
  bool hasNext();

  /// Skips the remainder of the current object.
  ///
  /// Exits the current array, ignoring any further
  /// elements.
  ///
  /// An array is "current" after entering it
  /// using [tryArray] or [expectArray],
  /// and until exiting by having [hasNext] return false
  /// or by calling [skipArray].
  /// Entering another array makes that current until
  /// that array is exited.
  void skipArray();

  /// Enters the next value, which must be an object.
  ///
  /// The object should then be iterated using [nextKey] or [skipObject].
  void expectObject();

  /// Enters the next value if it is an object.
  ///
  /// Returns `true` if the scanner entered an object
  /// and `false` if not.
  ///
  /// The entered object should then be iterated using
  /// [nextKey] or [skipObject].
  bool tryObject();

  /// Whether the next value is an object.
  bool checkObject();

  /// The next key, of the current object.
  ///
  /// Must only be used while scanning an object.
  /// If the current object has more properties,
  /// then the key of the next property is returned,
  /// and the scanner is ready to read the
  /// corresponding value.
  ///
  /// Returns `null` if there are no further entries,
  /// and exits the object.
  String /*?*/ nextKey();

  /// The next object key, if it is in the list of candidates.
  ///
  /// Like [nextKey] except that it only matches if the next key
  /// is one of the strings in [candidates] *and* the key string
  /// value does not contain any escapes.
  ///
  /// The [candidates] *must* be a non-empty *sorted* list of ASCII
  /// strings.
  ///
  /// This is intended for simple key strings, which is what
  /// most JSON uses.
  /// If a match is found, the string object in the [candidates] list
  /// is returned rather than creating a new string.
  String /*?*/ tryKey(List<String> candidates);

  /// Skips the next map entry, if there is one.
  ///
  /// Can be used in the same situations as [nextKey] or [tryKey],
  /// but skips the key and the following value.
  ///
  /// Returns `true` if an entry was skipped.
  /// Returns `false` if there are no further entries
  /// and exits the object.
  bool skipObjectEntry();

  /// Skips the remainder of the current object.
  ///
  /// Exits the current object, ignoring any further
  /// keys or values.
  ///
  /// An object is "current" after entering it
  /// using [tryObject] or [expectObject],
  /// and until exiting by having [nextKey] return `null`
  /// or calling [skipObject].
  /// Entering another object makes that current until
  /// that object is exited.
  void skipObject();

  /// Skips the next value.
  ///
  /// This skips and consumes the entire next value.
  /// If the value is an array or object, all the
  /// nested elements or entries are skipped too.
  ///
  /// Example:
  /// ```dart
  /// var g = JsonGet(r'[{"a": 42}, "Here"]');
  /// g.expectArray();
  /// g.hasNext(); // true
  /// g.skipAnyValue();
  /// g.hasNext(); // true;
  /// g.expectString(); // "Here"
  /// ```
  void skipAnyValue();

  /// Skips the next value.
  ///
  /// This skips and consumes the entire next value.
  /// If the value is an array or object, all the
  /// nested elements or entries are skipped too.
  ///
  /// Returns a representation of the source corresponding
  /// to the skipped value. The kind of value returned
  /// depends on the implementation and source format.
  /// May throw or return `null` if there is no next value.
  SourceSlice expectAnyValueSource();

  /// Skips the next value.
  ///
  /// This skips and consumes the entire next value.
  /// If the value is an array or object, all the
  /// nested elements or entries are skipped too.
  ///
  /// Parses the JSON structure of the skipped value
  /// and emits it on the [sink].
  void expectAnyValue(JsonSink sink);

  /// Creates a copy of the state of the current reader.
  ///
  /// This can be used to, for example, create a copy,
  /// then skip a value using [skipAnyValue], and then
  /// later come back to the copy reader and read the
  /// value anyway.
  JsonReader copy();
}
