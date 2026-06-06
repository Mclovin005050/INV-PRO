import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/supplier.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;
    final bool isTablet = width >= 700 && width < 1200;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
          ),
          const SizedBox(height: 24),
          _buildStatGrid(firestoreService, isMobile, isTablet),
          const SizedBox(height: 32),
          _buildMainContent(context, firestoreService, isMobile),
        ],
      ),
    );
  }

  Widget _buildStatGrid(FirestoreService service, bool isMobile, bool isTablet) {
    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    // Adjusted ratio to be taller to prevent bottom overflow
    double aspectRatio = isMobile ? 3.5 : 1.8;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio,
      children: [
        _buildStatStream(service.getProducts(), 'Total Products', Icons.inventory_2_rounded, Colors.blue),
        _buildLowStockStream(service.getProducts()),
        _buildStatStream(service.getCategories(), 'Categories', Icons.category_rounded, Colors.green),
        _buildStatStream(service.getSuppliers(), 'Suppliers', Icons.people_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildStatStream(Stream<List<dynamic>> stream, String title, IconData icon, Color color) {
    return StreamBuilder<List<dynamic>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return _buildStatCard(
          title: title,
          value: count.toString(),
          icon: icon,
          color: color,
          trend: 'Active',
          trendColor: color,
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
          color: Colors.orange,
          trend: lowStockCount > 0 ? 'Action required' : 'Healthy',
          trendColor: lowStockCount > 0 ? Colors.red : Colors.green,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required Color trendColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(fontSize: 10, color: trendColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, FirestoreService service, bool isMobile) {
    final activityCard = _buildRecentActivity(context, service);
    final alertsCard = _StockAlertsWidget(service: service);

    if (isMobile) {
      return Column(
        children: [
          activityCard,
          const SizedBox(height: 24),
          alertsCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: activityCard),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: alertsCard),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, FirestoreService service) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: service.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No transactions found.'));

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length > 5 ? 5 : transactions.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.grey.shade50, height: 24),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isStockIn = tx['type'] == 'IN';
                    final date = (tx['date'] as dynamic)?.toDate() ?? DateTime.now();
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFF1F5F9),
                          child: Icon(
                            isStockIn ? Icons.add_circle_outline : Icons.remove_circle_outline,
                            size: 16,
                            color: isStockIn ? Colors.green.shade600 : Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx['productName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('${isStockIn ? 'Restock' : 'Sale'} • ${DateFormat('HH:mm').format(date)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text(
                          '${isStockIn ? '+' : '-'}${tx['quantity']}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isStockIn ? Colors.green : const Color(0xFF0F172A)),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Critical Stock',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<Product>>(
              stream: service.getProducts(),
              builder: (context, snapshot) {
                final lowStock = snapshot.data?.where((p) => p.isLowStock).toList() ?? [];
                if (lowStock.isEmpty) return const Text('Stock levels healthy.', style: TextStyle(color: Colors.grey, fontSize: 13));

                return Column(
                  children: lowStock.take(5).map((p) => _buildAlertItem(p.name, '${p.quantity} units left', Colors.red)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(String product, String stock, Color color) {
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
            child: Text(product, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Text(
            stock,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
