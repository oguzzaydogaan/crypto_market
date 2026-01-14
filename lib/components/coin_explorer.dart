import 'package:flutter/material.dart';
import '../models/coin_model.dart';
import 'search_field.dart';
import 'coin_card.dart';

enum SortCriteria { name, price, change }

class CoinExplorer extends StatefulWidget {
  final List<CoinModel> coins; // Gösterilecek coin listesi (Ham liste)
  final Map<String, dynamic> liveData; // Canlı veriler
  final Set<int> favoriteCoinIds; // Favori ID'leri
  final Function(int) onToggleFavorite; // Favori değiştirme fonksiyonu
  final Function() onRefresh; // Yenileme fonksiyonu
  final Widget? extraAction; // Ekstra buton (Örn: Ekle Butonu)

  const CoinExplorer({
    super.key,
    required this.coins,
    required this.liveData,
    required this.favoriteCoinIds,
    required this.onToggleFavorite,
    required this.onRefresh,
    this.extraAction,
  });

  @override
  State<CoinExplorer> createState() => _CoinExplorerState();
}

class _CoinExplorerState extends State<CoinExplorer> {
  // --- STATE ---
  List<CoinModel> _filteredCoins = [];
  String _searchKeyword = "";
  SortCriteria _sortCriteria = SortCriteria.name;
  bool _isAscending = true;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _filteredCoins = widget.coins;
    _sortCoins();
  }

  @override
  void didUpdateWidget(covariant CoinExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Eğer parent'tan gelen ana liste değişirse (Örn: Coin eklendi)
    // veya Canlı veri gelirse ve sıralama Fiyat/Yüzde ise listeyi güncelle.
    if (widget.coins != oldWidget.coins) {
      _applyFilterAndSort();
    } else if (widget.liveData != oldWidget.liveData) {
      if (_sortCriteria != SortCriteria.name) {
        _sortCoins();
      }
    }
  }

  void _runFilter(String keyword) {
    _searchKeyword = keyword;
    _applyFilterAndSort();
  }

  void _applyFilterAndSort() {
    // 1. Filtrele
    if (_searchKeyword.isEmpty) {
      _filteredCoins = List.from(widget.coins);
    } else {
      _filteredCoins = widget.coins
          .where(
            (coin) =>
                coin.name.toLowerCase().contains(
                  _searchKeyword.toLowerCase(),
                ) ||
                coin.symbol.toLowerCase().contains(
                  _searchKeyword.toLowerCase(),
                ),
          )
          .toList();
    }
    // 2. Sırala
    _sortCoins();
  }

  void _sortCoins() {
    setState(() {
      _filteredCoins.sort((a, b) {
        var dataA = widget.liveData[a.symbol];
        var dataB = widget.liveData[b.symbol];
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- ÜST BAR (Arama + Görünüm + Extra) ---
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            children: [
              Expanded(child: CoinSearchField(onChanged: _runFilter)),

              // Görünüm Değiştirme Butonu
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
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                  tooltip: "Change View",
                ),
              ),

              // Ekstra Aksiyon (Örn: Ekle butonu)
              if (widget.extraAction != null) widget.extraAction!,
            ],
          ),
        ),

        // --- SIRALAMA CHIP'leri ---
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

        // --- LİSTE / GRID ---
        Expanded(
          child: _filteredCoins.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("No results found."),
                      TextButton(
                        onPressed: widget.onRefresh,
                        child: const Text(
                          "Refresh",
                          style: TextStyle(color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                )
              : _isGridView
              ? _buildGridView()
              : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 10),
      itemCount: _filteredCoins.length,
      itemBuilder: (context, index) {
        var coin = _filteredCoins[index];
        return CoinCard(
          coin: coin,
          liveData: widget.liveData[coin.symbol],
          isFavorite: widget.favoriteCoinIds.contains(coin.id),
          isGrid: false,
          onToggleFavorite: () => widget.onToggleFavorite(coin.id),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: _filteredCoins.length,
      itemBuilder: (context, index) {
        var coin = _filteredCoins[index];
        return CoinCard(
          coin: coin,
          liveData: widget.liveData[coin.symbol],
          isFavorite: widget.favoriteCoinIds.contains(coin.id),
          isGrid: true,
          onToggleFavorite: () => widget.onToggleFavorite(coin.id),
        );
      },
    );
  }

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
              color: Colors.teal,
            ),
          ],
        ],
      ),
      backgroundColor: isActive
          ? Colors.teal.withOpacity(0.3)
          : Colors.teal.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Colors.teal,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.transparent),
      ),
      onPressed: () => _changeSort(criteria),
    );
  }
}
