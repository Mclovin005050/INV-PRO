import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'product_list_screen.dart';
import 'category_list_screen.dart';
import 'supplier_list_screen.dart';
import 'stock_management_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isRailExtended = true;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductListScreen(),
    const StockManagementScreen(),
    const CategoryListScreen(),
    const SupplierListScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;
    final bool isDesktop = width >= 1100;

    return Scaffold(
      drawer: isMobile ? _buildDrawer(context) : null,
      body: Row(
        children: [
          if (!isMobile)
            _buildNavigationRail(isDesktop),
          Expanded(
            child: Column(
              children: [
                _buildHeader(isMobile, isDesktop),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _screens[_selectedIndex],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: const Color(0xFF2563EB),
              unselectedItemColor: const Color(0xFF94A3B8),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Inventory'),
                BottomNavigationBarItem(icon: Icon(Icons.swap_vert), label: 'Stock'),
                BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
              ],
            )
          : null,
    );
  }

  Widget _buildNavigationRail(bool isDesktop) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      extended: isDesktop && _isRailExtended,
      minWidth: 72,
      minExtendedWidth: 240,
      backgroundColor: const Color(0xFF0F172A),
      unselectedIconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
      selectedIconTheme: const IconThemeData(color: Colors.white),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: AnimatedCrossFade(
          firstChild: IconButton(
            icon: const Icon(Icons.inventory, color: Colors.white, size: 32),
            onPressed: () => setState(() => _isRailExtended = !_isRailExtended),
          ),
          secondChild: InkWell(
            onTap: () => setState(() => _isRailExtended = !_isRailExtended),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  'INV PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: (isDesktop && _isRailExtended) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2_rounded),
          label: Text('Products'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.swap_vert_rounded),
          selectedIcon: Icon(Icons.swap_vert_rounded),
          label: Text('Stock Movements'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.category_outlined),
          selectedIcon: Icon(Icons.category_rounded),
          label: Text('Categories'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: Text('Suppliers'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bar_chart_rounded),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: Text('Reports'),
        ),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile, bool isDesktop) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (isMobile) ...[
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'INV PRO',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ] else
            Text(
              _getScreenTitle(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          const Spacer(),
          if (!isMobile)
            SizedBox(
              width: isDesktop ? 400 : 200,
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products, orders...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: EdgeInsets.zero,
                  fillColor: const Color(0xFFF1F5F9),
                ),
              ),
            ),
          const SizedBox(width: 24),
          Stack(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              ),
            ],
          ),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            const VerticalDivider(indent: 20, endIndent: 20),
            const SizedBox(width: 12),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Admin User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Store Manager', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=Admin+User&background=2563EB&color=fff'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF0F172A)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  Text('Inventory Pro', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Products'),
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Products';
      case 2: return 'Stock Management';
      case 3: return 'Categories';
      case 4: return 'Suppliers';
      case 5: return 'Reports';
      default: return 'Inventory Pro';
    }
  }
}
