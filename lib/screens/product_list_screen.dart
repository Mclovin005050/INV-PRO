import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';
import '../services/export_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating CSV report...')),
      );
      
      final products = await _firestoreService.getProducts().first;
      
      if (products.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No products found to export.')),
          );
        }
        return;
      }

      await ExportService.exportProductsToCsv(products);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export started successfully!'), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 800;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory Assets',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage and track your product catalog',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildAddButton(isMobile),
            ],
          ),
          const SizedBox(height: 32),
          _buildFilters(isMobile),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _firestoreService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allProducts = snapshot.data ?? [];
                final products = _searchQuery.isEmpty
                    ? allProducts
                    : allProducts.where((p) => 
                        p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                        p.categoryId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                if (products.isEmpty) return _buildEmptyState();

                return isMobile ? _buildMobileList(products) : _buildDesktopTable(products);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(bool isMobile) {
    return ElevatedButton.icon(
      onPressed: () => _showProductDialog(context),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(isMobile ? 'Add' : 'Add New Product'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F46E5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  Widget _buildFilters(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by name, SKU or category...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            _buildFilterAction(Icons.filter_list_rounded, 'Filter'),
            const SizedBox(width: 12),
            _buildFilterAction(Icons.file_download_rounded, 'Export', onTap: _handleExport),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterAction(IconData icon, String label, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextButton.icon(
        onPressed: onTap ?? () {},
        icon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        label: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      ),
    );
  }

  Widget _buildDesktopTable(List<Product> products) {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          child: DataTable(
            horizontalMargin: 24,
            columnSpacing: 24,
            headingRowHeight: 60,
            dataRowMaxHeight: 70,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(label: Text('PRODUCT NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFF64748B)))),
              DataColumn(label: Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFF64748B)))),
              DataColumn(label: Text('PRICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFF64748B)))),
              DataColumn(label: Text('STOCK LEVEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFF64748B)))),
              DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFF64748B)))),
              DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFF64748B)))),
            ],
            rows: products.map((product) {
              return DataRow(cells: [
                DataCell(Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                  child: Text(product.categoryId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                )),
                DataCell(Text('₱${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(product.quantity.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: product.isLowStock ? const Color(0xFFEF4444) : const Color(0xFF1E293B)))),
                DataCell(_buildStatusBadge(product.isLowStock)),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => _showProductDialog(context, product: product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFF43F5E)),
                      onPressed: () => _confirmDelete(context, product),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<Product> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                _buildStatusBadge(product.isLowStock),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('${product.categoryId} • ₱${product.price.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text('Available Stock: ${product.quantity}', style: TextStyle(fontWeight: FontWeight.w600, color: product.isLowStock ? const Color(0xFFEF4444) : const Color(0xFF475569))),
              ],
            ),
            onTap: () => _showProductDialog(context, product: product),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(bool isLowStock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLowStock ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isLowStock ? 'LOW STOCK' : 'IN STOCK',
        style: TextStyle(
          color: isLowStock ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          const Text('No products found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('Try adjusting your search or add a new item.', style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
          const SizedBox(height: 16),
          const Text('Database Connection Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to remove "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _firestoreService.deleteProduct(product.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            child: const Text('Delete Assets'),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, {Product? product}) {
    final bool isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.name);
    final priceCtrl = TextEditingController(text: product?.price.toString());
    final qtyCtrl = TextEditingController(text: product?.quantity.toString());
    String? categoryId = product?.categoryId;
    final formKey = GlobalKey<FormState>();

    Future<void> submit() async {
      if (formKey.currentState!.validate()) {
        final item = Product(
          id: product?.id ?? '',
          name: nameCtrl.text.trim(),
          categoryId: categoryId!,
          price: double.parse(priceCtrl.text),
          quantity: int.parse(qtyCtrl.text),
        );
        try {
          final navigator = Navigator.of(context);
          isEdit ? await _firestoreService.updateProduct(item) : await _firestoreService.addProduct(item);
          if (navigator.canPop()) navigator.pop();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save: Check Firebase rules or connection'), backgroundColor: Colors.red)
            );
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Asset' : 'Add New Asset'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl, 
                  decoration: const InputDecoration(labelText: 'Asset Name'), 
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Category>>(
                  stream: _firestoreService.getCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      value: categories.any((c) => c.name == categoryId) ? categoryId : null,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                      onChanged: (val) => categoryId = val,
                      validator: (v) => v == null ? 'Required' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceCtrl, 
                        decoration: const InputDecoration(labelText: 'Unit Price', prefixText: '₱'), 
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => (v == null || double.tryParse(v) == null) ? 'Invalid' : null,
                        textInputAction: TextInputAction.next,
                      )
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: qtyCtrl, 
                        decoration: const InputDecoration(labelText: 'Initial Qty'), 
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || int.tryParse(v) == null) ? 'Invalid' : null,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => submit(),
                      )
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: submit,
            child: Text(isEdit ? 'Update Asset' : 'Add Asset'),
          ),
        ],
      ),
    );
  }
}
