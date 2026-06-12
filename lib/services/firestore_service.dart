import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:inventory_management_system/models/product.dart';
import 'package:inventory_management_system/models/category.dart';
import 'package:inventory_management_system/models/supplier.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _handleError(String operation, dynamic e) {
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        debugPrint("CRITICAL: Firestore Permission Denied. Check your Security Rules!");
      }
    }
    debugPrint("Firestore Error [$operation]: $e");
  }

  // --- Product Operations ---
  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList();
    }).handleError((e) => _handleError("getProducts", e));
  }

  Future<void> addProduct(Product product) async {
    try {
      await _db.collection('products').add(product.toMap());
    } catch (e) {
      _handleError("addProduct", e);
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _db.collection('products').doc(product.id).update(product.toMap());
    } catch (e) {
      _handleError("updateProduct", e);
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _db.collection('products').doc(id).delete();
    } catch (e) {
      _handleError("deleteProduct", e);
      rethrow;
    }
  }

  // --- Category Operations ---
  Stream<List<Category>> getCategories() {
    return _db.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Category.fromMap(doc.id, doc.data())).toList();
    }).handleError((e) => _handleError("getCategories", e));
  }

  Future<void> addCategory(Category category) async {
    try {
      final id = category.name.toLowerCase().trim().replaceAll(' ', '_');
      await _db.collection('categories').doc(id).set(category.toMap());
    } catch (e) {
      _handleError("addCategory", e);
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _db.collection('categories').doc(category.id).update(category.toMap());
    } catch (e) {
      _handleError("updateCategory", e);
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final products = await _db.collection('products').where('categoryId', isEqualTo: id).limit(1).get();
      if (products.docs.isNotEmpty) {
        throw Exception('Cannot delete category: It is currently used by products.');
      }
      await _db.collection('categories').doc(id).delete();
    } catch (e) {
      _handleError("deleteCategory", e);
      rethrow;
    }
  }

  // --- Supplier Operations ---
  Stream<List<Supplier>> getSuppliers() {
    return _db.collection('suppliers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Supplier.fromMap(doc.id, doc.data())).toList();
    }).handleError((e) => _handleError("getSuppliers", e));
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      await _db.collection('suppliers').add(supplier.toMap());
    } catch (e) {
      _handleError("addSupplier", e);
      rethrow;
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      await _db.collection('suppliers').doc(supplier.id).update(supplier.toMap());
    } catch (e) {
      _handleError("updateSupplier", e);
      rethrow;
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _db.collection('suppliers').doc(id).delete();
    } catch (e) {
      _handleError("deleteSupplier", e);
      rethrow;
    }
  }

  // --- Transaction Management ---
  Stream<List<Map<String, dynamic>>> getTransactions() {
    return _db.collection('transactions')
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList())
        .handleError((e) => _handleError("getTransactions", e));
  }

  Future<void> recordTransaction({
    required String productId, 
    required String productName, 
    required int quantity, 
    required String type,
    required double price,
  }) async {
    final productRef = _db.collection('products').doc(productId);
    
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);
        if (!snapshot.exists) throw Exception('Product does not exist!');

        int currentStock = (snapshot.data()?['quantity'] ?? 0).toInt();
        int newStock = type == 'IN' ? currentStock + quantity : currentStock - quantity;

        if (newStock < 0) throw Exception('Insufficient stock!');

        transaction.update(productRef, {'quantity': newStock});
        transaction.set(_db.collection('transactions').doc(), {
          'productId': productId,
          'productName': productName,
          'quantity': quantity,
          'type': type,
          'priceAtTime': price,
          'totalValue': price * quantity,
          'date': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      _handleError("transaction", e);
      rethrow;
    }
  }
}
