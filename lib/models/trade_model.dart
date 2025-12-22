class TradeModel {
  final double price;
  final double amount;
  final DateTime time;
  final bool isBuyerMaker; // true = Satış (Maker Buyer), false = Alış

  TradeModel({
    required this.price,
    required this.amount,
    required this.time,
    required this.isBuyerMaker,
  });

  factory TradeModel.fromJson(Map<String, dynamic> json) {
    // Fiyat: 'price' veya 'p'
    double parsedPrice =
        double.tryParse(
          json['price']?.toString() ?? json['p']?.toString() ?? '0',
        ) ??
        0.0;

    // Miktar: 'qty', 'amount' veya 'q'
    double parsedAmount =
        double.tryParse(
          json['qty']?.toString() ??
              json['amount']?.toString() ??
              json['q']?.toString() ??
              '0',
        ) ??
        0.0;

    // Zaman: 'time' veya 'T'
    int timeInt = json['time'] ?? json['t'] ?? 0;
    DateTime parsedTime = DateTime.fromMillisecondsSinceEpoch(timeInt);

    // Alış/Satış Yönü: 'isBuyerMaker' veya 'm'
    bool parsedIsBuyerMaker = json['isBuyerMaker'] ?? json['m'] ?? false;

    return TradeModel(
      price: parsedPrice,
      amount: parsedAmount,
      time: parsedTime,
      isBuyerMaker: parsedIsBuyerMaker,
    );
  }
}
