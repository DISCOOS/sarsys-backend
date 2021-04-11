extension IterableX<T> on Iterable<T> {
  T get firstOrNull => isNotEmpty ? first : null;
  T get lastOrNull => isNotEmpty ? last : null;
}
