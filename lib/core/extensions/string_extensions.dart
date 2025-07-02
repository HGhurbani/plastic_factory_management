// plastic_factory_management/lib/core/extensions/string_extensions.dart

extension ShortString on String {
  /// Returns a substring from index 0 with a maximum length of [maxLength].
  /// If the string is shorter than [maxLength], the entire string is returned.
  String shortId([int maxLength = 6]) {
    return length <= maxLength ? this : substring(0, maxLength);
  }
}
