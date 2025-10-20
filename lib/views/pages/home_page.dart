import 'package:crypto_market/views/pages/coin_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.star_border_outlined),
                      ),
                      Icon(Icons.currency_bitcoin),
                      Text('Bitcoin (BTC)'),
                    ],
                  ),
                  Row(
                    children: [
                      Text('\$100,000'),
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return CoinPage();
                              },
                            ),
                          );
                        },
                        icon: Icon(Icons.arrow_forward_ios),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(onPressed: () {}, icon: Icon(Icons.star)),
                      Icon(Icons.currency_pound),
                      Text('Ethereum (ETH)'),
                    ],
                  ),
                  Text('\$30,000'),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.star_border_outlined),
                      ),
                      Icon(Icons.currency_franc),
                      Text('Doge (DOGE)'),
                    ],
                  ),
                  Text('\$0.25'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
