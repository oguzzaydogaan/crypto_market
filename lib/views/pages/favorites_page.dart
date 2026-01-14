import 'package:flutter/material.dart';
import 'package:crypto_market/services/signalr_service.dart';
import 'package:crypto_market/services/coin_service.dart';
import 'package:crypto_market/models/coin_model.dart';
import 'package:crypto_market/components/coin_explorer.dart'; // Yeni widget

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final CoinService _coinService = CoinService();
  final SignalRService _signalRService = SignalRService();

  List<CoinModel> _allFavorites = [];
  Map<String, dynamic> liveData = {};
  Set<int> _favoriteCoinIds = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    var coins = await _coinService.getFavoriteCoins();

    if (mounted) {
      setState(() {
        _allFavorites = coins;
        _favoriteCoinIds = coins.map((e) => e.id).toSet();
        isLoading = false;
      });
    }

    if (_allFavorites.isEmpty) return;

    _signalRService.onTickerReceived = (data) {
      // Sadece listedeki coinler için state güncelle (Performans için)
      if (_allFavorites.any((c) => c.symbol == data["s"]) && mounted) {
        setState(() {
          liveData[data["s"]] = data;
        });
      }
    };
    await _signalRService.connect();
  }

  Future<void> _toggleFavorite(int coinId) async {
    // Favorilerden çıkarma işlemi
    bool success = await _coinService.toggleFavoriteCoin(coinId);
    if (success) {
      _initializeApp(); // Listeyi yenile (Çıkarılan listeden gitmeli)
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Center(child: CircularProgressIndicator(color: Colors.teal));

    return CoinExplorer(
      coins: _allFavorites,
      liveData: liveData,
      favoriteCoinIds: _favoriteCoinIds,
      onToggleFavorite: _toggleFavorite,
      onRefresh: _initializeApp,
      extraAction: null, // Favorilerde ekleme butonu yok
    );
  }
}
