import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:intl/intl.dart';
import '../../models/coin_model.dart';
import '../../models/trade_model.dart';
import '../../services/coin_service.dart';
import '../../services/signalr_service.dart';

class CoinPage extends StatefulWidget {
  final CoinModel coin;

  const CoinPage({super.key, required this.coin});

  @override
  State<CoinPage> createState() => _CoinPageState();
}

class _CoinPageState extends State<CoinPage> {
  final CoinService _coinService = CoinService();
  final SignalRService _signalRService = SignalRService();

  List<Candle> candles = [];
  bool isLoading = true;
  double currentPrice = 0.0;
  bool isFavorite = false;
  List<TradeModel> recentTrades = [];
  bool isTradesLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // 1. Favori Kontrolü
    var favCoins = await _coinService.getFavoriteCoins();
    bool favStatus = favCoins.any((element) => element.id == widget.coin.id);

    // 2. Grafik Verisi
    var history = await _coinService.getKlinesBySymbol(widget.coin.symbol);

    // 3. Trade Verisi
    _fetchTrades();

    if (mounted) {
      setState(() {
        isFavorite = favStatus;
        candles = history.reversed.toList();
        if (candles.isNotEmpty) {
          currentPrice = candles[0].close;
        }
        isLoading = false;
      });
    }

    _startSocketListener();
  }

  Future<void> _fetchTrades() async {
    var trades = await _coinService.getRecentTrades(widget.coin.symbol);
    if (mounted) {
      setState(() {
        recentTrades = trades.reversed.toList();
        isTradesLoading = false;
      });
    }
  }

  Future<void> _startSocketListener() async {
    await _signalRService.connect();

    _signalRService.onKlineReceived = (data) {
      Map<String, dynamic> klineData;
      if (data is String) {
        klineData = jsonDecode(data);
      } else {
        klineData = data;
      }
      if (klineData["s"] != widget.coin.symbol) return;
      _processLiveCandle(klineData);
    };

    _signalRService.onTradeReceived = (data) {
      Map<String, dynamic> tradeData;
      if (data is String) {
        tradeData = jsonDecode(data);
      } else {
        tradeData = data;
      }
      if (tradeData["s"] != null && tradeData["s"] != widget.coin.symbol)
        return;
      _processLiveTrade(tradeData);
    };

    await _signalRService.joinGroup(widget.coin.symbol);
  }

  void _processLiveCandle(Map<String, dynamic> data) {
    if (candles.isEmpty) return;
    try {
      DateTime socketTime = DateTime.fromMillisecondsSinceEpoch(
        int.parse(data["t"].toString()),
      );
      double socketClose = double.parse(data["c"].toString());
      // ... Diğer parse işlemleri (h,l,o,v) ...
      double socketHigh = double.parse(data["h"].toString());
      double socketLow = double.parse(data["l"].toString());
      double socketOpen = double.parse(data["o"].toString());
      double socketVolume = double.parse(data["v"].toString());

      Candle lastCandle = candles[0];

      if (socketTime.isAfter(lastCandle.date)) {
        final newCandle = Candle(
          date: socketTime,
          high: socketHigh,
          low: socketLow,
          open: socketOpen,
          close: socketClose,
          volume: socketVolume,
        );
        if (mounted) {
          setState(() {
            candles.insert(0, newCandle);
            currentPrice = socketClose;
          });
        }
      } else if (socketTime.isAtSameMomentAs(lastCandle.date)) {
        final updatedCandle = Candle(
          date: lastCandle.date,
          high: socketHigh,
          low: socketLow,
          open: socketOpen,
          close: socketClose,
          volume: socketVolume,
        );
        if (mounted) {
          setState(() {
            candles[0] = updatedCandle;
            currentPrice = socketClose;
          });
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _processLiveTrade(Map<String, dynamic> data) {
    try {
      TradeModel newTrade = TradeModel.fromJson(data);
      if (mounted) {
        setState(() {
          recentTrades.insert(0, newTrade);
          if (recentTrades.length > 50) {
            recentTrades.removeLast();
          }
        });
      }
    } catch (e) {
      print("Trade Parse Error: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      isFavorite = !isFavorite;
    });
    bool success = await _coinService.toggleFavoriteCoin(widget.coin.id);
    if (!success && mounted) {
      setState(() {
        isFavorite = !isFavorite;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Hata oluştu")));
    }
  }

  @override
  void dispose() {
    _signalRService.leaveGroup(widget.coin.symbol);
    _signalRService.onKlineReceived = null;
    _signalRService.onTradeReceived = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPriceUp =
        candles.isNotEmpty && candles[0].close >= candles[0].open;
    final Color trendColor = isPriceUp ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.coin.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "\$${currentPrice.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 14, color: trendColor),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.orange : Colors.grey,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      // Grafik
                      Expanded(
                        child: candles.isNotEmpty
                            ? Candlesticks(candles: candles)
                            : const Center(child: Text("No candle data")),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Recent Trades",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Price (USDT)",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  "Amount (${widget.coin.symbol.replaceAll("USDT", "")})",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Time",
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 8, endIndent: 8),
                      const SizedBox(height: 7),
                      Expanded(child: _buildRecentTradesList()),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRecentTradesList() {
    if (isTradesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (recentTrades.isEmpty) {
      return const Center(child: Text("No recent trades available."));
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: recentTrades.length,
      itemBuilder: (context, index) {
        final trade = recentTrades[index];
        final bool isSell = trade.isBuyerMaker;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  trade.price.toStringAsFixed(2),
                  style: TextStyle(
                    color: isSell ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                trade.amount.toStringAsFixed(5),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: Text(
                  DateFormat('HH:mm:ss').format(trade.time),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
