import 'package:flutter/material.dart';
import 'package:salespro/admin/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ProductForm extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const ProductForm({super.key, this.product, required this.onSave});

  @override
  _ProductFormState createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _unitController;
  late TextEditingController _salePriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _stockQuantityController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? '');
    _unitController = TextEditingController(text: widget.product?.unit ?? '');
    _salePriceController =
        TextEditingController(text: widget.product?.salePrice.toString() ?? '');
    _purchasePriceController = TextEditingController(
        text: widget.product?.purchasePrice.toString() ?? '');
    _stockQuantityController = TextEditingController(
        text: widget.product?.stockQuantity.toString() ?? '');
    _categoryController =
        TextEditingController(text: widget.product?.category ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              TextFormField(
                controller: _salePriceController,
                decoration: const InputDecoration(labelText: 'Sale Price'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _purchasePriceController,
                decoration: const InputDecoration(labelText: 'Purchase Price'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _stockQuantityController,
                decoration: const InputDecoration(labelText: 'Stock Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('Save'),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              if (widget.product == null) {
                // Tạo sản phẩm mới với id tự động P001, P002...
                final newId = await _generateNextProductId();
                final newProduct = Product(
                  id: newId,
                  name: _nameController.text,
                  description: _descriptionController.text,
                  unit: _unitController.text,
                  salePrice: double.tryParse(_salePriceController.text) ?? 0,
                  purchasePrice:
                      double.tryParse(_purchasePriceController.text) ?? 0,
                  stockQuantity:
                      int.tryParse(_stockQuantityController.text) ?? 0,
                  category: _categoryController.text,
                );
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(newId)
                    .set(newProduct.toMap());
                widget.onSave(newProduct);
              } else {
                // Sửa sản phẩm cũ
                final updatedProduct = Product(
                  id: widget.product!.id,
                  name: _nameController.text,
                  description: _descriptionController.text,
                  unit: _unitController.text,
                  salePrice: double.tryParse(_salePriceController.text) ?? 0,
                  purchasePrice:
                      double.tryParse(_purchasePriceController.text) ?? 0,
                  stockQuantity:
                      int.tryParse(_stockQuantityController.text) ?? 0,
                  category: _categoryController.text,
                );
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(updatedProduct.id)
                    .update(updatedProduct.toMap());
                widget.onSave(updatedProduct);
              }
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }

  Future<String> _generateNextProductId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .orderBy('id', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return 'P001';
    final lastId = snapshot.docs.first['id'] as String;
    final number = int.tryParse(lastId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return 'P' + (number + 1).toString().padLeft(3, '0');
  }
}
