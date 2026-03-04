class MarketplaceException implements Exception {
  const MarketplaceException(this.message);

  final String message;

  @override
  String toString() => message;
}
