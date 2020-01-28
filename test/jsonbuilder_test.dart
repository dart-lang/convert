// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:test/test.dart";
import "package:convert/convert.dart";

void main() {
  JsonReader read(String source) => JsonReader.fromString(source);

  test("primitive values", () {
    expect(jsonInt(read("1")), 1);
    expect(jsonDouble(read("1.5")), 1.5);
    expect(jsonString(read('"str"')), "str");
    expect(jsonBool(read("false")), false);
  });

  test("optional values", () {
    expect(jsonOptional(jsonInt)(read("1")), 1);
    expect(jsonOptional(jsonInt)(read("null")), null);
    expect(jsonOptional(jsonDouble)(read("1.5")), 1.5);
    expect(jsonOptional(jsonDouble)(read("null")), null);
    expect(jsonOptional(jsonString)(read('"str"')), "str");
    expect(jsonOptional(jsonString)(read("null")), null);
    expect(jsonOptional(jsonBool)(read("false")), false);
    expect(jsonOptional(jsonBool)(read("null")), null);
  });

  test("array values", () {
    var jsonStringArray = jsonArray(jsonString);
    expect(jsonStringArray(read('[]')), []);

    expect(jsonStringArray(read('["a"]')), ["a"]);

    expect(jsonStringArray(read('["a", "b"]')), ["a", "b"]);

    expect(jsonArray(jsonStringArray)(read('[[], ["a"], ["a", "b"]]')), [
      [],
      ["a"],
      ["a", "b"]
    ]);
  });

  test("array index builder", () {
    var intStringArray =
        jsonIndexedArray((index) => index.isEven ? jsonInt : jsonString);
    expect(intStringArray(read('[]')), []);
    expect(intStringArray(read('[1, "2", 3, "4", 5]')), [1, "2", 3, "4", 5]);
  });

  test("array fold builder", () {
    var foldArray = jsonFoldArray(jsonInt, () => 0, (int a, int b) => a + b);
    expect(foldArray(read('[]')), 0);
    expect(foldArray(read('[1]')), 1);
    expect(foldArray(read('[1, 2, 3, 4, 5]')), 15);
  });

  test("object values", () {
    expect(jsonObject(jsonString)(read('{}')), {});

    expect(jsonObject(jsonInt)(read('{"a": 2}')), {"a": 2});

    expect(jsonObject(jsonInt)(read('{"a": 1, "b": 2}')), {"a": 1, "b": 2});

    expect(
        jsonObject(jsonObject(jsonInt))(
            read('{"0": {}, "2": {"a": 1, "b": 2}}')),
        {
          "0": {},
          "2": {"a": 1, "b": 2}
        });
  });

  test("object key builder", () {
    var objectKeys =
        jsonStruct({"x": jsonInt, "y": jsonString, "z": jsonArray(jsonBool)});
    expect(objectKeys(read('{}')), {});
    expect(objectKeys(read('{"x": 1}')), {"x": 1});
    expect(objectKeys(read('{"other": 3.14, "x": 1}')), {"x": 1});
    expect(objectKeys(read('{"y": "str", "x": 1}')), {"x": 1, "y": "str"});
    expect(objectKeys(read('{"y": "str", "x": 1, "z": [true, false]}')), {
      "x": 1,
      "y": "str",
      "z": [true, false]
    });
    var objectKeysDefault = jsonStruct(
        {"x": jsonInt, "y": jsonString, "z": jsonArray(jsonBool)}, jsonDouble);
    expect(objectKeysDefault(read('{"other": 3.14, "x": 1}')),
        {"x": 1, "other": 3.14});
  });

  test("object fold builder", () {
    var objectFold =
        jsonFoldObject(jsonInt, () => 0, (int a, String key, int b) => a + b);
    expect(objectFold(read('{}')), 0);
    expect(objectFold(read('{"x": 1}')), 1);
    expect(objectFold(read('{"x": 1, "y": 2, "z": 3}')), 6);
    var objectFoldKey = jsonFoldObject(
        jsonInt, () => [], (List a, String key, int b) => a..add(key)..add(b));
    expect(objectFoldKey(read('{"x": 1, "y": 2, "z": 3}')),
        ["x", 1, "y", 2, "z", 3]);
  });

  test("date build", () {
    var date = DateTime.now();
    var dateString = date.toString();
    expect(jsonDateString(read('"$dateString"')), date);
  });

  test("uri build", () {
    var uri = Uri.parse("https://example.com/pathway");
    var uriString = uri.toString();
    expect(jsonUriString(read('"$uriString"')), uri);
  });
}
