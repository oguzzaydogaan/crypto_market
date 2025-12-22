class CoinModel {
  final int id;
  final String symbol;
  final String name;
  final bool isFavorite;

  CoinModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.isFavorite,
  });

  factory CoinModel.fromJson(Map<String, dynamic> json) {
    return CoinModel(
      id: json['id'] ?? 0,
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}
