import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventory_management_system/models/product.dart';
import 'package:inventory_management_system/models/category.dart';
import 'package:inventory_management_system/services/firestore_service.dart';

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
    final bool isMobile = screenWidth < 750;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile),
            const SizedBox(height: 24),
            _buildSearchAndFilters(),
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
                          p.categoryId.toLowerCase().contains(_searchQuery.toLowerCase())
                        ).toList();

                  if (products.isEmpty) return _buildEmptyState();

                  return isMobile ? _buildMobileList(products) : _buildDesktopTable(products);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showProductDialog(context),
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Inventory',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your stock levels and product details.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: () => _showProductDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Your inventory is empty.' : 'No matches found for "$_searchQuery"',
            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<Product> products) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          child: DataTable(
            horizontalMargin: 24,
            columnSpacing: 24,
            headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8FAFC)),
            columns: [
              DataColumn(label: Text('PRODUCT NAME', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF64748B)))),
              DataColumn(label: Text('CATEGORY', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF64748B)))),
              DataColumn(label: Text('PRICE', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF64748B)))),
              DataColumn(label: Text('STOCK', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF64748B)))),
              DataColumn(label: Text('STATUS', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF64748B)))),
              DataColumn(label: Text('ACTIONS', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF64748B)))),
            ],
            rows: products.map((product) {
              return DataRow(cells: [
                DataCell(Text(product.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)))),
                DataCell(Text(product.categoryId, style: const TextStyle(color: Color(0xFF64748B)))),
                DataCell(Text('₱${product.price.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.w500))),
                DataCell(Text(product.quantity.toString())),
                DataCell(_buildStatusBadge(product.isLowStock)),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6366F1)),
                      onPressed: () => _showProductDialog(context, product: product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFF43F5E)),
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
    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Expanded(child: Text(product.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))),
                _buildStatusBadge(product.isLowStock),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('${product.categoryId} • ₱${product.price.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text('Stock: ${product.quantity}', style: TextStyle(fontWeight: FontWeight.w600, color: product.isLowStock ? const Color(0xFFB91C1C) : const Color(0xFF1E293B))),
              ],
            ),
            onTap: () => _showProductDialog(context, product: product),
            trailing: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') _showProductDialog(context, product: product);
                if (val == 'delete') _confirmDelete(context, product);
              },
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 12), Text('Edit')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(bool isLowStock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLowStock ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isLowStock ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5)),
      ),
      child: Text(
        isLowStock ? 'Low Stock' : 'Healthy',
        style: TextStyle(
          color: isLowStock ? const Color(0xFFB91C1C) : const Color(0xFF059669),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
            const SizedBox(height: 16),
            const Text('Sync Error', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(error, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to remove "${product.name}" from inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                await _firestoreService.deleteProduct(product.id);
                if (navigator.canPop()) navigator.pop();
                messenger.showSnackBar(SnackBar(content: Text('${product.name} deleted'), behavior: SnackBarBehavior.floating));
              } catch (e) {
                if (navigator.canPop()) navigator.pop();
                messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? 'Edit Product' : 'Add New Product', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Product Name', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'e.g. Wireless Mouse'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                Text('Category', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                StreamBuilder<List<Category>>(
                  stream: _firestoreService.getCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    // Handle logic if selected category no longer exists
                    final isValid = categories.any((c) => c.name == selectedCategoryId);
                    return DropdownButtonFormField<String>(
                      value: isValid ? selectedCategoryId : null,
                      isExpanded: true,
                      decoration: const InputDecoration(hintText: 'Select category'),
                      items: categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                      onChanged: (val) => selectedCategoryId = val,
                      validator: (v) => v == null ? 'Required' : null,
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Price (₱)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(hintText: '0.00'),
                            validator: (v) => double.tryParse(v!) == null ? 'Invalid' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stock', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '0'),
                            validator: (v) => int.tryParse(v!) == null ? 'Invalid' : null,
                          ),
                        ],
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
              if (formKey.currentState!.validate() && selectedCategoryId != null) {
                final newProduct = Product(
                  id: product?.id ?? '',
                  name: nameController.text.trim(),
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
                  if (navigator.canPop()) navigator.pop();
                  messenger.showSnackBar(SnackBar(content: Text(isEditing ? 'Updated' : 'Added'), behavior: SnackBarBehavior.floating));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
                }
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}
