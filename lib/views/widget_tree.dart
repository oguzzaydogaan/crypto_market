import 'package:crypto_market/data/notifiers.dart';
import 'package:crypto_market/views/pages/favorites_page.dart';
import 'package:crypto_market/views/pages/home_page.dart';
import 'package:crypto_market/views/pages/profile_page.dart';
import 'package:flutter/material.dart';

import 'widgets/navbar_widget.dart';

List<Widget> pages = [HomePage(), FavoritesPage(), ProfilePage()];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Market'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              isDarkModeNotifier.value = !isDarkModeNotifier.value;
            },
            icon: ValueListenableBuilder(
              valueListenable: isDarkModeNotifier,
              builder: (context, isDarkMode, child) {
                return Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode);
              },
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: pageIndexNotifier,
        builder: (context, pageIndex, child) {
          return pages[pageIndex];
        },
      ),
      bottomNavigationBar: NavbarWidget(),
    );
  }
}
