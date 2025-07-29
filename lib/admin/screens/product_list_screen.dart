import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salespro/admin/models/product.dart';
import 'package:salespro/admin/widgets/product_form.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const int pageSize = 10;
  List<DocumentSnapshot> products = [];
  DocumentSnapshot? lastDoc;
  List<DocumentSnapshot> prevDocs = [];
  bool hasMore = true;
  bool isLoading = false;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts({bool next = false, bool prev = false}) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('products')
        .orderBy('name')
        .limit(pageSize);

    if (next && lastDoc != null) {
      query = query.startAfterDocument(lastDoc!);
    } else if (prev && prevDocs.isNotEmpty) {
      query = query.startAtDocument(prevDocs.last);
    }

    final snapshot = await query.get();
    setState(() {
      if (next) {
        currentPage++;
        prevDocs.add(products.isNotEmpty ? products.first : lastDoc!);
      } else if (prev && currentPage > 1) {
        currentPage--;
        if (prevDocs.isNotEmpty) prevDocs.removeLast();
      }
      products = snapshot.docs;
      lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : lastDoc;
      hasMore = snapshot.docs.length == pageSize;
      isLoading = false;
    });
  }

  void _showProductForm(BuildContext context, {DocumentSnapshot? doc}) {
    Product? product;
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      product = Product.fromMap(data..['id'] = doc.id);
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProductForm(
          product: product,
          onSave: (savedProduct) async {
            if (doc == null) {
              await FirebaseFirestore.instance
                  .collection('products')
                  .add(savedProduct.toMap());
            } else {
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(doc.id)
                  .update(savedProduct.toMap());
            }
            setState(() {});
          },
        );
      },
    );
  }

  void _deleteProduct(String docId) async {
    await FirebaseFirestore.instance.collection('products').doc(docId).delete();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Products',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              _showProductForm(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : DataTable(
                    columns: const [
                      DataColumn(label: Text('Product ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Sale Price')),
                      DataColumn(label: Text('Stock')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: products.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final product = Product.fromMap(data..['id'] = doc.id);
                      return DataRow(cells: [
                        DataCell(Text(product.id)),
                        DataCell(Text(product.name)),
                        DataCell(Text(product.salePrice.toStringAsFixed(0))),
                        DataCell(Text(product.stockQuantity.toString())),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showProductForm(context, doc: doc);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _confirmDeleteProduct(context, doc.id),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: currentPage > 1 && !isLoading
                    ? () => _fetchProducts(prev: true)
                    : null,
                child: const Text('Trang trước'),
              ),
              const SizedBox(width: 16),
              Text('Trang $currentPage'),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: hasMore && !isLoading
                    ? () => _fetchProducts(next: true)
                    : null,
                child: const Text('Trang sau'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa sản phẩm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(productId)
                  .delete();
              if (context.mounted) {
                Navigator.of(context).pop();
                _fetchProducts();
              }
            },
            child: const Text('Xóa'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
