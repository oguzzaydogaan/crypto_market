import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import '../../models/coin_model.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    var history = await _coinService.getKlinesBySymbol(widget.coin.symbol);

    if (mounted) {
      setState(() {
        candles = history.reversed.toList();
        if (candles.isNotEmpty) {
          currentPrice = candles[0].close;
        }
        isLoading = false;
      });
    }

    _startSocketListener();
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

    await _signalRService.joinGroup(widget.coin.symbol);
  }

  void _processLiveCandle(Map<String, dynamic> data) {
    if (candles.isEmpty) return;

    try {
      DateTime socketTime = DateTime.fromMillisecondsSinceEpoch(
        int.parse(data["t"].toString()),
      );
      double socketClose = double.parse(data["c"].toString());
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
      print("Candle Parse Error: $e");
    }
  }

  @override
  void dispose() {
    _signalRService.leaveGroup(widget.coin.symbol);
    _signalRService.onKlineReceived = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(
                fontSize: 14,
                color: candles.isNotEmpty && candles[0].close >= candles[0].open
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : candles.isEmpty
                ? const Center(child: Text("No candle data available"))
                : Candlesticks(candles: candles),
          ),
        ],
      ),
    );
  }
}
