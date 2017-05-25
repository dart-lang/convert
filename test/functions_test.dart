// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';

import 'package:convert/convert.dart';

void main() {
  group("bytesFromStream()", () {
    test("concatenates all byte chunks", () {
      expect(bytesFromStream(new Stream.fromIterable([[1, 2, 3], [4, 5, 6], [], [7]])),
          completion(equals([1, 2, 3, 4, 5, 6, 7])));
    });

    test("handles an empty stream", () {
      expect(bytesFromStream(new Stream.empty()), completion(isEmpty));
    });

    test("clamps integers to byte range", () {
      expect(bytesFromStream(new Stream.fromIterable([[-1, -2, 256, 1027]])),
          completion(equals([255, 254, 0, 3])));
    });

    test("forwards errors to the future", () {
      expect(bytesFromStream(new Stream.fromFuture(new Future.error("oh no!"))),
          throwsA("oh no!"));
    });
  });

  group("stringFromStream()", () {
    test("concatenates all strings", () {
      expect(stringFromStream(new Stream.fromIterable(["foo", "bar", "", "x"])),
          completion(equals("foobarx")));
    });

    test("handles an empty stream", () {
      expect(stringFromStream(new Stream.empty()), completion(isEmpty));
    });

    test("forwards errors to the future", () {
      expect(stringFromStream(new Stream.fromFuture(new Future.error("oh no!"))),
          throwsA("oh no!"));
    });
  });
}
