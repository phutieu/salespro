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
              // Add new product
              await FirebaseFirestore.instance
                  .collection('products')
                  .add(savedProduct.toMap());
            } else {
              // Edit existing product
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
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return DataTable(
                  columns: const [
                    DataColumn(label: Text('Product ID')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Sale Price')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: docs.map((doc) {
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
                            onPressed: () {
                              _deleteProduct(doc.id);
                            },
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
