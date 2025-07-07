import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/purchase_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/financial_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/spare_part_model.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';
import 'package:plastic_factory_management/core/extensions/string_extensions.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final financialUseCases = Provider.of<FinancialUseCases>(context);
    final inventoryUseCases = Provider.of<InventoryUseCases>(context, listen: false);
    final currentUser = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.purchasesManagement),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddPurchaseDialog(
                  context,
                  financialUseCases,
                  inventoryUseCases,
                  currentUser,
                  appLocalizations),
              tooltip: appLocalizations.addPurchase,
            ),
        ],
      ),
      floatingActionButton: currentUser != null
          ? FloatingActionButton(
              onPressed: () => _showAddPurchaseDialog(
                  context,
                  financialUseCases,
                  inventoryUseCases,
                  currentUser,
                  appLocalizations),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              tooltip: appLocalizations.addPurchase,
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<List<PurchaseModel>>(
        stream: financialUseCases.getPurchases(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      appLocalizations.somethingWentWrong,
                      style: const TextStyle(fontSize: 18, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${appLocalizations.technicalDetails}: ${snapshot.error}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final purchases = snapshot.data ?? [];
          if (purchases.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        color: Colors.grey[400], size: 80),
                    const SizedBox(height: 16),
                    Text(
                      appLocalizations.noData,
                      style:
                          TextStyle(fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final p = purchases[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              const Icon(Icons.shopping_cart_outlined,
                                  color: AppColors.primary, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                p.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            intl.DateFormat('yyyy-MM-dd')
                                .format(p.purchaseDate.toDate()),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildInfoRow(appLocalizations.category, p.category,
                          icon: Icons.category_outlined),
                      _buildInfoRow(appLocalizations.amount,
                          '﷼${p.amount.toStringAsFixed(2)}',
                          icon: Icons.currency_exchange, isBold: true),
                      if (p.maintenanceLogId != null &&
                          p.maintenanceLogId!.isNotEmpty)
                        _buildInfoRow(
                            appLocalizations.linkedMaintenanceLog,
                            '#${p.maintenanceLogId!.shortId()}',
                            icon: Icons.build_outlined),
                      if (p.productionOrderId != null &&
                          p.productionOrderId!.isNotEmpty)
                        _buildInfoRow(
                            appLocalizations.linkedProductionOrder,
                            '#${p.productionOrderId!.shortId()}',
                            icon: Icons.work_outline),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddPurchaseDialog(
      BuildContext context,
      FinancialUseCases useCases,
      InventoryUseCases inventoryUseCases,
      UserModel currentUser,
      AppLocalizations appLocalizations) {
    final formKey = GlobalKey<FormState>();
    final descController = TextEditingController();
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final maintenanceController = TextEditingController();
    final productionController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    InventoryItemType? selectedType;
    dynamic selectedItem;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(appLocalizations.addPurchase, textAlign: TextAlign.center),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.description,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      validator: (v) => v == null || v.isEmpty ? appLocalizations.fieldRequired : null,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: categoryController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.category,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: appLocalizations.amount,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.currency_exchange),
                      ),
                      validator: (v) => v == null || v.isEmpty ? appLocalizations.fieldRequired : null,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: intl.DateFormat.yMd().format(selectedDate)),
                      decoration: InputDecoration(
                        labelText: appLocalizations.paymentDate,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                          // Rebuild to show the selected date
                          (context as Element).markNeedsBuild();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: maintenanceController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.linkedMaintenanceLog,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.build_outlined),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: productionController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.linkedProductionOrder,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.work_outline),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<InventoryItemType>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: appLocalizations.selectInventoryType,
                        border: const OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: InventoryItemType.rawMaterial,
                          child: Text('المادة الأولية',
                              textDirection: TextDirection.rtl),
                        ),
                        DropdownMenuItem(
                          value: InventoryItemType.finishedProduct,
                          child: Text('الإنتاج التام',
                              textDirection: TextDirection.rtl),
                        ),
                        DropdownMenuItem(
                          value: InventoryItemType.sparePart,
                          child: Text('قطع الغيار',
                              textDirection: TextDirection.rtl),
                        ),
                      ],
                      onChanged: (val) {
                        selectedType = val;
                        selectedItem = null;
                        (context as Element).markNeedsBuild();
                      },
                    ),
                    const SizedBox(height: 12),
                    if (selectedType != null)
                      StreamBuilder<List<dynamic>>(
                        stream:
                            _itemsStream(inventoryUseCases, selectedType!),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final items = snapshot.data!;
                          return DropdownButtonFormField<dynamic>(
                            value: selectedItem,
                            decoration: InputDecoration(
                              labelText: appLocalizations.selectItem,
                              border: const OutlineInputBorder(),
                            ),
                            items: items
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(_getName(e),
                                        textDirection: TextDirection.rtl),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              selectedItem = val;
                              (context as Element).markNeedsBuild();
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: qtyController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.quantity,
                        border: const OutlineInputBorder(),
                        prefixIcon:
                            const Icon(Icons.confirmation_num_outlined),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(appLocalizations.cancel),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.white),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final purchase = PurchaseModel(
                      id: '',
                      description: descController.text,
                      category: categoryController.text,
                      amount: double.tryParse(amountController.text) ?? 0.0,
                      purchaseDate: Timestamp.fromDate(selectedDate),
                      maintenanceLogId:
                          maintenanceController.text.isEmpty ? null : maintenanceController.text,
                      productionOrderId:
                          productionController.text.isEmpty ? null : productionController.text,
                      createdByUid: currentUser.uid,
                      createdByName: currentUser.name,
                      itemId: selectedItem != null ? _getId(selectedItem) : null,
                      itemName:
                          selectedItem != null ? _getName(selectedItem) : null,
                      itemType: selectedType,
                      quantity: double.tryParse(qtyController.text),
                    );
                    await useCases.recordPurchase(purchase);
                    if (selectedType != null && selectedItem != null) {
                      await inventoryUseCases.adjustInventoryWithNotification(
                        itemId: _getId(selectedItem),
                        itemName: _getName(selectedItem),
                        type: selectedType!,
                        delta: double.tryParse(qtyController.text) ?? 0.0,
                      );
                    }
                    Navigator.pop(context);
                  }
                },
                label: Text(appLocalizations.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.7)),
            const SizedBox(width: 8),
          ],
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<dynamic>> _itemsStream(
      InventoryUseCases useCases, InventoryItemType type) {
    switch (type) {
      case InventoryItemType.rawMaterial:
        return useCases.getRawMaterials();
      case InventoryItemType.finishedProduct:
        return useCases.getProducts();
      case InventoryItemType.sparePart:
        return useCases.getSpareParts();
    }
  }

  String _getName(dynamic item) {
    if (item is RawMaterialModel) return '${item.code} - ${item.name}';
    if (item is ProductModel) return '${item.productCode} - ${item.name}';
    if (item is SparePartModel) return '${item.code} - ${item.name}';
    return '';
  }

  String _getId(dynamic item) {
    if (item is RawMaterialModel) return item.id;
    if (item is ProductModel) return item.id;
    if (item is SparePartModel) return item.id;
    return '';
  }
}
