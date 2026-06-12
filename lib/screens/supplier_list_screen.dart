import 'package:flutter/material.dart';
import '../models/supplier.dart';
import '../services/firestore_service.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
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
                'Supplier Management',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showSupplierDialog(),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(isMobile ? 'Add' : 'Add Supplier'),
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
            child: StreamBuilder<List<Supplier>>(
              stream: _firestoreService.getSuppliers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final suppliers = snapshot.data ?? [];
                if (suppliers.isEmpty) {
                  return const Center(child: Text('No suppliers found. Click Add to start.'));
                }

                return isMobile ? _buildMobileList(suppliers) : _buildDesktopTable(suppliers);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<Supplier> suppliers) {
    return Card(
      elevation: 0,
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('SUPPLIER NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('CONTACT PHONE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('EMAIL ADDRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: suppliers.map((supplier) {
            return DataRow(cells: [
              DataCell(Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(supplier.phone)),
              DataCell(Text(supplier.email)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showSupplierDialog(supplier: supplier),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => _firestoreService.deleteSupplier(supplier.id),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<Supplier> suppliers) {
    return ListView.builder(
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(supplier.phone),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(supplier.email),
                  ],
                ),
              ],
            ),
            onTap: () => _showSupplierDialog(supplier: supplier),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _firestoreService.deleteSupplier(supplier.id),
            ),
          ),
        );
      },
    );
  }

  void _showSupplierDialog({Supplier? supplier}) {
    final bool isEdit = supplier != null;
    final nameCtrl = TextEditingController(text: supplier?.name);
    final phoneCtrl = TextEditingController(text: supplier?.phone);
    final emailCtrl = TextEditingController(text: supplier?.email);
    final formKey = GlobalKey<FormState>();

    Future<void> submit() async {
      if (formKey.currentState!.validate()) {
        final s = Supplier(
          id: supplier?.id ?? '',
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          email: emailCtrl.text.trim(),
        );
        
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        try {
          if (isEdit) {
            await _firestoreService.updateSupplier(s);
          } else {
            await _firestoreService.addSupplier(s);
          }
          if (navigator.canPop()) navigator.pop();
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Supplier' : 'Add Supplier'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl, 
                decoration: const InputDecoration(labelText: 'Supplier Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: phoneCtrl, 
                decoration: const InputDecoration(labelText: 'Phone Number'), 
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailCtrl, 
                decoration: const InputDecoration(labelText: 'Email Address'), 
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => submit(),
              ),
            ],
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
