import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/supplier.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Product Operations ---
  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> addProduct(Product product) {
    return _db.collection('products').add(product.toMap());
  }

  Future<void> updateProduct(Product product) {
    return _db.collection('products').doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String id) {
    return _db.collection('products').doc(id).delete();
  }

  // --- Category Operations ---
  Stream<List<Category>> getCategories() {
    return _db.collection('categories').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Category.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> addCategory(Category category) {
    return _db.collection('categories').add(category.toMap());
  }

  Future<void> updateCategory(Category category) {
    return _db.collection('categories').doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    // Check if any products are using this category before deleting
    final products = await _db.collection('products').where('categoryId', isEqualTo: id).limit(1).get();
    if (products.docs.isNotEmpty) {
      throw Exception('Cannot delete category: It is currently used by one or more products.');
    }
    return _db.collection('categories').doc(id).delete();
  }

  // --- Supplier Operations ---
  Stream<List<Supplier>> getSuppliers() {
    return _db.collection('suppliers').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Supplier.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> addSupplier(Supplier supplier) {
    return _db.collection('suppliers').add(supplier.toMap());
  }

  Future<void> updateSupplier(Supplier supplier) {
    return _db.collection('suppliers').doc(supplier.id).update(supplier.toMap());
  }

  Future<void> deleteSupplier(String id) {
    return _db.collection('suppliers').doc(id).delete();
  }

  // --- Transaction & Stock Management ---
  Stream<List<Map<String, dynamic>>> getTransactions() {
    return _db.collection('transactions').orderBy('date', descending: true).limit(50).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> recordTransaction({
    required String productId, 
    required String productName, 
    required int quantity, 
    required String type,
    required double price,
  }) async {
    final productRef = _db.collection('products').doc(productId);
    
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      if (!snapshot.exists) throw Exception('Product does not exist!');

      int currentStock = (snapshot.data()?['quantity'] ?? 0).toInt();
      int newStock = type == 'IN' ? currentStock + quantity : currentStock - quantity;

      if (newStock < 0) throw Exception('Insufficient stock for this operation!');

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
  }
}
