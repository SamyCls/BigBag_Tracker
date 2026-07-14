import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
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
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final app = context.watch<AppProvider>();

    if (app.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ── Landscape (wide): permanent sidebar ───────────────────────────
    if (isWide && isLandscape) {
      return Scaffold(
        body: Row(
          children: [
            _SideNav(
              index: _index,
              destinations: _destinations,
              onTap: (i) => setState(() => _index = i),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(index: _index, children: _screens),
            ),
          ],
        ),
      );
    }

    // ── Portrait tablet: sidebar hidden behind drawer ─────────────────
    if (isWide && !isLandscape) {
      return Scaffold(
        drawer: Drawer(
          width: 280,
          child: SafeArea(
            child: Builder(
              builder: (ctx) => _SideNav(
                index: _index,
                destinations: _destinations,
                onTap: (i) {
                  setState(() => _index = i);
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            IndexedStack(index: _index, children: _screens),
            Positioned(
              top: 20,
              left: 20,
              child: Builder(
                builder: (ctx) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Material(
                    color: isDark
                        ? AppColors.cardDark
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 4,
                    shadowColor: Colors.black26,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          Icons.menu,
                          size: 32,
                          color: isDark
                              ? AppColors.inkOnDark
                              : AppColors.ink,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile: bottom navigation bar ────────────────────────────────
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

/// Full-height sidebar where every destination fills an equal slice of the bar.
class _SideNav extends StatelessWidget {
  final int index;
  final List<({IconData icon, String label})> destinations;
  final ValueChanged<int> onTap;

  const _SideNav({
    required this.index,
    required this.destinations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);
    final selectedBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final selectedColor = Theme.of(context).colorScheme.primary;
    final unselectedColor = isDark ? Colors.white54 : Colors.black45;

    return Container(
      width: 280,
      color: bg,
      child: Column(
        children: [
          for (var i = 0; i < destinations.length; i++)
            Expanded(
              child: _SideNavItem(
                icon: destinations[i].icon,
                label: destinations[i].label,
                selected: index == i,
                selectedBg: selectedBg,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedBg;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedBg,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;

    return Material(
      color: selected ? selectedBg : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: selected
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: selectedColor, width: 4),
                  ),
                )
              : null,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
