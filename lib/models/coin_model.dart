class CoinModel {
  final int id;
  final String symbol;
  final String name;

  CoinModel({required this.id, required this.symbol, required this.name});

  factory CoinModel.fromJson(Map<String, dynamic> json) {
    return CoinModel(
      id: json['id'] ?? 0,
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
