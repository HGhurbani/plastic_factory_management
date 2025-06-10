// plastic_factory_management/lib/presentation/sales/sales_orders_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'package:plastic_factory_management/domain/usecases/sales_usecases.dart';
import 'package:intl/intl.dart' as intl;

import 'create_sales_order_screen.dart';

class SalesOrdersListScreen extends StatefulWidget {
  @override
  _SalesOrdersListScreenState createState() => _SalesOrdersListScreenState();
}

class _SalesOrdersListScreenState extends State<SalesOrdersListScreen> {
  String _selectedStatusFilter = 'all'; // For filtering orders

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final salesUseCases = Provider.of<SalesUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(appLocalizations.salesOrders)),
        body: Center(child: Text('لا يمكن عرض الطلبات بدون بيانات المستخدم.')),
      );
    }

    final bool isSalesRepresentative = currentUser.userRoleEnum == UserRole.salesRepresentative;
    final bool isManager = currentUser.userRoleEnum == UserRole.factoryManager || currentUser.userRoleEnum == UserRole.productionManager;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.salesOrders),
        centerTitle: true,
        actions: [
          if (isSalesRepresentative)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateSalesOrderScreen()));
              },
              tooltip: appLocalizations.createSalesOrder,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter buttons (visible for managers and sales reps)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFilterChip(appLocalizations.all, 'all', _selectedStatusFilter, (value) {
                    setState(() {
                      _selectedStatusFilter = value;
                    });
                  }),
                  _buildFilterChip(appLocalizations.pendingFulfillment, SalesOrderStatus.pendingFulfillment.toFirestoreString(), _selectedStatusFilter, (value) {
                    setState(() {
                      _selectedStatusFilter = value;
                    });
                  }),
                  _buildFilterChip(appLocalizations.fulfilled, SalesOrderStatus.fulfilled.toFirestoreString(), _selectedStatusFilter, (value) {
                    setState(() {
                      _selectedStatusFilter = value;
                    });
                  }),
                  _buildFilterChip(appLocalizations.canceled, SalesOrderStatus.canceled.toFirestoreString(), _selectedStatusFilter, (value) {
                    setState(() {
                      _selectedStatusFilter = value;
                    });
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SalesOrderModel>>(
              stream: isSalesRepresentative
                  ? salesUseCases.getSalesOrders(salesRepUid: currentUser.uid) // Only show own orders
                  : salesUseCases.getSalesOrders(), // Managers see all orders
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ في تحميل طلبات المبيعات: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('لا توجد طلبات مبيعات لعرضها.'));
                }

                // Apply status filter
                final List<SalesOrderModel> filteredOrders = _selectedStatusFilter == 'all'
                    ? snapshot.data!
                    : snapshot.data!.where((order) => order.status.toFirestoreString() == _selectedStatusFilter).toList();

                if (filteredOrders.isEmpty) {
                  return Center(child: Text('لا توجد طلبات مبيعات بهذا الفلتر.'));
                }

                return ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      child: ListTile(
                        onTap: () {
                          _showSalesOrderDetailDialog(context, appLocalizations, order);
                        },
                        title: Text(
                          'طلب العميل: ${order.customerName}',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${appLocalizations.totalAmount}: \$${order.totalAmount.toStringAsFixed(2)}',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                            Text(
                              '${appLocalizations.salesRepresentative}: ${order.salesRepresentativeName}',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                            Text(
                              '${appLocalizations.status}: ${order.status.toArabicString()}',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: _getSalesOrderStatusColor(order.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'تاريخ الطلب: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt.toDate())}',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: (isManager && order.status == SalesOrderStatus.pendingFulfillment)
                            ? IconButton(
                          icon: Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () {
                            _showFulfillOrderDialog(context, salesUseCases, appLocalizations, order.id, order.customerName);
                          },
                          tooltip: appLocalizations.markAsFulfilled, // أضف هذا النص
                        )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue, Function(String) onSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedValue == value,
        onSelected: (bool selected) {
          if (selected) {
            onSelected(value);
          }
        },
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: selectedValue == value ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: selectedValue == value ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Color _getSalesOrderStatusColor(SalesOrderStatus status) {
    switch (status) {
      case SalesOrderStatus.pendingFulfillment:
        return Colors.orange;
      case SalesOrderStatus.fulfilled:
        return Colors.green;
      case SalesOrderStatus.canceled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showSalesOrderDetailDialog(BuildContext context, AppLocalizations appLocalizations, SalesOrderModel order) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('${appLocalizations.salesOrder}: ${order.id.substring(0, 6)}...', textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildDetailRow(appLocalizations.customerName, order.customerName),
                _buildDetailRow(appLocalizations.salesRepresentative, order.salesRepresentativeName),
                _buildDetailRow(appLocalizations.totalAmount, '\$${order.totalAmount.toStringAsFixed(2)}'),
                _buildDetailRow(appLocalizations.status, order.status.toArabicString(), textColor: _getSalesOrderStatusColor(order.status), isBold: true),
                _buildDetailRow('تاريخ الطلب', intl.DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt.toDate())),
                SizedBox(height: 16),
                Text(appLocalizations.orderItems, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: order.orderItems.map((item) => Text(
                    '${item.productName} - ${item.quantity} ${appLocalizations.quantityUnit} @ \$${item.unitPrice.toStringAsFixed(2)}', // أضف وحدة الكمية
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  )).toList(),
                ),
                if (order.customerSignatureUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(appLocalizations.customerSignature, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
                        SizedBox(height: 8),
                        Image.network(
                          order.customerSignatureUrl!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.close),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  void _showFulfillOrderDialog(BuildContext context, SalesUseCases useCases, AppLocalizations appLocalizations, String orderId, String customerName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.markAsFulfilledConfirmation), // أضف هذا النص
          content: Text('${appLocalizations.confirmFulfillOrder}: "$customerName"؟'), // أضف هذا النص
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text(appLocalizations.fulfill), // أضف هذا النص
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await useCases.updateSalesOrderStatus(orderId, SalesOrderStatus.fulfilled);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLocalizations.orderFulfilledSuccessfully)), // أضف هذا النص
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorFulfillingOrder}: $e')), // أضف هذا النص
                  );
                  print('Error fulfilling order: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }
}