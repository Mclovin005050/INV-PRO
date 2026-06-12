import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

Future<void> saveCsvFile(String csvData, String fileName) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvData);
    debugPrint("File saved to: ${file.path}");
    // In a production app, you might want to use 'open_file' or 'share_plus' here
  } catch (e) {
    debugPrint("Error saving CSV on mobile: $e");
  }
}
