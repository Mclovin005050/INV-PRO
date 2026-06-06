import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Inventory',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showProductDialog(context),
                icon: const Icon(Icons.add),
                label: Text(isMobile ? 'Add' : 'Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchAndFilters(),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _firestoreService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allProducts = snapshot.data ?? [];
                final products = _searchQuery.isEmpty
                    ? allProducts
                    : allProducts.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || p.categoryId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No products found. Start by adding one!' : 'No products match your search.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return isMobile ? _buildMobileList(products) : _buildDesktopTable(products);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Firebase Connection Error',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              'Error details: $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 24),
            const Text(
              'Please ensure:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Firestore rules allow read/write\n• Internet connection is active'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search products by name or category...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(List<Product> products) {
    return Card(
      elevation: 0,
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            horizontalMargin: 24,
            columnSpacing: 24,
            headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(label: Text('PRODUCT NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('CATEGORY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('PRICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('STOCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
            rows: products.map((product) {
              return DataRow(cells: [
                DataCell(Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(product.categoryId)),
                // Updated currency to PHP
                DataCell(Text('₱${product.price.toStringAsFixed(2)}')),
                DataCell(Text(product.quantity.toString())),
                DataCell(_buildStatusBadge(product.isLowStock)),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showProductDialog(context, product: product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
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
                // Updated currency to PHP
                Text('${product.categoryId} • ₱${product.price.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                Text('Stock: ${product.quantity}', style: TextStyle(color: product.isLowStock ? Colors.red : Colors.grey.shade600)),
              ],
            ),
            onTap: () => _showProductDialog(context, product: product),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, product),
            ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLowStock ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7)),
      ),
      child: Text(
        isLowStock ? 'Low Stock' : 'In Stock',
        style: TextStyle(
          color: isLowStock ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _firestoreService.deleteProduct(product.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(ApiResponseSnackBar('Product deleted'));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, {Product? product}) {
    final bool isEditing = product != null;
    final nameController = TextEditingController(text: product?.name);
    final priceController = TextEditingController(text: product?.price.toString());
    final quantityController = TextEditingController(text: product?.quantity.toString());
    String? selectedCategoryId = product?.categoryId;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Category>>(
                  stream: _firestoreService.getCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    // Ensure current value is in items to avoid error
                    String? initialVal;
                    if (categories.any((c) => c.name == selectedCategoryId)) {
                      initialVal = selectedCategoryId;
                    }

                    return DropdownButtonFormField<String>(
                      value: initialVal,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                      onChanged: (val) => selectedCategoryId = val,
                      validator: (v) => v == null ? 'Required' : null,
                      hint: const Text('Select Category'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price', prefixText: '₱'),
                        keyboardType: TextInputType.number,
                        validator: (v) => double.tryParse(v!) == null ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                        validator: (v) => int.tryParse(v!) == null ? 'Invalid' : null,
                      ),
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newProduct = Product(
                  id: product?.id ?? '',
                  name: nameController.text,
                  categoryId: selectedCategoryId!,
                  price: double.parse(priceController.text),
                  quantity: int.parse(quantityController.text),
                );

                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                try {
                  if (isEditing) {
                    await _firestoreService.updateProduct(newProduct);
                  } else {
                    await _firestoreService.addProduct(newProduct);
                  }
                  navigator.pop();
                  messenger.showSnackBar(
                    ApiResponseSnackBar(isEditing ? 'Product updated' : 'Product added'),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    ApiResponseSnackBar('Error: $e'),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}

class ApiResponseSnackBar extends SnackBar {
  ApiResponseSnackBar(String message, {super.key})
      : super(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        );
}
