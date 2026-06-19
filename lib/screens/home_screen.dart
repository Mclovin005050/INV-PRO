import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventory_management_system/services/auth_service.dart';
import 'package:inventory_management_system/screens/dashboard_screen.dart';
import 'package:inventory_management_system/screens/product_list_screen.dart';
import 'package:inventory_management_system/screens/category_list_screen.dart';
import 'package:inventory_management_system/screens/supplier_list_screen.dart';
import 'package:inventory_management_system/screens/stock_management_screen.dart';
import 'package:inventory_management_system/screens/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isRailExtended = true;
  final AuthService _authService = AuthService();

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
    final bool isMobile = width < 900;
    final bool isDesktop = width >= 1200;
    final User? user = _authService.currentUser;

    return Scaffold(
      drawer: isMobile ? _buildDrawer(context, user) : null,
      body: Row(
        children: [
          if (!isMobile) _buildNavigationRail(isDesktop),
          Expanded(
            child: Column(
              children: [
                _buildHeader(isMobile, isDesktop, user),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey<int>(_selectedIndex),
                        child: _screens[_selectedIndex],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(bool isDesktop) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        extended: isDesktop && _isRailExtended,
        minWidth: 80,
        minExtendedWidth: 260,
        backgroundColor: Colors.transparent,
        unselectedIconTheme: const IconThemeData(color: Color(0xFF94A3B8), size: 22),
        selectedIconTheme: const IconThemeData(color: Colors.white, size: 22),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: const Color(0xFF94A3B8), 
          fontSize: 14, 
          fontWeight: FontWeight.w500
        ),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: Colors.white, 
          fontSize: 14, 
          fontWeight: FontWeight.w600
        ),
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          child: InkWell(
            onTap: () => setState(() => _isRailExtended = !_isRailExtended),
            child: Row(
              mainAxisAlignment: isDesktop && _isRailExtended ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 24),
                ),
                if (isDesktop && _isRailExtended) ...[
                  const SizedBox(width: 12),
                  Text(
                    'INV PRO',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.0,
                    ),
                  ),
                ]
              ],
            ),
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
            label: Text('Stock'),
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
                tooltip: 'Logout',
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFF43F5E)),
                onPressed: () => _authService.signOut(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile, bool isDesktop, User? user) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (isMobile) ...[
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const SizedBox(width: 8),
          ] else
            Text(
              _getScreenTitle(),
              style: GoogleFonts.inter(
                fontSize: 22, 
                fontWeight: FontWeight.w700, 
                color: const Color(0xFF0F172A)
              ),
            ),
          const Spacer(),
          if (!isMobile)
            _buildSearchBar(isDesktop),
          const SizedBox(width: 24),
          _buildHeaderAction(Icons.notifications_none_rounded),
          const SizedBox(width: 12),
          const VerticalDivider(indent: 25, endIndent: 25, color: Color(0xFFE2E8F0)),
          const SizedBox(width: 12),
          _buildUserProfile(user),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDesktop) {
    return SizedBox(
      width: isDesktop ? 400 : 250,
      height: 44,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search items...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        onPressed: () {},
      ),
    );
  }

  Widget _buildUserProfile(User? user) {
    return Row(
      children: [
        if (MediaQuery.of(context).size.width > 400)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                user?.displayName ?? user?.email?.split('@')[0] ?? 'Admin',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0F172A)),
              ),
              Text(
                'Store Manager',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF4F46E5), width: 2),
          ),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEEF2FF),
            child: Text(
              (user?.email?[0] ?? 'A').toUpperCase(),
              style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, User? user) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E293B)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text('Inventory Pro', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildDrawerItem(0, Icons.grid_view_rounded, 'Dashboard'),
          _buildDrawerItem(1, Icons.inventory_2_rounded, 'Products'),
          _buildDrawerItem(2, Icons.swap_vert_rounded, 'Stock'),
          _buildDrawerItem(3, Icons.category_rounded, 'Categories'),
          _buildDrawerItem(4, Icons.people_rounded, 'Suppliers'),
          _buildDrawerItem(5, Icons.bar_chart_rounded, 'Reports'),
          const Spacer(),
          const Divider(color: Color(0xFF334155), indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFF43F5E)),
            title: Text('Logout', style: GoogleFonts.inter(color: const Color(0xFFF43F5E), fontWeight: FontWeight.w600)),
            onTap: () => _authService.signOut(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        selectedTileColor: const Color(0xFF4F46E5),
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 0: return 'Dashboard Overview';
      case 1: return 'Inventory Management';
      case 2: return 'Stock Control';
      case 3: return 'Item Categories';
      case 4: return 'Supplier Network';
      case 5: return 'Business Reports';
      default: return 'Inventory Pro';
    }
  }
}
