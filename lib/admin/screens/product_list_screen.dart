import 'package:flutter/material.dart';
import 'package:salespro/admin/mock_data.dart';
import 'package:salespro/admin/models/product.dart';
import 'package:salespro/admin/widgets/product_form.dart';
import 'dart:math';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late List<Product> _products;

  @override
  void initState() {
    super.initState();
    _products = List.from(mockProducts);
  }

  void _showProductForm(BuildContext context, {Product? product}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProductForm(
          product: product,
          onSave: (savedProduct) {
            setState(() {
              if (product == null) {
                // Add new product
                _products.add(savedProduct);
              } else {
                // Edit existing product
                final index =
                    _products.indexWhere((p) => p.id == savedProduct.id);
                if (index != -1) {
                  _products[index] = savedProduct;
                }
              }
            });
          },
        );
      },
    );
  }

  void _deleteProduct(String productId) {
    setState(() {
      _products.removeWhere((p) => p.id == productId);
    });
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
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Product ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Sale Price')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _products.map((product) {
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
                            _showProductForm(context, product: product);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteProduct(product.id);
                          },
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
