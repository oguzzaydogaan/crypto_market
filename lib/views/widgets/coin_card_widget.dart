import 'package:flutter/material.dart';

class CoinCardWidget extends StatefulWidget {
  const CoinCardWidget({super.key});

  @override
  State<CoinCardWidget> createState() => _CoinCardWidgetState();
}

class _CoinCardWidgetState extends State<CoinCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.monetization_on, color: Colors.white),
        ),
        title: Text('Bitcoin'),
        subtitle: Text('\$50,000'),
        trailing: Text('+5%'),
      ),
    );
  }
}
