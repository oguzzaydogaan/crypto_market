import 'package:flutter/material.dart';

class CoinPage extends StatefulWidget {
  const CoinPage({super.key});

  @override
  State<CoinPage> createState() => _CoinPageState();
}

class _CoinPageState extends State<CoinPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Coin Details'), centerTitle: true),
      body: Center(
        child: Text('Details about the selected coin will be shown here.'),
      ),
    );
  }
}
