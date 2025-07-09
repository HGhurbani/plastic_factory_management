// plastic_factory_management/lib/presentation/production/create_production_order_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/domain/usecases/machinery_operator_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/production_order_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/user_usecases.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';

class CreateProductionOrderScreen extends StatefulWidget {
  @override
  _CreateProductionOrderScreenState createState() => _CreateProductionOrderScreenState();
}

class _CreateProductionOrderScreenState extends State<CreateProductionOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  ProductModel? _selectedProduct;
  MachineModel? _selectedMachine;
  UserModel? _selectedSupervisor;
  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(ProductionOrderUseCases useCases, UserModel currentUser) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.productRequired)),
        );
        return;
      }
      if (_selectedMachine == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.machineRequired)),
        );
        return;
      }
      if (_selectedSupervisor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.fieldRequired)),
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
          orderPreparer: currentUser,
          selectedMachine: _selectedMachine!,
          shiftSupervisor: _selectedSupervisor!,
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

    final machineryUseCases = Provider.of<MachineryOperatorUseCases>(context);
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
                    value: snapshot.data!.contains(_selectedProduct)
                        ? _selectedProduct
                        : null,
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
              StreamBuilder<List<MachineModel>>(
                stream: machineryUseCases.getMachines(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('خطأ في تحميل الآلات: ${snapshot.error}');
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('لا توجد آلات متاحة. يرجى إضافة آلات أولاً.');
                  }

                  return DropdownButtonFormField<MachineModel>(
                    value: snapshot.data!.contains(_selectedMachine)
                        ? _selectedMachine
                        : null,
                    decoration: InputDecoration(
                      labelText: appLocalizations.machine,
                      border: const OutlineInputBorder(),
                    ),
                    items: snapshot.data!.map((machine) {
                      final label = machine.status == MachineStatus.underMaintenance
                          ? '${machine.name} (${appLocalizations.underMaintenance})'
                          : machine.name;
                      return DropdownMenuItem(
                        value: machine,
                        child: Text(label, textDirection: TextDirection.rtl),
                      );
                    }).toList(),
                    onChanged: (MachineModel? newValue) {
                      if (newValue != null && newValue.status == MachineStatus.underMaintenance) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(appLocalizations.machineUnderMaintenanceMessage)),
                        );
                        return;
                      }
                      setState(() {
                        _selectedMachine = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? appLocalizations.machineRequired : null,
                  );
                },
              ),
              SizedBox(height: 16),
              FutureBuilder<List<UserModel>>( 
                future: Provider.of<UserUseCases>(context, listen: false)
                    .getUsersByRole(UserRole.productionShiftSupervisor),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text(appLocalizations.noUsersAvailable);
                  }
                  return DropdownButtonFormField<UserModel>(
                    value: snapshot.data!
                            .any((u) => u.uid == _selectedSupervisor?.uid)
                        ? _selectedSupervisor
                        : null,
                    decoration: InputDecoration(
                      labelText: appLocalizations.shiftSupervisor,
                      border: const OutlineInputBorder(),
                    ),
                    items: snapshot.data!
                        .map((u) => DropdownMenuItem(value: u, child: Text(u.name, textDirection: TextDirection.rtl)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedSupervisor = val),
                    validator: (value) => value == null ? appLocalizations.fieldRequired : null,
                  );
                },
              ),
              SizedBox(height: 16),
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