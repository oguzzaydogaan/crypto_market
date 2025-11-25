import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  final String serverUrl = "https://localhost:7214/cryptohub";

  late HubConnection _hubConnection;
  Function(dynamic)? onTickerReceived;
  Function(dynamic)? onKlineReceived;

  Future<void> connect() async {
    try {
      _hubConnection = HubConnectionBuilder()
          .withUrl(serverUrl)
          .withAutomaticReconnect()
          .build();

      _hubConnection.on("ReceiveTicker", (arguments) {
        if (arguments != null && arguments.isNotEmpty) {
          if (onTickerReceived != null) {
            onTickerReceived!(arguments[0]);
          }
        }
      });
      _hubConnection.on("ReceiveKline", (arguments) {
        if (arguments != null && arguments.isNotEmpty) {
          print("Received Kline: ${arguments[0]}");
          if (onKlineReceived != null) {
            onKlineReceived!(arguments[0]);
          }
        }
      });

      await _hubConnection.start();
    } catch (e) {
      AlertDialog(
        title: Text('Connection Error'),
        content: Text('Could not connect to SignalR server: $e'),
      );
    }
  }

  Future<void> joinGroup(String symbol) async {
    if (_hubConnection.state == HubConnectionState.Connected) {
      await _hubConnection.invoke("JoinCoinGroup", args: [symbol]);
    }
  }

  Future<void> leaveGroup(String symbol) async {
    if (_hubConnection.state == HubConnectionState.Connected) {
      await _hubConnection.invoke("LeaveCoinGroup", args: [symbol]);
    }
  }
}
