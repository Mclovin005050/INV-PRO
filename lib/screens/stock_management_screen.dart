import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
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

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Management',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
          ),
          const SizedBox(height: 24),
          if (isMobile)
            Column(
              children: [
                _buildActionCard(
                  context,
                  title: 'Stock In',
                  description: 'Receive new products from suppliers',
                  icon: Icons.add_business_rounded,
                  color: Colors.green,
                  onTap: () => _showTransactionDialog(context, 'IN'),
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  context,
                  title: 'Stock Out / Sales',
                  description: 'Record sales and reduce inventory',
                  icon: Icons.sell_rounded,
                  color: Colors.blue,
                  onTap: () => _showTransactionDialog(context, 'OUT'),
                ),
              ],
            )
          else
            Row(
              children: [
                _buildActionCard(
                  context,
                  title: 'Stock In',
                  description: 'Receive new products from suppliers',
                  icon: Icons.add_business_rounded,
                  color: Colors.green,
                  onTap: () => _showTransactionDialog(context, 'IN'),
                ),
                const SizedBox(width: 24),
                _buildActionCard(
                  context,
                  title: 'Stock Out / Sales',
                  description: 'Record sales and reduce inventory',
                  icon: Icons.sell_rounded,
                  color: Colors.blue,
                  onTap: () => _showTransactionDialog(context, 'OUT'),
                ),
              ],
            ),
          const SizedBox(height: 32),
          const Text(
            'Recent Movements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No transactions yet.')),
                    ),
                  );
                }
                
                return _buildMovementsList(transactions);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsList(List<Map<String, dynamic>> transactions) {
    return Card(
      elevation: 0,
      child: ListView.separated(
        itemCount: transactions.length,
        separatorBuilder: (context, index) => Divider(color: Colors.grey.shade50, height: 1),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final bool isStockIn = tx['type'] == 'IN';
          final DateTime date = (tx['date'] as dynamic)?.toDate() ?? DateTime.now();
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isStockIn ? Colors.green.shade50 : Colors.blue.shade50,
              child: Icon(
                isStockIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isStockIn ? Colors.green : Colors.blue,
                size: 18,
              ),
            ),
            title: Text(
              isStockIn ? 'Stock Received: ${tx['productName']}' : 'Sale: ${tx['productName']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(date),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            trailing: Text(
              isStockIn ? '+${tx['quantity']}' : '-${tx['quantity']}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isStockIn ? Colors.green : Colors.blue,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      flex: MediaQuery.of(context).size.width < 700 ? 0 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDialog(BuildContext context, String type) {
    Product? selectedProduct;
    final qtyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'IN' ? 'Stock In (Restock)' : 'Stock Out (Sale)'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<List<Product>>(
                stream: _firestoreService.getProducts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final products = snapshot.data!;
                  if (products.isEmpty) return const Text('No products available.');
                  
                  return DropdownButtonFormField<Product>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Select Product'),
                    items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: (p) => selectedProduct = p,
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Invalid quantity';
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
                    const SnackBar(content: Text('Transaction recorded successfully'))
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
