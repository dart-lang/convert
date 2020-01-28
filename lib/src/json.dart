// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A collection of JSON related operations.
///
/// JSON is a text format which represents an abstract "JSON structure".
///
/// A JSON structure is either a *primitive value*: a number, a string,
/// a boolean or null, or a composite value.
/// The composite value is either a JSON array, a seqeunce of JSON structures,
/// or a JSON object, a sequence of pairs of string keys and JSON structure values.
///
/// Dart typically represents the JSON structure using [List] and [Map] objects
/// for the composite values and [num], [String], [bool] and [Null] values for
/// the primitive values.
///
/// This library provides various ways to operate on a JSON structure without
/// necessarily creating intermediate the Dart lists or maps.
///
/// The [JsonReader] provides a *pull based* approach to investigating and
/// deconstructing a JSON structure, whether it's represented as a string,
/// bytes which are the UTF-8 encoding of such a string, or by Dart object
/// structures.
///
/// The [JsonBuilder] functions provide a way to convert a JSON structure
/// to another kind of value.
///
/// The [JsonSink] provides a *push* based approach to constructing
/// a JSON structure. This can be used to create JSON source or structures
/// from other kinds of values.
library convert.json;

export "json/builder/builder.dart";
export "json/reader/reader.dart";
export "json/sink/sink.dart";
