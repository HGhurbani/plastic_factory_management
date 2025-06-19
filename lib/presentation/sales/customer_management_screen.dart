// plastic_factory_management/lib/presentation/sales/customer_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/customer_model.dart';
import 'package:plastic_factory_management/domain/usecases/sales_usecases.dart';
import 'package:intl/intl.dart' as intl;
import 'package:plastic_factory_management/theme/app_colors.dart';

class CustomerManagementScreen extends StatefulWidget {
  @override
  _CustomerManagementScreenState createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final salesUseCases = Provider.of<SalesUseCases>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.customerManagement),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {
              _showAddEditCustomerDialog(context, salesUseCases, appLocalizations);
            },
            tooltip: appLocalizations.registerNewCustomer,
          ),
        ],
      ),
      body: StreamBuilder<List<CustomerModel>>(
        stream: salesUseCases.getCustomers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل بيانات العملاء: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('لا يوجد عملاء لعرضهم. يرجى إضافة عميل جديد.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final customer = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    customer.name,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${appLocalizations.contactPerson}: ${customer.contactPerson}',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        '${appLocalizations.phone}: ${customer.phone}',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                      if (customer.email != null && customer.email!.isNotEmpty)
                        Text(
                          '${appLocalizations.email}: ${customer.email}',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                      if (customer.address != null && customer.address!.isNotEmpty)
                        Text(
                          '${appLocalizations.address}: ${customer.address}',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                      Text(
                        'تاريخ التسجيل: ${intl.DateFormat('yyyy-MM-dd').format(customer.createdAt.toDate())}',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () {
                          _showAddEditCustomerDialog(context, salesUseCases, appLocalizations, customer: customer);
                        },
                        tooltip: appLocalizations.edit,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmationDialog(context, salesUseCases, appLocalizations, customer.id, customer.name);
                        },
                        tooltip: appLocalizations.delete,
                      ),
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

  void _showAddEditCustomerDialog(
      BuildContext context,
      SalesUseCases useCases,
      AppLocalizations appLocalizations, {
        CustomerModel? customer,
      }) {
    final isEditing = customer != null;
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: customer?.name);
    final _contactPersonController = TextEditingController(text: customer?.contactPerson);
    final _phoneController = TextEditingController(text: customer?.phone);
    final _emailController = TextEditingController(text: customer?.email);
    final _addressController = TextEditingController(text: customer?.address);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? appLocalizations.editCustomer : appLocalizations.addCustomer), // أضف هذا النص في ARB
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: appLocalizations.customerName, border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _contactPersonController,
                    decoration: InputDecoration(labelText: appLocalizations.contactPerson, border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: appLocalizations.phone, border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: appLocalizations.email, border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: appLocalizations.address, border: OutlineInputBorder()),
                    maxLines: 3,
                    textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text(isEditing ? appLocalizations.save : appLocalizations.add),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    if (isEditing) {
                      await useCases.updateCustomer(
                        id: customer!.id,
                        name: _nameController.text,
                        contactPerson: _contactPersonController.text,
                        phone: _phoneController.text,
                        email: _emailController.text.isEmpty ? null : _emailController.text,
                        address: _addressController.text.isEmpty ? null : _addressController.text,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.customerUpdatedSuccessfully))); // أضف هذا النص في ARB
                    } else {
                      await useCases.addCustomer(
                        name: _nameController.text,
                        contactPerson: _contactPersonController.text,
                        phone: _phoneController.text,
                        email: _emailController.text.isEmpty ? null : _emailController.text,
                        address: _addressController.text.isEmpty ? null : _addressController.text,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.customerAddedSuccessfully))); // أضف هذا النص في ARB
                    }
                    Navigator.of(dialogContext).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorSavingCustomer}: $e'))); // أضف هذا النص في ARB
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context,
      SalesUseCases useCases,
      AppLocalizations appLocalizations,
      String customerId,
      String customerName,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.confirmDeletion),
          content: Text('${appLocalizations.confirmDeleteCustomer}: "$customerName"؟'), // أضف هذا النص في ARB
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text(appLocalizations.delete),
              onPressed: () async {
                try {
                  await useCases.deleteCustomer(customerId);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.customerDeletedSuccessfully))); // أضف هذا النص في ARB
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorDeletingCustomer}: $e'))); // أضف هذا النص في ARB
                }
              },
            ),
          ],
        );
      },
    );
  }
}