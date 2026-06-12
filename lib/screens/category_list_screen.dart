import 'package:flutter/material.dart';
import 'package:inventory_management_system/models/category.dart';
import 'package:inventory_management_system/services/firestore_service.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Categories',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(),
                icon: const Icon(Icons.add),
                label: Text(isMobile ? 'Add' : 'Add Category'),
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
          Expanded(
            child: StreamBuilder<List<Category>>(
              stream: _firestoreService.getCategories(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data ?? [];
                if (categories.isEmpty) {
                  return const Center(child: Text('No categories found. Click Add to start.'));
                }

                return isMobile ? _buildMobileList(categories) : _buildDesktopTable(categories);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<Category> categories) {
    return Card(
      elevation: 0,
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('CATEGORY NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: categories.map((category) {
            return DataRow(cells: [
              DataCell(Text('#${category.id.substring(0, category.id.length > 5 ? 5 : category.id.length)}...')),
              DataCell(Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showCategoryDialog(category: category),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => _deleteCategory(category),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<Category> categories) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ID: #${category.id.substring(0, category.id.length > 8 ? 8 : category.id.length)}'),
            onTap: () => _showCategoryDialog(category: category),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteCategory(category),
            ),
          ),
        );
      },
    );
  }

  void _deleteCategory(Category category) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _firestoreService.deleteCategory(category.id);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('${category.name} deleted')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCategoryDialog({Category? category}) {
    final bool isEdit = category != null;
    final nameController = TextEditingController(text: category?.name);
    final formKey = GlobalKey<FormState>();

    void submit() async {
      if (formKey.currentState!.validate()) {
        final newCategory = Category(
          id: category?.id ?? '',
          name: nameController.text.trim(),
        );
        
        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        try {
          if (isEdit) {
            await _firestoreService.updateCategory(newCategory);
          } else {
            await _firestoreService.addCategory(newCategory);
          }
          if (navigator.canPop()) navigator.pop();
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Category' : 'Add Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Category Name'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => submit(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: submit,
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}
