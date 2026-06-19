import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventory_management_system/services/firestore_service.dart';
import 'package:inventory_management_system/models/product.dart';
import 'package:inventory_management_system/models/category.dart';
import 'package:inventory_management_system/models/supplier.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final double width = MediaQuery.of(context).size.width;
    // Standardizing breakpoints
    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 1024;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(context, isMobile),
              const SizedBox(height: 32),
              _buildStatGrid(firestoreService, isMobile, isTablet),
              const SizedBox(height: 32),
              _buildMainContent(context, firestoreService, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Monitor your inventory performance and stock levels.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(FirestoreService service, bool isMobile, bool isTablet) {
    int crossAxisCount = 4;
    double aspectRatio = 1.6;

    if (isMobile) {
      crossAxisCount = 2;
      aspectRatio = 1.2;
    } else if (isTablet) {
      crossAxisCount = 2;
      aspectRatio = 2.0;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio,
      children: [
        _buildStatStream<Product>(service.getProducts(), 'Total Products', Icons.inventory_2_rounded, const Color(0xFF6366F1)),
        _buildLowStockStream(service.getProducts()),
        _buildStatStream<Category>(service.getCategories(), 'Categories', Icons.category_rounded, const Color(0xFF10B981)),
        _buildStatStream<Supplier>(service.getSuppliers(), 'Suppliers', Icons.people_rounded, const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _buildStatStream<T>(Stream<List<T>> stream, String title, IconData icon, Color color) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return _buildStatCard(
          title: title,
          value: count.toString(),
          icon: icon,
          color: color,
          isLoading: snapshot.connectionState == ConnectionState.waiting,
        );
      },
    );
  }

  Widget _buildLowStockStream(Stream<List<Product>> stream) {
    return StreamBuilder<List<Product>>(
      stream: stream,
      builder: (context, snapshot) {
        final lowStockCount = snapshot.data?.where((p) => p.isLowStock).length ?? 0;
        return _buildStatCard(
          title: 'Low Stock',
          value: lowStockCount.toString(),
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF59E0B),
          isWarning: lowStockCount > 0,
          isLoading: snapshot.connectionState == ConnectionState.waiting,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isWarning = false,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (isWarning && !isLoading)
                const Icon(Icons.circle, color: Color(0xFFF43F5E), size: 8),
            ],
          ),
          const Spacer(),
          isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, FirestoreService service, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildRecentActivity(context, service),
          const SizedBox(height: 24),
          _StockAlertsWidget(service: service),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildRecentActivity(context, service)),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _StockAlertsWidget(service: service)),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, FirestoreService service) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              ),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: service.getTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              }
              
              final transactions = snapshot.data ?? [];
              if (transactions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text('No recent activity recorded.', style: TextStyle(color: Colors.grey.shade400)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length > 5 ? 5 : transactions.length,
                separatorBuilder: (context, index) => const Divider(height: 32, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final isStockIn = tx['type'] == 'IN';
                  final date = (tx['date'] as dynamic)?.toDate() ?? DateTime.now();
                  return Row(
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: isStockIn ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isStockIn ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                          size: 18,
                          color: isStockIn ? const Color(0xFF059669) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx['productName'] ?? 'Product', 
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))
                            ),
                            Text(
                              '${isStockIn ? 'Restock' : 'Order'} • ${DateFormat('MMM dd, HH:mm').format(date)}', 
                              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11)
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isStockIn ? '+' : '-'}${tx['quantity']}',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: isStockIn ? const Color(0xFF059669) : const Color(0xFF1E293B)),
                          ),
                          Text('₱${(tx['totalValue'] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StockAlertsWidget extends StatelessWidget {
  final FirestoreService service;
  const _StockAlertsWidget({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Alerts',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Product>>(
            stream: service.getProducts(),
            builder: (context, snapshot) {
              final lowStock = snapshot.data?.where((p) => p.isLowStock).toList() ?? [];
              if (lowStock.isEmpty) {
                return Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    Text('Stock levels healthy.', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13)),
                  ],
                );
              }

              return Column(
                children: lowStock.take(5).map((p) => _buildAlertItem(p)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Product p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name, 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF991B1B))
                  ),
                  Text('${p.quantity} units remaining', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB91C1C))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
