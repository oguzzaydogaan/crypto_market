import 'package:crypto_market/data/notifiers.dart';
import 'package:flutter/material.dart';

class NavbarWidget extends StatefulWidget {
  const NavbarWidget({super.key});

  @override
  State<NavbarWidget> createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  int currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: pageIndexNotifier,
      builder: (context, pageIndex, child) {
        return NavigationBar(
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.currency_exchange),
              label: 'Currencies',
            ),
            NavigationDestination(icon: Icon(Icons.star), label: 'Favorites'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
          selectedIndex: pageIndex,
          onDestinationSelected: (value) {
            pageIndexNotifier.value = value;
          },
        );
      },
    );
  }
}
