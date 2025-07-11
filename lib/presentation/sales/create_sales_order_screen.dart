// plastic_factory_management/lib/presentation/sales/create_sales_order_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/customer_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/sales_usecases.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';
import 'package:signature/signature.dart'; // للتوقيع الرقمي
import 'dart:io'; // لاستخدام File
import 'dart:typed_data'; // لاستخدام Uint8List
import 'package:path_provider/path_provider.dart'; // لحفظ التوقيع مؤقتاً
import 'package:flutter/foundation.dart';

import '../../domain/usecases/inventory_usecases.dart';

class CreateSalesOrderScreen extends StatefulWidget {
  @override
  _CreateSalesOrderScreenState createState() => _CreateSalesOrderScreenState();
}

class _CreateSalesOrderScreenState extends State<CreateSalesOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  CustomerModel? _selectedCustomer;
  List<SalesOrderItem> _orderItems = [];
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  double _totalAmount = 0.0;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  void _calculateTotalAmount() {
    double total = 0.0;
    for (var item in _orderItems) {
      total += item.quantity * item.unitPrice;
    }
    setState(() {
      _totalAmount = total;
    });
  }

  Future<void> _addOrUpdateOrderItem(AppLocalizations appLocalizations, SalesUseCases useCases, {SalesOrderItem? existingItem, int? index}) async {
    ProductModel? selectedProduct;
    int quantity = existingItem?.quantity ?? 1;
    double unitPrice = existingItem?.unitPrice ?? 0.0;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                existingItem != null ? appLocalizations.editItem : appLocalizations.addItem,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<List<ProductModel>>(
                      stream: useCases.getProductCatalogForSales(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator(color: AppColors.primary));
                        }
                        if (snapshot.hasError) {
                          return Text('خطأ في تحميل المنتجات: ${snapshot.error}', style: TextStyle(color: Colors.red));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text('لا توجد منتجات متاحة لإضافتها.', style: TextStyle(color: Colors.grey));
                        }
                        // Pre-select product if editing
                        if (existingItem != null && selectedProduct == null) {
                          selectedProduct = snapshot.data!.firstWhere((p) => p.id == existingItem.productId, orElse: () => snapshot.data!.first);
                        }

                        return DropdownButtonFormField<ProductModel>(
                          value: selectedProduct,
                          decoration: InputDecoration(
                            labelText: appLocalizations.product,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                          items: snapshot.data!.map((product) {
                            return DropdownMenuItem(
                              value: product,
                              child: Text(product.name, textDirection: TextDirection.rtl),
                            );
                          }).toList(),
                          onChanged: (ProductModel? newValue) {
                            setState(() {
                              selectedProduct = newValue;
                            });
                          },
                          validator: (value) => value == null ? appLocalizations.productRequired : null,
                        );
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      initialValue: quantity.toString(),
                      decoration: InputDecoration(
                        labelText: appLocalizations.quantity,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        quantity = int.tryParse(value) ?? 1;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return appLocalizations.fieldRequired;
                        if (int.tryParse(value) == null || int.parse(value)! <= 0) return appLocalizations.invalidQuantity;
                        return null;
                      },
                      textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      initialValue: unitPrice.toStringAsFixed(2),
                      decoration: InputDecoration(
                        labelText: appLocalizations.unitPrice,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        unitPrice = double.tryParse(value) ?? 0.0;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return appLocalizations.fieldRequired;
                        if (double.tryParse(value) == null || double.parse(value)! < 0) return appLocalizations.invalidNumber;
                        return null;
                      },
                      textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(foregroundColor: AppColors.dark),
                  child: Text(appLocalizations.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedProduct == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.productRequired)));
                      return;
                    }
                    if (quantity <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.invalidQuantity)));
                      return;
                    }
                    if (unitPrice < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.invalidNumber)));
                      return;
                    }

                    final newItem = SalesOrderItem(
                      productId: selectedProduct!.id,
                      productName: selectedProduct!.name,
                      quantity: quantity,
                      unitPrice: unitPrice,
                    );
                    Navigator.of(dialogContext).pop(newItem);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(existingItem != null ? appLocalizations.save : appLocalizations.add),
                ),
              ],
            );
          },
        );
      },
    ).then((newItem) {
      if (newItem != null) {
        setState(() {
          if (existingItem != null && index != null) {
            _orderItems[index] = newItem; // Update existing item
          } else {
            _orderItems.add(newItem); // Add new item
          }
          _calculateTotalAmount();
        });
      }
    });
  }

  Future<void> _submitOrder(SalesUseCases useCases, InventoryUseCases inventoryUseCases, UserModel currentUser) async {
    if (_formKey.currentState!.validate() && _orderItems.isNotEmpty) {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.customerRequired)),
        );
        return;
      }
      if (_orderItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.atLeastOneItemRequired)),
        );
        return;
      }
      if (_signatureController.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.signatureRequired)),
        );
        return;
      }

      setState(() {
        // Show loading indicator
      });

      try {
        final Uint8List? signaturePngBytes =
            await _signatureController.toPngBytes();
        File? signatureFile;
        Uint8List? signatureBytes;
        if (signaturePngBytes != null) {
          if (kIsWeb) {
            signatureBytes = signaturePngBytes;
          } else {
            final tempDir = await getTemporaryDirectory();
            signatureFile = File(
                '${tempDir.path}/customer_signature_${DateTime.now().microsecondsSinceEpoch}.png');
            await signatureFile.writeAsBytes(signaturePngBytes);
          }
        }

        await useCases.createSalesOrder(
          customer: _selectedCustomer!,
          salesRepresentative: currentUser,
          orderItems: _orderItems,
          totalAmount: _totalAmount,
          customerSignatureFile: signatureFile,
          customerSignatureBytes: signatureBytes,
          inventoryUseCases: inventoryUseCases,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.salesOrderCreatedSuccessfully)),
        );
        Navigator.of(context).pop(); // Go back after successful submission
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorCreatingSalesOrder}: $e')),
        );
        print(e);
      } finally {
        setState(() {
          // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final salesUseCases = Provider.of<SalesUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(appLocalizations.salesOrders)),
        body: Center(child: Text('لا يمكن إنشاء طلب بدون بيانات المستخدم.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.createSalesOrder),
        centerTitle: true,
        backgroundColor: AppColors.primary, // Apply primary color to AppBar
        foregroundColor: Colors.white, // White text for AppBar title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Customer Selection
              StreamBuilder<List<CustomerModel>>(
                stream: salesUseCases.getCustomers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (snapshot.hasError) {
                    return Text('خطأ في تحميل العملاء: ${snapshot.error}', style: TextStyle(color: Colors.red));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('لا توجد عملاء متاحون. يرجى إضافة عميل أولاً.', style: TextStyle(color: Colors.grey));
                  }

                  return DropdownButtonFormField<CustomerModel>(
                    value: _selectedCustomer,
                    decoration: InputDecoration(
                      labelText: appLocalizations.customer,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    items: snapshot.data!.map((customer) {
                      return DropdownMenuItem(
                        value: customer,
                        child: Text(customer.name, textDirection: TextDirection.rtl),
                      );
                    }).toList(),
                    onChanged: (CustomerModel? newValue) {
                      setState(() {
                        _selectedCustomer = newValue;
                      });
                    },
                    validator: (value) =>
                    value == null ? appLocalizations.customerRequired : null,
                  );
                },
              ),
              SizedBox(height: 24),
              // Order Items
              Text(appLocalizations.orderItems, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark), textAlign: TextAlign.right),
              SizedBox(height: 12),
              _orderItems.isEmpty
                  ? Text(appLocalizations.noItemsAdded, textAlign: TextAlign.right, style: TextStyle(color: Colors.grey[700]))
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _orderItems.length,
                itemBuilder: (context, index) {
                  final item = _orderItems[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text(item.productName, textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${appLocalizations.quantity}: ${item.quantity} | ${appLocalizations.unitPrice}:${item.unitPrice.toStringAsFixed(2)} ريال سعودي ', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.grey[700])),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: AppColors.primary),
                            onPressed: () => _addOrUpdateOrderItem(appLocalizations, salesUseCases, existingItem: item, index: index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _orderItems.removeAt(index);
                                _calculateTotalAmount();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                icon: Icon(Icons.add_shopping_cart_outlined, color: Colors.white),
                label: Text(appLocalizations.addOrderItem, style: TextStyle(color: Colors.white)),
                onPressed: () => _addOrUpdateOrderItem(appLocalizations, salesUseCases),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              SizedBox(height: 24),
              // Total Amount
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${appLocalizations.totalAmount} : ${_totalAmount.toStringAsFixed(2)} ريال سعودي ',                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                  textDirection: TextDirection.rtl,
                ),
              ),
              SizedBox(height: 24),
              // Customer Signature
              Text(appLocalizations.customerSignature, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark), textAlign: TextAlign.right),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                width: double.infinity,
                child: Signature(
                  controller: _signatureController,
                  height: 200,
                  backgroundColor: Colors.grey[50]!,
                ),
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: Icon(Icons.clear_outlined, color: AppColors.dark),
                  onPressed: () => _signatureController.clear(),
                  label: Text(appLocalizations.clearSignature, style: TextStyle(color: AppColors.dark)),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.send, color: Colors.white),
                label: Text(appLocalizations.submitOrder, style: TextStyle(color: Colors.white)),
                onPressed: () => _submitOrder(
                    salesUseCases,
                    Provider.of<InventoryUseCases>(context, listen: false),
                    currentUser),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}