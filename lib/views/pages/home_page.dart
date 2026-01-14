import 'package:crypto_market/components/search_field.dart';
import 'package:crypto_market/models/coin_model.dart';
import 'package:crypto_market/views/pages/coin_page.dart';
import 'package:flutter/material.dart';
import 'package:crypto_market/services/signalr_service.dart';
import 'package:crypto_market/services/coin_service.dart';

// Sıralama Kriterleri
enum SortCriteria { name, price, change }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CoinService _coinService = CoinService();
  final SignalRService _signalRService = SignalRService();

  List<CoinModel> _allCoins = [];
  List<CoinModel> _filteredCoins = [];

  Map<String, dynamic> liveData = {};
  Set<int> _favoriteCoinIds = {};

  bool isLoading = true;

  // --- AYARLAR ---
  SortCriteria _sortCriteria = SortCriteria.price;
  bool _isAscending = false;

  // Görünüm Modu (Liste mi Grid mi?)
  bool _isGridView = false;

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

      var allCoins = results[0];
      var favCoins = results[1];

      if (mounted) {
        setState(() {
          _allCoins = allCoins;
          _filteredCoins = allCoins;
          _favoriteCoinIds = favCoins.map((e) => e.id).toSet();
          isLoading = false;
        });
        _sortCoins();
      }

      if (_allCoins.isEmpty) return;

      _signalRService.onTickerReceived = (data) {
        String incomingSymbol = data["s"];
        if (mounted) {
          setState(() {
            liveData[incomingSymbol] = data;
            if (_sortCriteria != SortCriteria.name) {
              _sortCoins();
            }
          });
        }
      };

      await _signalRService.connect();
    } catch (e) {
      debugPrint("Hata: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _sortCoins() {
    _filteredCoins.sort((a, b) {
      var dataA = liveData[a.symbol];
      var dataB = liveData[b.symbol];
      int compareResult = 0;

      switch (_sortCriteria) {
        case SortCriteria.name:
          compareResult = a.name.compareTo(b.name);
          break;
        case SortCriteria.price:
          double priceA = dataA != null
              ? (double.tryParse(dataA["c"].toString()) ?? 0)
              : 0;
          double priceB = dataB != null
              ? (double.tryParse(dataB["c"].toString()) ?? 0)
              : 0;
          compareResult = priceA.compareTo(priceB);
          break;
        case SortCriteria.change:
          double changeA = dataA != null
              ? (double.tryParse(dataA["P"].toString()) ?? 0)
              : 0;
          double changeB = dataB != null
              ? (double.tryParse(dataB["P"].toString()) ?? 0)
              : 0;
          compareResult = changeA.compareTo(changeB);
          break;
      }
      return _isAscending ? compareResult : -compareResult;
    });
  }

  void _changeSort(SortCriteria criteria) {
    setState(() {
      if (_sortCriteria == criteria) {
        _isAscending = !_isAscending;
      } else {
        _sortCriteria = criteria;
        _isAscending = false;
      }
      _sortCoins();
    });
  }

  void _runFilter(String keyword) {
    List<CoinModel> results = [];
    if (keyword.isEmpty) {
      results = _allCoins;
    } else {
      results = _allCoins
          .where(
            (coin) =>
                coin.name.toLowerCase().contains(keyword.toLowerCase()) ||
                coin.symbol.toLowerCase().contains(keyword.toLowerCase()),
          )
          .toList();
    }
    setState(() {
      _filteredCoins = results;
      _sortCoins();
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
        if (isFav)
          _favoriteCoinIds.add(coinId);
        else
          _favoriteCoinIds.remove(coinId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Process failed!")));
    }
  }

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
                  labelText: "Coin Name (Bitcoin)",
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
                  hintText: "Binance format (BTCUSDT)",
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
                    symbolController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all areas!")),
                  );
                  return;
                }
                bool success = await _coinService.addCoin(
                  nameController.text.trim(),
                  symbolController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Coin added successfully!")),
                    );
                    _initializeApp();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to add coin!")),
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    } else if (_allCoins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 10),
            const Text("No coins found."),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: _showAddCoinDialog,
              icon: const Icon(Icons.add),
              label: const Text("Add Coin"),
            ),
            TextButton(
              onPressed: _initializeApp,
              child: const Text(
                "Refresh",
                style: TextStyle(color: Colors.teal),
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          // --- ARAMA, GÖRÜNÜM BUTONU ve EKLEME BUTONU ---
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Expanded(child: CoinSearchField(onChanged: _runFilter)),

                // Görünüm Değiştirme Butonu (Liste <-> Grid)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      color: Colors.teal,
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                    tooltip: "Change View",
                  ),
                ),

                // Ekleme Butonu
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.teal),
                    onPressed: _showAddCoinDialog,
                    tooltip: "Add New Coin",
                  ),
                ),
              ],
            ),
          ),

          // --- SIRALAMA BUTONLARI ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildSortChip("Name", SortCriteria.name),
                const SizedBox(width: 8),
                _buildSortChip("Price", SortCriteria.price),
                const SizedBox(width: 8),
                _buildSortChip("Change (24h)", SortCriteria.change),
              ],
            ),
          ),

          // --- LİSTE VEYA GRID ---
          Expanded(
            child: _filteredCoins.isEmpty
                ? const Center(child: Text("No results found."))
                : _isGridView
                ? _buildGridView() // Grid Görünümü
                : _buildListView(), // Liste Görünümü
          ),
        ],
      );
    }
  }

  // --- LIST VIEW BUILDER ---
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 10),
      itemCount: _filteredCoins.length,
      itemBuilder: (context, index) {
        CoinModel coin = _filteredCoins[index];
        var data = liveData[coin.symbol];
        return _buildCoinListCard(coin, data);
      },
    );
  }

  // --- GRID VIEW BUILDER ---
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Yan yana 2 kutu
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1, // Kutuların kareye yakın olması için
      ),
      itemCount: _filteredCoins.length,
      itemBuilder: (context, index) {
        CoinModel coin = _filteredCoins[index];
        var data = liveData[coin.symbol];
        return _buildCoinGridCard(coin, data);
      },
    );
  }

  // --- WIDGET: SIRALAMA CHIP'i ---
  Widget _buildSortChip(String label, SortCriteria criteria) {
    bool isActive = _sortCriteria == criteria;
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isActive) ...[
            const SizedBox(width: 4),
            Icon(
              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: Colors.white,
            ),
          ],
        ],
      ),
      backgroundColor: isActive ? Colors.teal : Colors.grey[200],
      labelStyle: TextStyle(
        color: isActive ? Colors.white : Colors.black87,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.transparent),
      ),
      onPressed: () => _changeSort(criteria),
    );
  }

  Map<String, dynamic> _parseCoinData(dynamic data) {
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
      }
    }
    return {
      "price": price,
      "percent": percent,
      "percentColor": percentColor,
      "trendIcon": trendIcon,
    };
  }

  Widget _buildCoinListCard(CoinModel coin, dynamic data) {
    var parsed = _parseCoinData(data);
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
                    parsed["price"],
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
                      color: (parsed["percentColor"] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          parsed["trendIcon"],
                          size: 14,
                          color: parsed["percentColor"],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          parsed["percent"],
                          style: TextStyle(
                            color: parsed["percentColor"],
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
                onPressed: () => _toggleFavorite(coin.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- COIN GRID KARTI ---
  Widget _buildCoinGridCard(CoinModel coin, dynamic data) {
    var parsed = _parseCoinData(data);
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
                    parsed["price"],
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
                      color: (parsed["percentColor"] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      parsed["percent"],
                      style: TextStyle(
                        color: parsed["percentColor"],
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Favori Butonu - Sağ Üst Köşe
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : Colors.grey.shade300,
                  size: 24,
                ),
                onPressed: () => _toggleFavorite(coin.id),
              ),
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
