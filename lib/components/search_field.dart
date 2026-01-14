import 'package:flutter/material.dart';

class CoinSearchField extends StatelessWidget {
  final Function(String) onChanged;

  const CoinSearchField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search coin (Bitcoin, Ethereum...)',
          fillColor: Colors.teal.withOpacity(0.1),
          hintStyle: TextStyle(color: Colors.teal),
          prefixIcon: const Icon(Icons.search, color: Colors.teal),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(width: 1),
          ),
        ),
      ),
    );
  }
}
