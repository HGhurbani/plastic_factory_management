import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/purchase_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/financial_usecases.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';
import 'package:plastic_factory_management/core/extensions/string_extensions.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final financialUseCases = Provider.of<FinancialUseCases>(context);
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
                  context, financialUseCases, currentUser, appLocalizations),
              tooltip: appLocalizations.addPurchase,
            ),
        ],
      ),
      floatingActionButton: currentUser != null
          ? FloatingActionButton(
              onPressed: () => _showAddPurchaseDialog(
                  context, financialUseCases, currentUser, appLocalizations),
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

  void _showAddPurchaseDialog(BuildContext context, FinancialUseCases useCases,
      UserModel currentUser, AppLocalizations appLocalizations) {
    final _formKey = GlobalKey<FormState>();
    final descController = TextEditingController();
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final maintenanceController = TextEditingController();
    final productionController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(appLocalizations.addPurchase, textAlign: TextAlign.center),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: descController,
                    decoration: InputDecoration(labelText: appLocalizations.description),
                    validator: (v) => v == null || v.isEmpty ? appLocalizations.fieldRequired : null,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: categoryController,
                    decoration: InputDecoration(labelText: appLocalizations.category),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: appLocalizations.amount),
                    validator: (v) => v == null || v.isEmpty ? appLocalizations.fieldRequired : null,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(intl.DateFormat.yMd().format(selectedDate)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        selectedDate = picked;
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: maintenanceController,
                    decoration:
                        InputDecoration(labelText: appLocalizations.linkedMaintenanceLog),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: productionController,
                    decoration:
                        InputDecoration(labelText: appLocalizations.linkedProductionOrder),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final purchase = PurchaseModel(
                    id: '',
                    description: descController.text,
                    category: categoryController.text,
                    amount: double.tryParse(amountController.text) ?? 0.0,
                    purchaseDate: Timestamp.fromDate(selectedDate),
                    maintenanceLogId: maintenanceController.text.isEmpty ? null : maintenanceController.text,
                    productionOrderId: productionController.text.isEmpty ? null : productionController.text,
                    createdByUid: currentUser.uid,
                    createdByName: currentUser.name,
                  );
                  await useCases.recordPurchase(purchase);
                  Navigator.pop(context);
                }
              },
              child: Text(appLocalizations.save),
            ),
          ],
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
}
