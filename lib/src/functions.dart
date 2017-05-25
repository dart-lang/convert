// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:typed_data/typed_data.dart';

/// Concatenates all bytes from [stream] into a single list.
///
/// Integers outside the range `[0..256)` will be clamped to their lowest 8
/// bytes.
Future<List<int>> bytesFromStream(Stream<List<int>> stream) {
  return stream
    .fold(new Uint8Buffer(), (buffer, chunk) =>
      buffer..addAll(chunk)
    )
    .then((buffer) => new Uint8List.view(buffer.buffer, 0, buffer.lengthInBytes));
}

/// Concatenates all string in [stream] into a single string.
Future<String> stringFromStream(Stream<String> stream) {
  return stream
      .fold(new StringBuffer(), (buffer, string) => buffer..write(string))
      .then((buffer) => buffer.toString());
}
