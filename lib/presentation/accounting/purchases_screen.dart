import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/purchase_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/financial_usecases.dart';

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
      ),
      floatingActionButton: currentUser != null
          ? FloatingActionButton(
              onPressed: () =>
                  _showAddPurchaseDialog(context, financialUseCases, currentUser, appLocalizations),
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<List<PurchaseModel>>(
        stream: financialUseCases.getPurchases(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final purchases = snapshot.data ?? [];
          if (purchases.isEmpty) {
            return Center(child: Text(appLocalizations.noData));
          }
          return ListView.builder(
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final p = purchases[index];
              return ListTile(
                title: Text(p.description, textDirection: TextDirection.rtl),
                subtitle: Text(
                  '${intl.DateFormat.yMd().format(p.purchaseDate.toDate())} - ${p.amount}',
                  textDirection: TextDirection.rtl,
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
}
