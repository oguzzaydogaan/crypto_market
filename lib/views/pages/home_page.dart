import 'package:flutter/material.dart';
import 'package:crypto_market/services/signalr_service.dart';
import 'package:crypto_market/services/coin_service.dart';
import 'package:crypto_market/models/coin_model.dart';
import 'package:crypto_market/components/coin_explorer.dart'; // Yeni widget

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CoinService _coinService = CoinService();
  final SignalRService _signalRService = SignalRService();

  List<CoinModel> _allCoins = [];
  Map<String, dynamic> liveData = {};
  Set<int> _favoriteCoinIds = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final results = await Future.wait([
        _coinService.getAllCoins(),
        _coinService.getFavoriteCoins(),
      ]);

      if (mounted) {
        setState(() {
          _allCoins = results[0];
          _favoriteCoinIds = results[1].map((e) => e.id).toSet();
          isLoading = false;
        });
      }

      if (_allCoins.isEmpty) return;

      _signalRService.onTickerReceived = (data) {
        if (mounted) {
          setState(() {
            liveData[data["s"]] = data;
          });
        }
      };
      await _signalRService.connect();
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFavorite(int coinId) async {
    bool isFav = _favoriteCoinIds.contains(coinId);
    setState(() {
      if (isFav)
        _favoriteCoinIds.remove(coinId);
      else
        _favoriteCoinIds.add(coinId);
    });

    bool success = await _coinService.toggleFavoriteCoin(coinId);
    if (!success && mounted) {
      // Hata olursa geri al
      setState(() {
        if (isFav)
          _favoriteCoinIds.add(coinId);
        else
          _favoriteCoinIds.remove(coinId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("İşlem başarısız oldu")));
    }
  }

  // Coin Ekleme Dialogu
  void _showAddCoinDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController symbolController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Coin", style: TextStyle(color: Colors.teal)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Coin Name",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                ),
                cursorColor: Colors.teal,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: symbolController,
                decoration: const InputDecoration(
                  labelText: "Symbol (BTCUSDT)",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                ),
                cursorColor: Colors.teal,
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    symbolController.text.isEmpty)
                  return;
                bool success = await _coinService.addCoin(
                  nameController.text.trim(),
                  symbolController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("Success!")));
                    _initializeApp(); // Listeyi yenile
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to add coin.")),
                    );
                  }
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Center(child: CircularProgressIndicator(color: Colors.teal));

    // Home Page'e özel "Ekleme Butonu"
    final addCoinButton = Container(
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.add, color: Colors.teal),
        onPressed: _showAddCoinDialog,
        tooltip: "Add New Coin",
      ),
    );

    return CoinExplorer(
      coins: _allCoins,
      liveData: liveData,
      favoriteCoinIds: _favoriteCoinIds,
      onToggleFavorite: _toggleFavorite,
      onRefresh: _initializeApp,
      extraAction: addCoinButton, // Butonu parametre olarak geçiyoruz
    );
  }
}
