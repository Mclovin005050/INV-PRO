import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/supplier.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile),
            const SizedBox(height: 32),
            Expanded(
              child: StreamBuilder<List<Supplier>>(
                stream: _firestoreService.getSuppliers(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final suppliers = snapshot.data ?? [];
                  if (suppliers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No suppliers found.', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => _showSupplierDialog(),
                            child: const Text('Add your first supplier'),
                          ),
                        ],
                      ),
                    );
                  }

                  return isMobile ? _buildMobileList(suppliers) : _buildDesktopTable(suppliers);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showSupplierDialog(),
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.person_add_rounded, color: Colors.white),
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
                'Supplier Directory',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your external vendors and contacts.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: () => _showSupplierDialog(),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add Supplier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopTable(List<Supplier> suppliers) {
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
            headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8FAFC)),
            horizontalMargin: 24,
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text('SUPPLIER NAME', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF64748B)))),
              DataColumn(label: Text('CONTACT', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF64748B)))),
              DataColumn(label: Text('DATE ADDED', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF64748B)))),
              DataColumn(label: Text('ACTIONS', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF64748B)))),
            ],
            rows: suppliers.map((supplier) {
              final dateStr = supplier.createdAt != null 
                  ? DateFormat('MMM dd, yyyy').format(supplier.createdAt!) 
                  : 'N/A';
              return DataRow(cells: [
                DataCell(Text(supplier.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)))),
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(supplier.phone, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text(supplier.email, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                )),
                DataCell(Text(dateStr, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13))),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6366F1)),
                      onPressed: () => _showSupplierDialog(supplier: supplier),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFF43F5E)),
                      onPressed: () => _confirmDelete(supplier),
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

  Widget _buildMobileList(List<Supplier> suppliers) {
    return ListView.separated(
      itemCount: suppliers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        final dateStr = supplier.createdAt != null 
            ? DateFormat('MMM dd, yyyy').format(supplier.createdAt!) 
            : 'N/A';
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            title: Text(supplier.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Added: $dateStr', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Text(supplier.phone, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') _showSupplierDialog(supplier: supplier);
                if (val == 'delete') _confirmDelete(supplier);
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

  void _confirmDelete(Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to remove "${supplier.name}" from your contacts?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                await _firestoreService.deleteSupplier(supplier.id);
                navigator.pop();
                messenger.showSnackBar(SnackBar(content: Text('${supplier.name} deleted'), behavior: SnackBarBehavior.floating));
              } catch (e) {
                navigator.pop();
                messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSupplierDialog({Supplier? supplier}) {
    final bool isEdit = supplier != null;
    final nameCtrl = TextEditingController(text: supplier?.name);
    final phoneCtrl = TextEditingController(text: supplier?.phone);
    final emailCtrl = TextEditingController(text: supplier?.email);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEdit ? 'Edit Supplier' : 'New Supplier', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Supplier Name', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. Global Tech Inc.'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                Text('Contact Phone', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '+1 234 567 890'),
                ),
                const SizedBox(height: 20),
                Text('Email Address', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'contact@supplier.com'),
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
                final s = Supplier(
                  id: supplier?.id ?? '',
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  createdAt: supplier?.createdAt,
                );
                
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                try {
                  if (isEdit) {
                    await _firestoreService.updateSupplier(s);
                  } else {
                    await _firestoreService.addSupplier(s);
                  }
                  navigator.pop();
                  messenger.showSnackBar(SnackBar(content: Text(isEdit ? 'Updated' : 'Added'), behavior: SnackBarBehavior.floating));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}
