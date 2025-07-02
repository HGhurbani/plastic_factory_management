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
        backgroundColor: AppColors.primary, // Apply primary color
        foregroundColor: Colors.white, // White text for AppBar title
        elevation: 0, // No shadow for a cleaner look
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1_outlined, color: Colors.white), // Specific icon, white color
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
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
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
                      'خطأ في تحميل بيانات العملاء: ${snapshot.error}', // Original error message for technical details
                      style: const TextStyle(fontSize: 18, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${appLocalizations.technicalDetails}: ${snapshot.error}', // Reused localization
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, color: Colors.grey[400], size: 80), // Specific icon
                    const SizedBox(height: 16),
                    Text(
                      'لا يوجد عملاء لعرضهم. يرجى إضافة عميل جديد.', // Default message for no data
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.tapToAddFirstUser, // Reused localization for adding first item
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddEditCustomerDialog(context, salesUseCases, appLocalizations);
                      },
                      icon: const Icon(Icons.add, color: Colors.white,),
                      label: Text(appLocalizations.addCustomer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemBuilder: (context, index) {
              final customer = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4, // Increased elevation for prominence
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
                child: InkWell( // Added InkWell for tap feedback
                  onTap: () {
                    // Optionally, show a detailed view of the customer
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0), // Inner padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end, // Align all content to the right
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Customer Name with icon
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Icon(Icons.person_outline, color: AppColors.primary, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  customer.name,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 16), // Separator
                        _buildInfoRow(appLocalizations.contactPerson, customer.contactPerson, icon: Icons.contact_mail_outlined),
                        _buildInfoRow(appLocalizations.phone, customer.phone, icon: Icons.phone_outlined),
                        if (customer.email != null && customer.email!.isNotEmpty)
                          _buildInfoRow(appLocalizations.email, customer.email!, icon: Icons.email_outlined),
                        if (customer.address != null && customer.address!.isNotEmpty)
                          _buildInfoRow(appLocalizations.address, customer.address!, icon: Icons.location_on_outlined),
                        _buildInfoRow(
                          'تاريخ التسجيل',
                          intl.DateFormat('yyyy-MM-dd').format(customer.createdAt.toDate()),
                          icon: Icons.calendar_today_outlined,
                          textColor: Colors.grey[700],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomLeft, // Align actions to bottom left for RTL
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 22, color: AppColors.secondary),
                                onPressed: () {
                                  _showAddEditCustomerDialog(context, salesUseCases, appLocalizations, customer: customer);
                                },
                                tooltip: appLocalizations.edit,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 22, color: Colors.redAccent),
                                onPressed: () {
                                  _showDeleteConfirmationDialog(context, salesUseCases, appLocalizations, customer.id, customer.name);
                                },
                                tooltip: appLocalizations.delete,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditCustomerDialog(context, salesUseCases, appLocalizations);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: appLocalizations.addCustomer,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor, bool isBold = false, IconData? icon}) {
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
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: textColor ?? Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.left,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
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
    final _creditLimitController =
        TextEditingController(text: customer?.creditLimit.toString());
    final _currentDebtController =
        TextEditingController(text: customer?.currentDebt.toString());

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? appLocalizations.editCustomer : appLocalizations.addCustomer,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.customerName,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.person_outline),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _contactPersonController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.contactPerson,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.contact_mail_outlined),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.phone,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.phone_outlined),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.email,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.email_outlined),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.address,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    maxLines: 3,
                    textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _creditLimitController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.creditLimit,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.credit_score_outlined),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return appLocalizations.fieldRequired;
                      final n = double.tryParse(value);
                      if (n == null) return appLocalizations.invalidNumber;
                      return null;
                    },
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _currentDebtController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.currentDebt,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return appLocalizations.fieldRequired;
                      final n = double.tryParse(value);
                      if (n == null) return appLocalizations.invalidNumber;
                      return null;
                    },
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: AppColors.dark),
            ),
            ElevatedButton.icon(
              icon: Icon(isEditing ? Icons.save : Icons.add, color: Colors.white),
              label: Text(isEditing ? appLocalizations.save : appLocalizations.add, style: TextStyle(color: Colors.white)),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext loadingContext) {
                      return Center(child: CircularProgressIndicator(color: AppColors.primary));
                    },
                  );
                  try {
                    if (isEditing) {
                      await useCases.updateCustomer(
                        id: customer!.id,
                        name: _nameController.text,
                        contactPerson: _contactPersonController.text,
                        phone: _phoneController.text,
                        email: _emailController.text.isEmpty ? null : _emailController.text,
                        address: _addressController.text.isEmpty ? null : _addressController.text,
                        creditLimit: double.parse(_creditLimitController.text),
                        currentDebt: double.parse(_currentDebtController.text),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.customerUpdatedSuccessfully)));
                    } else {
                      await useCases.addCustomer(
                        name: _nameController.text,
                        contactPerson: _contactPersonController.text,
                        phone: _phoneController.text,
                        email: _emailController.text.isEmpty ? null : _emailController.text,
                        address: _addressController.text.isEmpty ? null : _addressController.text,
                        creditLimit: double.parse(_creditLimitController.text),
                        currentDebt: double.parse(_currentDebtController.text),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.customerAddedSuccessfully)));
                    }
                    Navigator.of(context).pop(); // Pop the loading indicator
                    Navigator.of(dialogContext).pop();
                  } catch (e) {
                    Navigator.of(context).pop(); // Pop the loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorSavingCustomer}: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.confirmDeletion, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(
            '${appLocalizations.confirmDeleteCustomer}: "$customerName"؟\n\n${appLocalizations.thisActionCannotBeUndone}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: AppColors.dark),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: Text(appLocalizations.delete, style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Pop confirmation dialog
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return Center(child: CircularProgressIndicator(color: AppColors.primary));
                  },
                );
                try {
                  await useCases.deleteCustomer(customerId);
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.customerDeletedSuccessfully)));
                } catch (e) {
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorDeletingCustomer}: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}