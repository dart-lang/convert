// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert";
import "dart:typed_data";

import "package:test/test.dart";
import "package:convert/convert.dart";

void main() {
  for (var kind in ["string", "utf8", "object"]) {
    group(kind, () {
      var reader = {
        "string": mkStringReader,
        "utf8": mkByteReader,
        "object": mkObjectReader,
      }[kind] /*!*/;
      testReader(reader);
    });
  }
}

void testReader(JsonReader Function(String source) read) {
  test("parse int", () {
    var g1 = read("42");
    expect(g1.expectInt(), 42);
    var g2 = read("-42");
    expect(g2.expectInt(), -42);
    var g3 = read("true");
    expect(() => g3.expectInt(), throwsFormatException);
  });
  test("parse num", () {
    var g1 = read("42");
    expect(g1.expectNum(), same(42));
    var g2 = read("-42.55e+1");
    expect(g2.expectNum(), -425.5);
    var g3 = read("true");
    expect(() => g3.expectNum(), throwsFormatException);
  });
  test("parse double", () {
    var g1 = read("42");
    expect(g1.expectDouble(), same(42.0));
    var g2 = read("-42.55e+1");
    expect(g2.expectDouble(), -425.5);
    var g3 = read("true");
    expect(() => g3.expectDouble(), throwsFormatException);
  });
  test("parse bool", () {
    var g1 = read("true");
    expect(g1.expectBool(), true);
    var g2 = read("false");
    expect(g2.expectBool(), false);
    var g3 = read("42");
    expect(() => g3.expectBool(), throwsFormatException);
  });
  test("parse string", () {
    var g1 = read(r'"a"');
    expect(g1.expectString(), "a");
    var g2 = read(r'""');
    expect(g2.expectString(), "");
    var g2a = read(r'"\n"');
    expect(g2a.expectString(), "\n");
    var g3 = read(r'"\b\t\n\r\f\\\"\/\ufffd"');
    expect(g3.expectString(), "\b\t\n\r\f\\\"/\ufffd");
  });

  test("parse array", () {
    var g1 = read(r'[12, "str", true]');
    g1.expectArray();
    expect(g1.hasNext(), true);
    expect(g1.expectInt(), 12);
    expect(g1.hasNext(), true);
    expect(g1.expectString(), "str");
    expect(g1.hasNext(), true);
    expect(g1.expectBool(), true);
    expect(g1.hasNext(), false);
  });

  test("parse array empty", () {
    var g1 = read(r'[]');
    g1.expectArray();
    expect(g1.hasNext(), false);
  });

  test("parse array nested", () {
    var g1 = read(r'[[12, 13], [], ["str", ["str2"]], 1]');
    g1.expectArray(); // [
    expect(g1.hasNext(), true);
    g1.expectArray(); // [[
    expect(g1.hasNext(), true); // [[
    expect(g1.expectInt(), 12);
    expect(g1.hasNext(), true); // [[,
    expect(g1.expectInt(), 13);
    expect(g1.hasNext(), false); // [[,]
    expect(g1.hasNext(), true); // [[,],
    g1.expectArray(); // [[,],[
    expect(g1.hasNext(), false); // [[,],[]
    expect(g1.hasNext(), true); // [[,],[],
    g1.expectArray(); // [[,],[], [
    expect(g1.hasNext(), true);
    expect(g1.expectString(), "str");
    g1.skipArray(); // [[,],[], [...]
    expect(g1.hasNext(), true); // [[,],[], [...],
    expect(g1.expectInt(), 1);
    expect(g1.hasNext(), false); // [[,],[], [...],]
  });

  test("parse object", () {
    var g1 = read(r' { "a": true, "b": 42 } ');
    g1.expectObject();
    expect(g1.nextKey(), "a");
    expect(g1.expectBool(), true);
    expect(g1.nextKey(), "b");
    expect(g1.expectInt(), 42);
    expect(g1.nextKey(), null);
  });

  test("parse empty object", () {
    var g1 = read(r' { } ');
    g1.expectObject();
    expect(g1.nextKey(), null);
  });

  test("parse nested object", () {
    var g1 = read(r' { "a" : {"b": true}, "c": { "d": 42 } } ');
    g1.expectObject();
    expect(g1.nextKey(), "a");
    g1.expectObject();
    expect(g1.nextKey(), "b");
    expect(g1.expectBool(), true);
    expect(g1.nextKey(), null);
    expect(g1.nextKey(), "c");
    g1.expectObject();
    expect(g1.nextKey(), "d");
    expect(g1.expectInt(), 42);
    expect(g1.nextKey(), null);
    expect(g1.nextKey(), null);
  });

  test("whitepsace", () {
    var ws = " \n\r\t";
    // JSON: {"a":[1,2.5]}  with all whitespaces between all tokens.
    var g1 = read('$ws{$ws"a"$ws:$ws[${ws}1$ws,${ws}2.5$ws]$ws}');
    g1.expectObject();
    expect(g1.nextKey(), "a");
    g1.expectArray();
    expect(g1.hasNext(), true);
    expect(g1.expectInt(), 1);
    expect(g1.hasNext(), true);
    expect(g1.expectDouble(), 2.5);
    expect(g1.hasNext(), false);
    expect(g1.nextKey(), null);
  });

  test("peekKey", () {
    var g1 = read(r'{"a": 42, "abe": 42, "abc": 42, "b": 42}');
    const candidates = <String>["a", "abc", "abe"]; // Sorted.
    g1.expectObject();
    expect(g1.tryKey(candidates), same("a"));
    expect(g1.expectInt(), 42);
    expect(g1.tryKey(candidates), same("abe"));
    expect(g1.expectInt(), 42);
    expect(g1.tryKey(candidates), same("abc"));
    expect(g1.expectInt(), 42);
    expect(g1.tryKey(candidates), null);
    expect(g1.nextKey(), "b");
    expect(g1.expectInt(), 42);
    expect(g1.tryKey(candidates), null);
    expect(g1.nextKey(), null);
  });

  test("skipAnyValue", () {
    var g1 = read(r'{"a":[[[[{"a":2}]]]],"b":2}');
    g1.expectObject();
    expect(g1.nextKey(), "a");
    g1.skipAnyValue();
    expect(g1.nextKey(), "b");
    expect(g1.expectInt(), 2);
    expect(g1.nextKey(), null);
  });

  test("expetAnyValue", () {
    var g1 = read(r'{"a":["test"],"b":2}');
    g1.expectObject();
    expect(g1.nextKey(), "a");
    var skipped = g1.expectAnyValueSource();
    expect(g1.nextKey(), "b");
    expect(g1.expectInt(), 2);
    expect(g1.nextKey(), null);

    if (skipped is StringSlice) {
      expect(skipped.toString(), r'["test"]');
    } else if (skipped is Uint8List) {
      expect(skipped, r'["test"]'.codeUnits);
    } else {
      expect(skipped, ["test"]);
    }
  });

  test("Skip object entry", () {
    var g1 = read(r'[{"a":["test"],"b":42,"c":"str"},37]');
    g1.expectArray();
    expect(g1.hasNext(), true);
    g1.expectObject();
    expect(g1.tryKey(["a","c"]), "a");
    g1.skipAnyValue();
    expect(g1.tryKey(["a","c"]), null);
    expect(g1.skipObjectEntry(), true);
    expect(g1.tryKey(["a","c"]), "c");
    g1.skipAnyValue();
    expect(g1.tryKey(["a","c"]), null);
    expect(g1.skipObjectEntry(), false);
    expect(g1.hasNext(), true);
    expect(g1.expectInt(), 37);
    expect(g1.hasNext(), false);
  });

  test("copy", () {
    var g1 = read(r'{"a": 1, "b": {"c": ["d"]}, "c": 2}');
    expect(g1.tryObject(), true);
    expect(g1.nextKey(), "a");
    expect(g1.expectInt(), 1);
    expect(g1.nextKey(), "b");
    var g2 = g1.copy();
    expect(g1.checkObject(), true);
    g1.skipAnyValue();
    expect(g1.nextKey(), "c");
    expect(g1.expectInt(), 2);
    expect(g1.nextKey(), null);

    expect(g2.tryObject(), true);
    expect(g2.nextKey(), "c");
    expect(g2.tryArray(), true);
    expect(g2.hasNext(), true);
    expect(g2.expectString(), "d");
    expect(g2.hasNext(), false);
    expect(g2.nextKey(), null);

    expect(g2.nextKey(), "c");
    expect(g2.expectInt(), 2);
    expect(g2.nextKey(), null);
  });
}

JsonReader mkStringReader(String source) => JsonReader.fromString(source);
JsonReader mkByteReader(String source) =>
    JsonReader.fromUtf8(utf8.encoder.convert(source));
JsonReader mkObjectReader(String source) =>
    JsonReader.fromObject(json.decode(source));
