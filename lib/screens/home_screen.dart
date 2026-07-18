import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/language_provider.dart';
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
  bool _sideNavCollapsed = false;

  static const _screens = [
    ProductionScreen(),
    StockScreen(),
    ChargementScreen(),
    HistoriqueScreen(),
    ReglagesScreen(),
  ];

  static const _destinations = [
    (icon: Icons.autorenew, label: 'nav_production'),
    (icon: Icons.inventory_2_outlined, label: 'nav_stock'),
    (icon: Icons.local_shipping_outlined, label: 'nav_chargement'),
    (icon: Icons.history, label: 'nav_historique'),
    (icon: Icons.settings_outlined, label: 'nav_reglages'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;
    final app = context.watch<AppProvider>();

    if (app.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ── Tablets & Wide Screens (width >= 700): permanent sidebar ───────
    if (isWide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              _SideNav(
                index: _index,
                destinations: _destinations,
                stockCount: app.stockCount,
                collapsed: _sideNavCollapsed,
                onToggle: () => setState(() => _sideNavCollapsed = !_sideNavCollapsed),
                onTap: (i) => setState(() => _index = i),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: IndexedStack(index: _index, children: _screens),
              ),
            ],
          ),
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
            BottomNavigationBarItem(icon: Icon(d.icon), label: context.tr(d.label)),
        ],
      ),
    );
  }
}

/// Full-height sidebar where every destination fills an equal slice of the bar.
class _SideNav extends StatelessWidget {
  final int index;
  final List<({IconData icon, String label})> destinations;
  final int stockCount;
  final bool collapsed;
  final VoidCallback onToggle;
  final ValueChanged<int> onTap;

  const _SideNav({
    required this.index,
    required this.destinations,
    required this.stockCount,
    required this.collapsed,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);
    final selectedBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final selectedColor = Theme.of(context).colorScheme.primary;
    final unselectedColor = isDark ? Colors.white54 : Colors.black45;
    final mute = isDark ? AppColors.inkMuteDark : AppColors.inkMute;

    return Container(
      width: collapsed ? 60 : 180,
      color: bg,
      child: Column(
        children: [
          for (var i = 0; i < destinations.length; i++)
            Expanded(
              child: _SideNavItem(
                icon: destinations[i].icon,
                label: context.tr(destinations[i].label),
                selected: index == i,
                selectedBg: selectedBg,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                badge: i == 1 && stockCount > 0 ? stockCount : null,
                onTap: () => onTap(i),
                collapsed: collapsed,
              ),
            ),
          // version footer
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: Text(
                context.tr('set_version'),
                style: TextStyle(fontSize: 12, color: mute, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
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
  final int? badge;
  final VoidCallback onTap;
  final bool collapsed;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedBg,
    required this.selectedColor,
    required this.unselectedColor,
    this.badge,
    required this.onTap,
    required this.collapsed,
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
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 16),
          decoration: selected
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: selectedColor, width: 4),
                  ),
                )
              : null,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 36, color: color),
                  if (collapsed && badge != null && badge! > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                if (badge != null && badge! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
