import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 1024;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile),
            const SizedBox(height: 32),
            _buildReportGrid(isMobile, isTablet),
            const SizedBox(height: 40),
            Text(
              'Financial Overview',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<Product>>(
              stream: _firestoreService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return _buildErrorCard(snapshot.error.toString());
                }
                
                final products = snapshot.data ?? [];
                double totalValue = 0;
                int totalUnits = 0;
                for (var p in products) {
                  totalValue += (p.price * p.quantity);
                  totalUnits += p.quantity;
                }

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 24 : 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Inventory Asset Value',
                        style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(totalValue),
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 32 : 48,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF6366F1),
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: _buildValueStat(
                              'Product Types',
                              products.length.toString(),
                              Icons.inventory_2_outlined,
                              const Color(0xFF6366F1),
                            ),
                          ),
                          Container(height: 40, width: 1, color: const Color(0xFFF1F5F9)),
                          Expanded(
                            child: _buildValueStat(
                              'Total Units',
                              totalUnits.toString(),
                              Icons.shopping_bag_outlined,
                              const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics & Reports',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Detailed insights and performance metrics.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildValueStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildReportGrid(bool isMobile, bool isTablet) {
    int crossAxisCount = 3;
    double aspectRatio = 1.8;

    if (isMobile) {
      crossAxisCount = 1;
      aspectRatio = 3.5;
    } else if (isTablet) {
      crossAxisCount = 2;
      aspectRatio = 2.2;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio,
      children: [
        _buildReportCard(
          title: 'Stock Movements',
          subtitle: 'Full history log',
          icon: Icons.swap_horizontal_circle_rounded,
          color: const Color(0xFF10B981),
          onTap: () => _showMovementsDialog(),
        ),
        _buildReportCard(
          title: 'Inventory Audit',
          subtitle: 'Detailed list',
          icon: Icons.fact_check_rounded,
          color: const Color(0xFFF59E0B),
          onTap: () => _showAuditDialog(),
        ),
        _buildReportCard(
          title: 'Export Data',
          subtitle: 'Download CSV',
          icon: Icons.download_rounded,
          color: const Color(0xFF6366F1),
          onTap: () => _exportData(),
        ),
      ],
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E293B)),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showMovementsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recent Movements'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getTransactions(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final txs = snapshot.data!;
              if (txs.isEmpty) return const Text('No movements recorded.');
              return ListView.builder(
                shrinkWrap: true,
                itemCount: txs.length,
                itemBuilder: (context, index) {
                  final tx = txs[index];
                  final date = (tx['date'] as dynamic)?.toDate() ?? DateTime.now();
                  return ListTile(
                    title: Text(tx['productName'] ?? 'Product'),
                    subtitle: Text('${tx['type']} • ${tx['quantity']} units • ${DateFormat('MMM dd').format(date)}'),
                    trailing: Text('₱${(tx['totalValue'] ?? 0).toStringAsFixed(0)}'),
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showAuditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inventory Audit'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Product>>(
            stream: _firestoreService.getProducts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final products = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text('Category: ${p.categoryId}'),
                    trailing: Text('Stock: ${p.quantity}'),
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final products = await _firestoreService.getProducts().first;
      List<List<dynamic>> rows = [];
      rows.add(["ID", "Name", "Category", "Price", "Quantity", "Created At"]);
      
      for (var p in products) {
        rows.add([p.id, p.name, p.categoryId, p.price, p.quantity, p.createdAt?.toString() ?? '']);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/inventory_report_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report exported to $path'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 32),
          const SizedBox(height: 12),
          Text('Error loading financials', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF991B1B))),
          Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
        ],
      ),
    );
  }
}
