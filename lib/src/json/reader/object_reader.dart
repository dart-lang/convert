// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../sink/sink.dart';
import "reader.dart";

/// A [JsonReader] which traverses a JSON-like object structure.
///
/// A JSON-like object structure is one of:
/// * `null`,
/// * a number,
/// * a boolean,
/// * a string,
/// * a list of JSON-like object structures or
/// * a map from strings to JSON-like object structures.
class JsonObjectReader implements JsonReader<Object /*?*/ > {
  /// The next object to access.
  ///
  /// Is set to `#_none` when there are no next object available.
  /// This happens after reading the entire source object,
  /// after entering an array or after reading an array value,
  /// but before calling [hasNext] or [skipArray],
  /// or after entering an object or reading an object value,
  /// but before calling [expectKey], [tryKey] or [skipObject].
  Object /*?*/ _next;

  /// Stack of the currently entered objects and arrays.
  ///
  /// Contains an iterator for the elements of the array or
  /// the keys of the map, which is used to find the next
  /// one when needed.
  ///
  /// Stack elements are automatically popped from the stack
  /// when they have been completely iterated.
  _Stack /*?*/ _stack;

  /// Creates a reader for the [object] value.
  JsonObjectReader(Object /*?*/ object) : _next = object;

  /// Used by [copy] to create a copy of this reader's state.
  JsonObjectReader._(this._next, this._stack);

  @override
  bool checkArray() {
    return _next is List;
  }

  @override
  bool checkBool() {
    return _next is bool;
  }

  @override
  bool checkNull() {
    return _next == null;
  }

  @override
  bool checkNum() {
    return _next is num;
  }

  @override
  bool checkObject() {
    return _next is Map<String, dynamic>;
  }

  @override
  bool checkString() {
    return _next is String;
  }

