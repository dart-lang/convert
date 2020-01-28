// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'object_writer.dart';
import 'string_writer.dart';

/// A generalized JSON visitor interface.
///
/// A JSON-like object structure (or just "JSON structure")
/// is a recursive structure of either atomic values:
///
/// * number
/// * string
/// * boolean
/// * null
///
/// or composte structures which are either
/// an *array* of one or more JSON structures,
/// or an *object* with pairs of string keys and
/// JSON structure values.
///
/// A [JsonSink] expects its members to be called in sequences
/// corresponding to the JSON structure of a single value:
/// Either a primitive value, [addNumber], [addString], [addBool] or [addNull],
/// or a [startArray] followed by JSON values and ended by an [endArray],
/// or a [startObject] followed by alternating [addKey] and values, and ended
/// with an [endObject].
///
/// In general, a [JsonSink] is not required or expected to
/// work correctly if calls are performed out of order.
/// Only call sequences corresponding to a correct JSON structure
/// are guaranteed to give a meaningful result.
abstract class JsonSink {
  /// Called for a number value.
  void addNumber(num value);

  /// Called for a null value.
  void addNull();

  /// Called for a string value.
  void addString(String value);

  /// Called for a boolean value.
  void addBool(bool value);

  /// Called at the beginning of an array value.
  ///
  /// Each value added until a corresponding [endArray]
  /// is considered an element of this array, unless it's part of a nested
  /// array or object.
  void startArray();

  /// Ends the current array.
  ///
  /// The array value is now complete, and should
  /// be treated as a value of a surrounding array or obejct.
  void endArray();

  /// Called at the beginning of an object value.
  ///
  /// Each value added until a corresponding [endObject]
  /// is considered an entry value of this object, unless it's part of a nested
  /// array or object.
  /// Each such added value must be preceeded by exactly one call to [addKey]
  /// which provides the corresponding key.
  void startObject();

  /// Sets the key for the next value of an object.
  ///
  /// Should preceed any value or array/object start inside an object.
  void addKey(String key);

  /// Ends the current object.
  ///
  /// The object value is now complete, and should
  /// be treated as a value of a surrounding array or obejct.
  void endObject();
}

/// Creates a [JsonSink] which builds a JSON string.
///
/// The string is written to [sink].
///
/// If [indent] is supplied, the resulting string will be "pretty printed"
/// with array and object entries on lines of their own
/// and indented by multiples of the [indent] string.
/// If the [indent] string is not valid JSON whitespace,
/// the result written to [sink] will not be valid JSON source.
///
/// If [asciiOnly] is set to `true`, string values will have all non-ASCII
/// characters escaped. If not, only control characters, quotes and backslashes
/// are escaped.
///
/// The returned sink is not reusable. After it has written a single JSON structure,
/// it should not be used again.
JsonSink jsonStringWriter(StringSink sink,
    {String indent, bool asciiOnly = false}) {
  if (indent == null) return JsonStringWriter(sink, asciiOnly: asciiOnly);
  return JsonPrettyStringWriter(sink, indent, asciiOnly: asciiOnly);
}

/// Creates a [JsonSink] which builds a Dart JSON object structure.
///
/// After adding values corresponding to a JSON structure to the sink,
/// the [result] callback is called with the resulting object structure.
///
/// When [result] is called, the returned sink is reset and can be reused.
JsonSink jsonObjectWriter(void Function(dynamic) result) =>
    JsonObjectWriter(result);
