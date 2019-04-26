import 'dart:convert';

class _IdentityConverter<T> extends Converter<T, T> {
  _IdentityConverter();
  T convert(T input) => input;
}

/// A [Codec] that performs the identity conversion (changing nothing) in both
/// directions.
///
/// The identity codec passes input directly to output in both directions.
/// This class can be used as a base when combining multiple codecs,
/// because fusing the identity codec with any other codec gives the other
/// codec back.
///
/// Note, that when fused with another [Codec] the identity codec disppears.
class IdentityCodec<T> extends Codec<T, T> {
  const IdentityCodec();

  Converter<T, T> get decoder => _IdentityConverter<T>();
  Converter<T, T> get encoder => _IdentityConverter<T>();

  /// Fuse with an other codec.
  ///
  /// Fusing with the identify converter is a no-op, so this always return
  /// [other].
  Codec<T, R> fuse<R>(Codec<T, R> other) => other;
}
