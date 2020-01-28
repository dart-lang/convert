// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert";
import "package:test/test.dart";
import "package:convert/convert.dart";

import "src/json_data.dart";

void main() {
  test("simple rebuild", () {
    var simple = jsonDecode(simpleJson);
    var builtSimple;
    JsonReader.fromString(simpleJson).expectAnyValue(jsonObjectWriter((result){
      builtSimple = result;
    }));
    expect(simple, builtSimple);
  });

  test("simple toString", () {
    var simple = jsonEncode(jsonDecode(simpleJson));
    var buffer = StringBuffer();
    JsonReader.fromString(simpleJson).expectAnyValue(jsonStringWriter(buffer));
    expect(simple, buffer.toString());
  });
}