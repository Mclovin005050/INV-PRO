import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/export_service.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _handleExport(BuildContext context, FirestoreService service) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating inventory report...')),
      );
      
      final products = await service.getProducts().first;
      
      if (products.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No products found to export.')),
          );
        }
        return;
      }

      await ExportService.exportProductsToCsv(products);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report downloaded successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;
    final bool isTablet = width >= 700 && width < 1200;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Overview',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time inventory and analytics tracking',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (!isMobile)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ElevatedButton.icon(
                        onPressed: () => _handleExport(context, firestoreService),
                        icon: const Icon(Icons.file_download_rounded, size: 20),
                        label: const Text('Export Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF64748B),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                      onPressed: () => (context as Element).markNeedsBuild(),
                      tooltip: 'Refresh Data',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildStatGrid(firestoreService, isMobile, isTablet),
          const SizedBox(height: 32),
          _buildMainContent(context, firestoreService, isMobile),
        ],
      ),
    );
  }

  Widget _buildStatGrid(FirestoreService service, bool isMobile, bool isTablet) {
    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    double aspectRatio = isMobile ? 4.0 : 1.6;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: aspectRatio,
      children: [
        _buildStatStream(service.getProducts(), 'Total Products', Icons.inventory_2_rounded, const Color(0xFF6366F1)),
        _buildLowStockStream(service.getProducts()),
        _buildStatStream(service.getCategories(), 'Categories', Icons.category_rounded, const Color(0xFF10B981)),
        _buildStatStream(service.getSuppliers(), 'Active Suppliers', Icons.people_rounded, const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildStatStream(Stream<List<dynamic>> stream, String title, IconData icon, Color color) {
    return StreamBuilder<List<dynamic>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorCard(title, 'Sync Error');
        final count = snapshot.data?.length ?? 0;
        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
        
        return _buildStatCard(
          title: title,
          value: isLoading ? '--' : count.toString(),
          icon: icon,
          color: color,
          isLoading: isLoading,
        );
      },
    );
  }

  Widget _buildLowStockStream(Stream<List<Product>> stream) {
    return StreamBuilder<List<Product>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorCard('Low Stock', 'Sync Error');
        final lowStockCount = snapshot.data?.where((p) => p.isLowStock).length ?? 0;
        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
        
        return _buildStatCard(
          title: 'Low Stock Alerts',
          value: isLoading ? '--' : lowStockCount.toString(),
          icon: Icons.warning_amber_rounded,
          color: lowStockCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          isLoading: isLoading,
          isAlert: lowStockCount > 0,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isLoading,
    bool isAlert = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (isAlert)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Action Req.',
                      style: TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String title, String error) {
    return Card(
      color: const Color(0xFFFEF2F2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
            const Spacer(),
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
            Text(error, style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
          ],
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: service.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                }
                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No recent activity recorded.', style: TextStyle(color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length > 5 ? 5 : transactions.length,
                  separatorBuilder: (context, index) => const Divider(height: 32),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isStockIn = tx['type'] == 'IN';
                    final date = (tx['date'] as dynamic)?.toDate() ?? DateTime.now();
                    return Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (isStockIn ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isStockIn ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                            size: 20,
                            color: isStockIn ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx['productName'] ?? 'Unknown Item',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${isStockIn ? 'Restock' : 'Inventory Out'} • ${DateFormat('MMM dd, HH:mm').format(date)}',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isStockIn ? '+' : '-'}${tx['quantity']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: isStockIn ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '₱${(tx['totalValue'] ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
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
      ),
    );
  }
}

class _StockAlertsWidget extends StatelessWidget {
  final FirestoreService service;
  const _StockAlertsWidget({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Critical Stock',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<Product>>(
              stream: service.getProducts(),
              builder: (context, snapshot) {
                final lowStock = snapshot.data?.where((p) => p.isLowStock).toList() ?? [];
                if (lowStock.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                        SizedBox(width: 12),
                        Text('All levels healthy.', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }

                return Column(
                  children: lowStock.take(6).map((p) => _buildAlertItem(p.name, p.quantity, const Color(0xFFEF4444))).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(String product, int quantity, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$quantity units',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
