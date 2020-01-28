// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "sink.dart";

/// A [JsonSink] which builds Dart object structures.
class JsonObjectWriter implements JsonSink {
  /// The callback which is called for each complete JSON object.
  final void Function(dynamic) _result;

  /// Stack of objects or arrays being built, and pending [_key] values.
  final List<Object/*?*/> _stack = [];

  /// Last key added using [addKey].
  String _key;

  JsonObjectWriter(this._result);

  void _value(Object/*?*/ value) {
    if (_stack.isEmpty) {
      _result(value);
      _key = null;
    } else {
      var top = _stack.last;
      if (_key != null) {
        (top as Map<String, dynamic>)[_key] = value;
        _key = null;
      } else {
        (top as List<dynamic>).add(value);
      }
    }
  }

  void addBool(bool value) {
    _value(value);
  }

  void endArray() {
    var array = _stack.removeLast();
    _key = _stack.removeLast() as String;
    _value(array);
  }

  void endObject() {
    var object = _stack.removeLast();
    _key = _stack.removeLast() as String;
    _value(object);
  }

  void addKey(String key) {
    _key = key;
  }

  void addNull() {
    _value(null);
  }

  void addNumber(num value) {
    _value(value);
  }

  void startArray() {
    _stack.add(_key);
    _stack.add(<dynamic>[]);
    _key = null;
  }

  void startObject() {
    _stack.add(_key);
    _stack.add(<String, dynamic>{});
    _key = null;
  }

  void addString(String value) {
    _value(value);
  }
}