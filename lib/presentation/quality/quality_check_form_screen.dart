// plastic_factory_management/lib/presentation/quality/quality_check_form_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/data/models/production_order_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/quality_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/sales_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/production_order_usecases.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/core/services/file_upload_service.dart';

enum OrderType { sales, production }

class QualityCheckFormScreen extends StatefulWidget {
  const QualityCheckFormScreen({Key? key}) : super(key: key);

  @override
  State<QualityCheckFormScreen> createState() => _QualityCheckFormScreenState();
}

class _QualityCheckFormScreenState extends State<QualityCheckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  ProductModel? _selectedProduct;
  final TextEditingController _orderIdController = TextEditingController();
  OrderType? _orderType;
  SalesOrderModel? _salesOrder;
  ProductionOrderModel? _productionOrder;
  final TextEditingController _inspectedController = TextEditingController();
  final TextEditingController _rejectedController = TextEditingController();
  final TextEditingController _supervisorController = TextEditingController();
  final TextEditingController _defectController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  final FileUploadService _uploadService = FileUploadService();

  @override
  void dispose() {
    _orderIdController.dispose();
    _inspectedController.dispose();
    _rejectedController.dispose();
    _supervisorController.dispose();
    _defectController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _images.add(File(picked.path));
      });
    }
  }

  Future<void> _fetchOrder() async {
    final id = _orderIdController.text.trim();
    if (id.isEmpty || _orderType == null) return;
    if (_orderType == OrderType.sales) {
      final salesUseCases = Provider.of<SalesUseCases>(context, listen: false);
      final order = await salesUseCases.getSalesOrderById(id);
      setState(() {
        _salesOrder = order;
        _productionOrder = null;
        _selectedProduct = null;
      });
    } else {
      final prodUseCases =
          Provider.of<ProductionOrderUseCases>(context, listen: false);
      final order = await prodUseCases.getProductionOrderById(id);
      setState(() {
        _productionOrder = order;
        _salesOrder = null;
        _selectedProduct = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = Provider.of<UserModel?>(context, listen: false);
    if (currentUser == null || _selectedProduct == null) return;

    final inspected = int.tryParse(_inspectedController.text) ?? 0;
    final rejected = int.tryParse(_rejectedController.text) ?? 0;
    final List<String> urls = [];
    for (int i = 0; i < _images.length; i++) {
      final url = await _uploadService.uploadFile(
          _images[i],
          'quality_checks/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      if (url != null) urls.add(url);
    }

    final useCases = Provider.of<QualityUseCases>(context, listen: false);
    await useCases.recordQualityCheck(
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      inspectedQuantity: inspected,
      rejectedQuantity: rejected,
      shiftSupervisorUid: _supervisorController.text,
      shiftSupervisorName: _supervisorController.text,
      qualityInspectorUid: currentUser.uid,
      qualityInspectorName: currentUser.name,
      defectAnalysis: _defectController.text,
      imageUrls: urls,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final inventoryUseCases = Provider.of<InventoryUseCases>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addQualityCheck),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<OrderType>(
                  value: _orderType,
                  decoration: InputDecoration(labelText: loc.orderType),
                  items: [
                    DropdownMenuItem(
                      value: OrderType.sales,
                      child: Text(loc.salesOrder),
                    ),
                    DropdownMenuItem(
                      value: OrderType.production,
                      child: Text(loc.productionOrder),
                    ),
                  ],
                  onChanged: (val) => setState(() => _orderType = val),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _orderIdController,
                  decoration: InputDecoration(labelText: loc.orderId),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _fetchOrder,
                  child: Text(loc.fetchOrder),
                ),
                if (_salesOrder != null || _productionOrder != null) ...[
                  const SizedBox(height: 12),
                  _buildOrderDetails(loc),
                  const SizedBox(height: 12),
                ],
                StreamBuilder<List<ProductModel>>(
                  stream: inventoryUseCases.getProducts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final products = snapshot.data!;
                    return DropdownButtonFormField<ProductModel>(
                      value: _selectedProduct,
                      decoration:
                          InputDecoration(labelText: loc.product),
                      items: products
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name,
                                    textDirection: TextDirection.rtl),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedProduct = val),
                      validator: (v) => v == null ? loc.fieldRequired : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _inspectedController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: loc.inspectProductDelivery),
                  validator: (v) => v == null || v.isEmpty
                      ? loc.fieldRequired
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rejectedController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: loc.rejectedQuantity),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _supervisorController,
                  decoration: InputDecoration(labelText: loc.shiftSupervisor),
                  validator: (v) => v == null || v.isEmpty
                      ? loc.fieldRequired
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _defectController,
                  decoration: InputDecoration(labelText: loc.defectAnalysis),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final img in _images)
                      Image.file(img, width: 80, height: 80, fit: BoxFit.cover),
                    IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_a_photo),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(loc.save),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetails(AppLocalizations loc) {
    if (_salesOrder != null) {
      final o = _salesOrder!;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${loc.salesOrder} #${o.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${loc.customerName}: ${o.customerName}'),
              Text('${loc.statusColon} ${o.status.toArabicString()}'),
            ],
          ),
        ),
      );
    }
    if (_productionOrder != null) {
      final o = _productionOrder!;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${loc.productionOrder} #${o.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (o.machineName != null)
                Text('${loc.machineName}: ${o.machineName}'),
              Text('${loc.productName}: ${o.productName}'),
              Text('${loc.statusColon} ${o.status.toArabicString()}'),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