  @override
  Object expectAnyValueSource() {
    var result = _next;
    if (result == #_none) throw StateError("No value");
    _next = #_none;
    return result;
  }

  Object _error(String message) {
    if (_next == #_none) {
      return StateError("No value");
    }
    return FormatException(message, _next);
  }

  @override
  void expectArray() => tryArray() || (throw _error("Not a JSON array"));

  @override
  bool expectBool() => tryBool() ?? (throw _error("Not an boolean"));

  @override
  double expectDouble() => tryDouble() ?? (throw _error("Not a double"));

  @override
  int expectInt() => tryInt() ?? (throw _error("Not an integer"));

  @override
  void expectNull() => tryNull() || (throw _error("Not null"));

  @override
  num expectNum() => tryNum() ?? (throw _error("Not a number"));

  @override
  void expectObject() => tryObject() || (throw _error("Not a JSON object"));

  @override
  String expectString() => tryString() ?? (throw _error("Not a string"));

  @override
  bool hasNext() {
    if (_next == #_none) {
      var stack = _stack;
      _ListStack list;
      if (stack != null && (list = stack.asList) != null) {
        if (list.hasNext) {
          _next = list.moveNext();
          return true;
        }
        _stack = stack.next;
        _next = #_none;
        return false;
      }
    }
    throw StateError("Not before a JSON array element");
  }

  @override
  String nextKey() {
    if (_next == #_none) {
      var stack = _stack;
      if (stack != null && stack.isMap) {
        var map = stack.asMap;
        var key = map.nextKey();
        if (key != null) {
          _next = map.valueOf(key);
          return key;
        }
        _stack = stack.next;
        _next = #_none;
        return null;
      }
    }
    throw StateError("Not before a JSON object key");
  }

  @override
  bool tryArray() {
    var current = _next;
    if (current is List<dynamic>) {
      _next = #_none;
      _stack = _ListStack(current, _stack);
      return true;
    }
    if (current == #_none) {
      throw StateError("No value");
    }
    return false;
  }

  @override
  bool /*?*/ tryBool() {
    var current = _next;
    if (current is bool) {
      _next = #_none;
      return current;
    }
    if (current == #_none) {
      throw StateError("No value");
    }
    return null;
  }

  @override
  double /*?*/ tryDouble() {
    var current = _next;
    if (current is num) {
      _next = #_none;
      return current.toDouble();
    }
    if (current == #_none) {
      throw StateError("No value");
    }
    return null;
  }

  @override
  int /*?*/ tryInt() {
    var current = _next;
    if (current is int) {
      _next = #_none;
      return current;
    }
    return null;
  }

  @override
  String /*?*/ tryKey(List<String> candidates) {
    if (_next == #_none) {
      var stack = _stack;
      _MapStack /*?*/ map;
      if (stack != null && (map = stack.asMap) != null) {
        var key = map.peekKey();
        if (key != null) {
          var index = candidates.indexOf(key);
          if (index >= 0) {
            map.moveNext();
            _next = map.valueOf(key);
            return candidates[index];
          }
        }
        return null;
      }
    }
    throw StateError("Not before a JSON object key");
  }

  @override
  bool tryNull() {
    var current = _next;
    if (current == null) {
      _next = #_none;
      return true;
    }
    if (current == #_none) {
      throw StateError("No value");
    }
    return false;
  }

  @override
  num /*?*/ tryNum() {
    var current = _next;
    if (current is num) {
      _next = #_none;
      return current;
    }
    if (current == #_none) {
      throw StateError("No value");
    }
    return null;
  }

  @override
  bool tryObject() {
    var current = _next;
    if (current is Map<String, dynamic>) {
      _next = #_none;
      _stack = _MapStack(current, _stack);
      return true;
    }
    if (current == #_none) {
      throw StateError("No value");
    }
    return false;
  }

  @override
  String /*?*/ tryString() {
    var current = _next;
    if (current is String) {
      _next = #_none;
      return current;
    }
    if (current == #_none) {
      throw StateError("No value");
    }
    return null;
  }

  @override
  void skipAnyValue() {
    if (_next == #_none) {
      throw StateError("No value");
    }
    _next = #_none;
  }

  @override
  void skipArray() {
    var stack = _stack;
    do {
      if (stack.isList) {
        _stack = stack.next;
        _next = #_none;
        return;
      }
      stack = stack.next;
    } while (stack != null);
    throw StateError("Not inside a JSON array");
  }

  @override
  void skipObject() {
    var stack = _stack;
    do {
      if (stack.isMap) {
        _stack = stack.next;
        _next = #_none;
        return;
      }
      stack = stack.next;
    } while (stack != null);
    throw StateError("Not inside a JSON object");
  }

  @override
  bool skipObjectEntry() {
    if (_next == #_none) {
      var stack = _stack?.asMap;
      if (stack != null) {
        if (stack.nextKey() == null) {
          _stack = stack.next;
          return false;
        }
        return true;
      }
    }
    throw StateError("Not before a JSON object key");
  }

  @override
  JsonObjectReader copy() => JsonObjectReader._(_next, _stack.copy());

  @override
  void expectAnyValue(JsonSink sink) {
    void emitValue() {
      if (tryObject()) {
        sink.startObject();
        String key;
        while ((key = nextKey()) != null) {
          sink.addKey(key);
          emitValue();
        }
        return;
      }
      if (tryArray()) {
        sink.startArray();
        while (hasNext()) {
          emitValue();
        }
        return;
      }
      if (tryNull()) {
        sink.addNull();
      }
      var number = tryNum();
      if (number != null) {
        sink.addNumber(number);
        return;
      }
      var boolean = tryBool();
      if (boolean != null) {
        sink.addBool(boolean);
        return;
      }
      var string = tryString();
      if (string != null) {
        sink.addString(string);
        return;
      }
      throw _error("Not a JSON value");
    }

    emitValue();
  }
}

abstract class _Stack {
  final _Stack next;
  _Stack(this.next);

  bool get isMap => false;
  bool get isList => false;
  _MapStack get asMap => null;
  _ListStack get asList => null;

  _Stack copy();
}

class _ListStack extends _Stack {
  final List<dynamic> elements;
  int index = 0;
  _ListStack(List<dynamic> list, _Stack parent)
      : elements = list,
        super(parent);

  bool get isList => true;
  _ListStack get asList => this;

  bool get hasNext => index < elements.length;
  dynamic peek() => hasNext ? elements[index] : null;
  dynamic moveNext() => hasNext ? elements[index++] : null;

  _ListStack copy() => _ListStack(elements, next?.copy())..index = index;
}

class _MapStack extends _Stack {
  final Map<String, dynamic> map;
  final List<String> keys;
  int index;

  _MapStack(Map<String, dynamic> map, _Stack parent)
      : this._(map, map.keys.toList(), 0, parent);

  _MapStack._(this.map, this.keys, this.index, _Stack parent) : super(parent);

  String /*?*/ nextKey() => (index < keys.length) ? keys[index++] : null;

  String /*?*/ peekKey() => (index < keys.length) ? keys[index] : null;

  void moveNext() {
    index++;
  }

  dynamic valueOf(String key) => map[key];

  bool get isMap => true;
  _MapStack get asMap => this;

  _MapStack copy() => _MapStack._(map, keys, index, next?.copy());
}
