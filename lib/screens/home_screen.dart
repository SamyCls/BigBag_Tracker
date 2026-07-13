import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'production_screen.dart';
import 'stock_screen.dart';
import 'chargement_screen.dart';
import 'historique_screen.dart';
import 'reglages_screen.dart';

/// Écran racine avec navigation responsive :
/// - Bottom navigation bar sur mobile (largeur < 700)
/// - Navigation rail latérale sur tablette/desktop (largeur >= 700)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _screens = [
    ProductionScreen(),
    StockScreen(),
    ChargementScreen(),
    HistoriqueScreen(),
    ReglagesScreen(),
  ];

  static const _destinations = [
    (icon: Icons.autorenew, label: 'Production'),
    (icon: Icons.inventory_2_outlined, label: 'Stock'),
    (icon: Icons.local_shipping_outlined, label: 'Chargement'),
    (icon: Icons.history, label: 'Historique'),
    (icon: Icons.settings_outlined, label: 'Réglages'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;
    final app = context.watch<AppProvider>();

    if (app.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (var i = 0; i < _destinations.length; i++)
                  NavigationRailDestination(
                    icon: Icon(_destinations[i].icon),
                    label: Text(_destinations[i].label),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(index: _index, children: _screens),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          for (final d in _destinations)
            BottomNavigationBarItem(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}
