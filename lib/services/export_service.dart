import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'export_helper_stub.dart'
    if (dart.library.html) 'export_helper_web.dart'
    if (dart.library.io) 'export_helper_mobile.dart';

class ExportService {
  static Future<void> exportProductsToCsv(List<Product> products) async {
    if (products.isEmpty) return;

    // 1. Prepare data rows
    List<List<dynamic>> rows = [];
    
    // Add Headers
    rows.add([
      "Product ID",
      "Name",
      "Category",
      "Price",
      "Quantity",
      "Status"
    ]);

    // Add Data
    for (var p in products) {
      rows.add([
        p.id,
        p.name,
        p.categoryId,
        p.price,
        p.quantity,
        p.isLowStock ? "Low Stock" : "In Stock"
      ]);
    }

    // 2. Convert to CSV string
    String csvData = const ListToCsvConverter().convert(rows);
    String fileName = "inventory_export_${DateTime.now().millisecondsSinceEpoch}.csv";

    // 3. Save file using platform-specific helper
    try {
      await saveCsvFile(csvData, fileName);
    } catch (e) {
      debugPrint("Export error: $e");
      rethrow;
    }
  }
}
