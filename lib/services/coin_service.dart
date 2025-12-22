import 'dart:convert';
import 'package:crypto_market/models/trade_model.dart';
import 'package:http/http.dart' as http;
import '../models/coin_model.dart';
import 'package:candlesticks/candlesticks.dart';

class CoinService {
  final String _baseUrl = "https://localhost:7214/api";

  Future<List<CoinModel>> getAllCoins() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/coins'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => CoinModel.fromJson(item)).toList();
      } else {
        print("Sunucu Hatası: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("API Hatası: $e");
      return [];
    }
  }

  Future<List<CoinModel>> getFavoriteCoins() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/coins/favorites'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => CoinModel.fromJson(item)).toList();
      } else {
        print("Sunucu Hatası: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("API Hatası: $e");
      return [];
    }
  }

  Future<bool> toggleFavoriteCoin(int coinId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/coins/toggleFavorite/$coinId'),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Sunucu Hatası: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("API Hatası: $e");
      return false;
    }
  }

  Future<List<Candle>> getKlinesBySymbol(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/coins/$symbol/klines'),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);

        return body.map((e) {
          String rawDate = e['openTime'];
          if (!rawDate.endsWith('Z')) {
            rawDate += 'Z';
          }

          return Candle(
            date: DateTime.parse(rawDate).toLocal(),
            high: double.parse(e['high'].toString()),
            low: double.parse(e['low'].toString()),
            open: double.parse(e['open'].toString()),
            close: double.parse(e['close'].toString()),
            volume: double.parse(e['volume'].toString()),
          );
        }).toList();
      } else {
        print("Sunucu Hatası: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Kline API Hatası: $e");
      return [];
    }
  }

  Future<List<TradeModel>> getRecentTrades(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/coins/trades/$symbol'),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => TradeModel.fromJson(item)).toList();
      } else {
        print("Trades Hatası: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("API Hatası: $e");
      return [];
    }
  }
}
