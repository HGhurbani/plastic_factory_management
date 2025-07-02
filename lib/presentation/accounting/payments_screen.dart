import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/customer_model.dart';
import 'package:plastic_factory_management/data/models/payment_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/financial_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/sales_usecases.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  CustomerModel? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final financialUseCases = Provider.of<FinancialUseCases>(context);
    final salesUseCases = Provider.of<SalesUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.paymentsManagement),
      ),
      floatingActionButton: _selectedCustomer != null && currentUser != null
          ? FloatingActionButton(
              onPressed: () => _showAddPaymentDialog(
                  context, financialUseCases, currentUser, _selectedCustomer!, appLocalizations),
              child: const Icon(Icons.add),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder<List<CustomerModel>>(
              stream: salesUseCases.getCustomers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final customers = snapshot.data!;
                return DropdownButton<CustomerModel>(
                  hint: Text(appLocalizations.selectCustomer),
                  value: _selectedCustomer,
                  isExpanded: true,
                  onChanged: (c) => setState(() => _selectedCustomer = c),
                  items: customers
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name, textDirection: TextDirection.rtl),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedCustomer == null
                  ? Center(child: Text(appLocalizations.selectCustomer))
                  : StreamBuilder<List<PaymentModel>>(
                      stream: financialUseCases
                          .getPaymentsForCustomer(_selectedCustomer!.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final payments = snapshot.data ?? [];
                        if (payments.isEmpty) {
                          return Center(child: Text(appLocalizations.noData));
                        }
                        return ListView.builder(
                          itemCount: payments.length,
                          itemBuilder: (context, index) {
                            final p = payments[index];
                            return ListTile(
                              title: Text(intl.DateFormat.yMd().format(p.paymentDate.toDate()),
                                  textDirection: TextDirection.rtl),
                              subtitle: Text('${p.amount} - ${p.method}',
                                  textDirection: TextDirection.rtl),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentDialog(
      BuildContext context,
      FinancialUseCases useCases,
      UserModel currentUser,
      CustomerModel customer,
      AppLocalizations appLocalizations) {
    final _formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final methodController = TextEditingController(text: 'cash');
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(appLocalizations.recordPayment, textAlign: TextAlign.center),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: appLocalizations.amount),
                    validator: (v) => v == null || v.isEmpty ? appLocalizations.fieldRequired : null,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: methodController,
                    decoration: InputDecoration(labelText: appLocalizations.method),
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
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(labelText: appLocalizations.notes),
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
                  final payment = PaymentModel(
                    id: '',
                    customerId: customer.id,
                    customerName: customer.name,
                    amount: double.tryParse(amountController.text) ?? 0.0,
                    paymentDate: Timestamp.fromDate(selectedDate),
                    method: methodController.text,
                    notes: notesController.text,
                    recordedByUid: currentUser.uid,
                    recordedByName: currentUser.name,
                  );
                  await useCases.recordPayment(payment: payment, customer: customer);
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
