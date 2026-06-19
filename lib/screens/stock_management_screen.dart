import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventory_management_system/models/product.dart';
import 'package:inventory_management_system/services/firestore_service.dart';
import 'package:intl/intl.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock Management',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track movements and adjust your inventory levels.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildActionButtons(context, isMobile),
              const SizedBox(height: 40),
              Text(
                'Recent Movements',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.getTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                  }
                  final transactions = snapshot.data ?? [];
                  if (transactions.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No transactions yet.', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    );
                  }
                  
                  return _buildMovementsList(transactions);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isMobile) {
    final buttons = [
      _buildActionCard(
        context,
        title: 'Stock In',
        description: 'Receive new products from suppliers',
        icon: Icons.add_business_rounded,
        color: const Color(0xFF10B981),
        onTap: () => _showTransactionDialog(context, 'IN'),
      ),
      if (isMobile) const SizedBox(height: 16) else const SizedBox(width: 24),
      _buildActionCard(
        context,
        title: 'Stock Out',
        description: 'Record sales or internal distribution',
        icon: Icons.sell_rounded,
        color: const Color(0xFF6366F1),
        onTap: () => _showTransactionDialog(context, 'OUT'),
      ),
    ];

    if (isMobile) {
      return Column(children: buttons);
    } else {
      return Row(children: buttons);
    }
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool isMobileWidth = MediaQuery.of(context).size.width < 700;
    
    Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade300),
        ],
      ),
    );

    if (isMobileWidth) {
      return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: content);
    } else {
      return Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: content));
    }
  }

  Widget _buildMovementsList(List<Map<String, dynamic>> transactions) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final bool isStockIn = tx['type'] == 'IN';
          final DateTime date = (tx['date'] as dynamic)?.toDate() ?? DateTime.now();
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: isStockIn ? const Color(0xFFECFDF5) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isStockIn ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: isStockIn ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                size: 20,
              ),
            ),
            title: Text(
              tx['productName'] ?? 'Product',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E293B)),
            ),
            subtitle: Text(
              '${isStockIn ? 'Restock' : 'Sale'} • ${DateFormat('MMM dd, yyyy • HH:mm').format(date)}',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isStockIn ? '+' : '-'}${tx['quantity']}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: isStockIn ? const Color(0xFF059669) : const Color(0xFF1E293B),
                    fontSize: 16,
                  ),
                ),
                if (tx['totalValue'] != null)
                  Text(
                    '₱${(tx['totalValue'] as num).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTransactionDialog(BuildContext context, String type) {
    Product? selectedProduct;
    final qtyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              type == 'IN' ? 'Stock In (Restock)' : 'Stock Out (Sale)',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Product', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Product>>(
                    stream: _firestoreService.getProducts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final products = snapshot.data!;
                      if (products.isEmpty) return const Text('No products available.');
                      
                      final currentSelection = selectedProduct == null 
                          ? null 
                          : products.any((p) => p.id == selectedProduct!.id)
                              ? products.firstWhere((p) => p.id == selectedProduct!.id)
                              : null;

                      return DropdownButtonFormField<Product>(
                        value: currentSelection,
                        isExpanded: true,
                        decoration: const InputDecoration(hintText: 'Select a product'),
                        items: products.map((p) => DropdownMenuItem<Product>(
                          value: p, 
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (p) {
                          setDialogState(() {
                            selectedProduct = p;
                          });
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Quantity', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: qtyController,
                    decoration: const InputDecoration(hintText: 'e.g. 50'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return 'Invalid quantity';
                      if (type == 'OUT' && selectedProduct != null && n > selectedProduct!.quantity) {
                        return 'Insufficient stock (${selectedProduct!.quantity} left)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate() && selectedProduct != null) {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    try {
                      await _firestoreService.recordTransaction(
                        productId: selectedProduct!.id,
                        productName: selectedProduct!.name,
                        quantity: int.parse(qtyController.text),
                        type: type,
                        price: selectedProduct!.price,
                      );
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Transaction recorded successfully'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        )
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)
                      );
                    }
                  }
                },
                child: const Text('Submit Transaction'),
              ),
            ],
          );
        }
      ),
    );
  }
}
