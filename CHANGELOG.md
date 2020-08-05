## 2.2.0-nullsafety

Pre-release for the null safety migration of this package.

Note that 2.2.0 may not be the final stable null safety release version, we
reserve the right to release it as a 3.0.0 breaking change.

This release will be pinned to only allow pre-release sdk versions starting from
2.10.0-2.0.dev, which is the first version where this package will appear in the
null safety allow list.

## 2.1.1

 * Fixed a DDC compilation regression for consumers using the Dart 1.x SDK that was introduced in `2.1.0`.

## 2.1.0

 * Added an `IdentityCodec<T>` which implements `Codec<T,T>` for use as default
   value for in functions accepting an optional `Codec` as parameter.

## 2.0.2

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 2.0.1

* `PercentEncoder` no longer encodes digits. This follows the specified
  behavior.

## 2.0.0

**Note**: No new APIs have been added in 2.0.0. Packages that would use 2.0.0 as
a lower bound should use 1.0.0 instead—for example, `convert: ">=1.0.0 <3.0.0"`.

* `HexDecoder`, `HexEncoder`, `PercentDecoder`, and `PercentEncoder` no longer
  extend `ChunkedConverter`.

## 1.1.1

* Fix all strong-mode warnings.

## 1.1.0

* Add `AccumulatorSink`, `ByteAccumulatorSink`, and `StringAccumulatorSink`
  classes for providing synchronous access to the output of chunked converters.

## 1.0.1

* Small improvement in percent decoder efficiency.

## 1.0.0

* Initial version
