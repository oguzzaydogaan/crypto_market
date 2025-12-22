import 'package:crypto_market/components/search_field.dart'; // Oluşturduğumuz search widget importu
import 'package:crypto_market/models/coin_model.dart';
import 'package:crypto_market/views/pages/coin_page.dart';
import 'package:flutter/material.dart';
import 'package:crypto_market/services/signalr_service.dart';
import 'package:crypto_market/services/coin_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final CoinService _coinService = CoinService();
  final SignalRService _signalRService = SignalRService();

  // Tüm favoriler (API'den gelen ham liste)
  List<CoinModel> _allFavorites = [];
  // Ekranda filtrelenip gösterilen liste
  List<CoinModel> _filteredFavorites = [];

  // Canlı verileri tutan map
  Map<String, dynamic> _liveData = {};

  // Favori durumunu hızlı yönetmek için ID seti
  Set<int> _favoriteCoinIds = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Favorileri API'den çek
    var coins = await _coinService.getFavoriteCoins();

    if (mounted) {
      setState(() {
        _allFavorites = coins;
        _filteredFavorites = coins;
        _favoriteCoinIds = coins.map((e) => e.id).toSet();
        _isLoading = false;
      });
    }

    if (_allFavorites.isEmpty) return;

    _signalRService.onTickerReceived = (data) {
      String incomingSymbol = data["s"];
      bool isListed = _allFavorites.any((c) => c.symbol == incomingSymbol);

      if (isListed && mounted) {
        setState(() {
          _liveData[incomingSymbol] = data;
        });
      }
    };

    await _signalRService.connect();
  }

  void _runFilter(String keyword) {
    List<CoinModel> results = [];
    if (keyword.isEmpty) {
      results = _allFavorites;
    } else {
      results = _allFavorites
          .where(
            (coin) =>
                coin.name.toLowerCase().contains(keyword.toLowerCase()) ||
                coin.symbol.toLowerCase().contains(keyword.toLowerCase()),
          )
          .toList();
    }

    setState(() {
      _filteredFavorites = results;
    });
  }

  Future<void> _toggleFavorite(int coinId) async {
    bool isFav = _favoriteCoinIds.contains(coinId);

    setState(() {
      if (isFav) {
        _favoriteCoinIds.remove(coinId);
      } else {
        _favoriteCoinIds.add(coinId);
      }
    });

    bool success = await _coinService.toggleFavoriteCoin(coinId);

    if (!success && mounted) {
      setState(() {
        if (isFav) {
          _favoriteCoinIds.add(coinId);
        } else {
          _favoriteCoinIds.remove(coinId);
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("İşlem başarısız oldu")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_allFavorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_border, size: 64, color: Colors.grey),
            const SizedBox(height: 10),
            const Text("Favori listeniz boş."),
            TextButton(onPressed: _initializeApp, child: const Text("Yenile")),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          CoinSearchField(onChanged: _runFilter),
          Expanded(
            child: _filteredFavorites.isEmpty
                ? const Center(child: Text("Sonuç bulunamadı"))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 10),
                    itemCount: _filteredFavorites.length,
                    itemBuilder: (context, index) {
                      CoinModel coin = _filteredFavorites[index];
                      var liveDataForCoin = _liveData[coin.symbol];

                      return _buildCoinCard(coin, liveDataForCoin);
                    },
                  ),
          ),
        ],
      );
    }
  }

  Widget _buildCoinCard(CoinModel coin, dynamic data) {
    String price = "...";
    String percent = "0.00%";
    Color percentColor = Colors.grey;
    IconData trendIcon = Icons.remove;

    if (data != null) {
      double priceVal = double.tryParse(data["c"].toString()) ?? 0.0;
      price = "\$${priceVal.toStringAsFixed(priceVal < 1 ? 4 : 2)}";

      double percentVal = double.tryParse(data["P"].toString()) ?? 0.0;
      percent =
          "${percentVal >= 0 ? '+' : ''}${percentVal.toStringAsFixed(2)}%";

      if (percentVal > 0) {
        percentColor = Colors.green;
        trendIcon = Icons.trending_up;
      } else if (percentVal < 0) {
        percentColor = Colors.red;
        trendIcon = Icons.trending_down;
      } else {
        percentColor = Colors.grey;
        trendIcon = Icons.remove;
      }
    }

    String shortSymbol = coin.symbol.replaceAll("USDT", "");
    bool isFavorite = _favoriteCoinIds.contains(coin.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CoinPage(coin: coin)),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 3,
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
                    price,
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
                      color: percentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(trendIcon, size: 14, color: percentColor),
                        const SizedBox(width: 4),
                        Text(
                          percent,
                          style: TextStyle(
                            color: percentColor,
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
                  color: isFavorite ? Colors.orange : Colors.grey.shade400,
                  size: 28,
                ),
                onPressed: () => _toggleFavorite(coin.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getCoinIcon(String symbol) {
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
