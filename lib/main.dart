import 'package:flutter/material.dart';
import 'package:mina_hybird_flutter/screens/category/category_page.dart';
import 'package:mina_hybird_flutter/screens/product/product_page.dart';
import 'package:mina_hybird_flutter/screens/unit/unit_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const ProductPage(),
    );
  }
}

// Common drawer widget to be used across pages
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.red[20],
            ),
            child: Text(
              'Inventory',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: const Text('Product'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProductPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Category'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CategoryPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Unit'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UnitPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
