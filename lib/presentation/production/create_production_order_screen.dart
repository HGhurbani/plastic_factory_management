// plastic_factory_management/lib/presentation/production/create_production_order_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/production_order_usecases.dart';

class CreateProductionOrderScreen extends StatefulWidget {
  @override
  _CreateProductionOrderScreenState createState() => _CreateProductionOrderScreenState();
}

class _CreateProductionOrderScreenState extends State<CreateProductionOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  ProductModel? _selectedProduct;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _batchNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(ProductionOrderUseCases useCases, UserModel currentUser) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.productRequired)), // تحتاج لإضافة هذا النص في ملف ARB
        );
        return;
      }

      setState(() {
        // يمكن إضافة مؤشر تحميل هنا
      });

      try {
        await useCases.createProductionOrder(
          selectedProduct: _selectedProduct!,
          requiredQuantity: int.parse(_quantityController.text),
          batchNumber: _batchNumberController.text,
          orderPreparer: currentUser,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.orderCreatedSuccessfully)), // إضافة هذا النص في ARB
        );
        Navigator.of(context).pop(); // العودة بعد الإرسال الناجح
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorCreatingOrder}: $e')), // إضافة هذا النص في ARB
        );
        print(e);
      } finally {
        setState(() {
          // إزالة مؤشر التحميل
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final productionUseCases = Provider.of<ProductionOrderUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context); // Current logged-in user

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(appLocalizations.createOrder)),
        body: Center(child: Text('لا يمكن إنشاء طلب بدون بيانات المستخدم.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.createOrder),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Product Selection
              StreamBuilder<List<ProductModel>>(
                stream: productionUseCases.getProductsForSelection(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('خطأ في تحميل المنتجات: ${snapshot.error}');
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('لا توجد منتجات متاحة. يرجى إضافة منتجات أولاً.');
                  }

                  return DropdownButtonFormField<ProductModel>(
                    value: _selectedProduct,
                    decoration: InputDecoration(
                      labelText: appLocalizations.product,
                      border: OutlineInputBorder(),
                    ),
                    items: snapshot.data!.map((product) {
                      return DropdownMenuItem(
                        value: product,
                        child: Text(product.name, textDirection: TextDirection.rtl),
                      );
                    }).toList(),
                    onChanged: (ProductModel? newValue) {
                      setState(() {
                        _selectedProduct = newValue;
                      });
                    },
                    validator: (value) =>
                    value == null ? appLocalizations.productRequired : null,
                  );
                },
              ),
              SizedBox(height: 16),
              // Required Quantity
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: appLocalizations.requiredQuantity,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLocalizations.fieldRequired; // إضافة هذا النص في ARB
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return appLocalizations.invalidQuantity; // إضافة هذا النص في ARB
                  }
                  return null;
                },
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 16),
              // Batch Number
              TextFormField(
                controller: _batchNumberController,
                decoration: InputDecoration(
                  labelText: appLocalizations.batchNumber,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLocalizations.fieldRequired;
                  }
                  return null;
                },
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _submitOrder(productionUseCases, currentUser),
                child: Text(appLocalizations.createOrder),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}