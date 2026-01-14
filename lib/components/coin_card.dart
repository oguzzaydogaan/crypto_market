import 'package:flutter/material.dart';
import '../models/coin_model.dart';
import '../views/pages/coin_page.dart';

class CoinCard extends StatelessWidget {
  final CoinModel coin;
  final Map<String, dynamic>? liveData;
  final bool isFavorite;
  final bool isGrid; // Görünüm modu
  final VoidCallback onToggleFavorite;

  const CoinCard({
    super.key,
    required this.coin,
    required this.liveData,
    required this.isFavorite,
    required this.isGrid,
    required this.onToggleFavorite,
  });

  // Veriyi ayrıştıran yardımcı metod
  Map<String, dynamic> _parseData() {
    String price = "...";
    String percent = "0.00%";
    Color percentColor = Colors.grey;
    IconData trendIcon = Icons.remove;

    if (liveData != null) {
      double priceVal = double.tryParse(liveData!["c"].toString()) ?? 0.0;
      price = "\$${priceVal.toStringAsFixed(priceVal < 1 ? 4 : 2)}";

      double percentVal = double.tryParse(liveData!["P"].toString()) ?? 0.0;
      percent =
          "${percentVal >= 0 ? '+' : ''}${percentVal.toStringAsFixed(2)}%";

      if (percentVal > 0) {
        percentColor = Colors.green;
        trendIcon = Icons.trending_up;
      } else if (percentVal < 0) {
        percentColor = Colors.red;
        trendIcon = Icons.trending_down;
      }
    }
    return {
      "price": price,
      "percent": percent,
      "percentColor": percentColor,
      "trendIcon": trendIcon,
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = _parseData();
    final String shortSymbol = coin.symbol.replaceAll("USDT", "");

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CoinPage(coin: coin)),
        );
      },
      child: isGrid
          ? _buildGridCard(context, shortSymbol, data)
          : _buildListCard(context, shortSymbol, data),
    );
  }

  // --- GRID GÖRÜNÜMÜ ---
  Widget _buildGridCard(
    BuildContext context,
    String shortSymbol,
    Map<String, dynamic> data,
  ) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getCoinIcon(shortSymbol, size: 32),
                const SizedBox(height: 8),
                Text(
                  shortSymbol,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  coin.name,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  data["price"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (data["percentColor"] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    data["percent"],
                    style: TextStyle(
                      color: data["percentColor"],
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : Colors.grey.shade300,
                size: 24,
              ),
              onPressed: onToggleFavorite,
            ),
          ),
        ],
      ),
    );
  }

  // --- LISTE GÖRÜNÜMÜ ---
  Widget _buildListCard(
    BuildContext context,
    String shortSymbol,
    Map<String, dynamic> data,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _getCoinIcon(shortSymbol),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shortSymbol,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data["price"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (data["percentColor"] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data["trendIcon"],
                        size: 14,
                        color: data["percentColor"],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data["percent"],
                        style: TextStyle(
                          color: data["percentColor"],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : Colors.grey.shade300,
                size: 28,
              ),
              onPressed: onToggleFavorite,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCoinIcon(String symbol, {double size = 24}) {
    Color color;
    IconData icon;
    switch (symbol) {
      case "BTC":
        color = Colors.orange;
        icon = Icons.currency_bitcoin;
        break;
      case "ETH":
        color = Colors.indigo;
        icon = Icons.token;
        break;
      case "SOL":
        color = Colors.purple;
        icon = Icons.sunny;
        break;
      case "DOGE":
        color = Colors.brown;
        icon = Icons.pets;
        break;
      case "BNB":
        color = Colors.amber;
        icon = Icons.hexagon;
        break;
      default:
        color = Colors.teal;
        icon = Icons.monetization_on;
    }
    return Container(
      padding: EdgeInsets.all(size / 2.4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}
