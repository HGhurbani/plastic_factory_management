// plastic_factory_management/lib/presentation/sales/sales_orders_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'package:plastic_factory_management/domain/usecases/sales_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/user_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/production_order_usecases.dart';
import 'package:intl/intl.dart' as intl;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'create_sales_order_screen.dart';
import '../../theme/app_colors.dart';

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
    final productionUseCases = Provider.of<ProductionOrderUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(appLocalizations.salesOrders)),
        body: Center(child: Text('لا يمكن عرض الطلبات بدون بيانات المستخدم.')),
      );
    }

    final bool isSalesRepresentative = currentUser.userRoleEnum == UserRole.salesRepresentative;
    final bool isManager = currentUser.userRoleEnum == UserRole.factoryManager ||
        currentUser.userRoleEnum == UserRole.productionManager ||
        currentUser.userRoleEnum == UserRole.accountant;
    final bool isAccountant = currentUser.userRoleEnum == UserRole.accountant;

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
                  _buildFilterChip(appLocalizations.pendingApproval, SalesOrderStatus.pendingApproval.toFirestoreString(), _selectedStatusFilter, (value) {
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
                  _buildFilterChip(appLocalizations.rejected, SalesOrderStatus.rejected.toFirestoreString(), _selectedStatusFilter, (value) {
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
                        trailing: _buildTrailingActions(context, order, currentUser, salesUseCases, productionUseCases, appLocalizations, isManager, isAccountant),
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

  Widget _buildTrailingActions(
      BuildContext context,
      SalesOrderModel order,
      UserModel currentUser,
      SalesUseCases useCases,
      ProductionOrderUseCases productionUseCases,
      AppLocalizations appLocalizations,
      bool isManager,
      bool isAccountant) {
    if (isAccountant && order.status == SalesOrderStatus.pendingApproval) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => _showApproveDialog(context, useCases, appLocalizations, order),
            tooltip: appLocalizations.approve,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _showRejectDialog(context, useCases, appLocalizations, order),
            tooltip: appLocalizations.reject,
          ),
        ],
      );
    }
    if (isAccountant && order.status == SalesOrderStatus.pendingFulfillment) {
      return IconButton(
        icon: const Icon(Icons.local_shipping, color: Colors.blue),
        onPressed: () => _showInitiateSupplyDialog(
            context, useCases, appLocalizations, order, currentUser),
        tooltip: appLocalizations.initiateSupply,
      );
    }
    if (currentUser.userRoleEnum == UserRole.inventoryManager && order.status == SalesOrderStatus.warehouseProcessing) {
      return IconButton(
        icon: const Icon(Icons.camera_alt, color: Colors.orange),
        onPressed: () => _showWarehouseDocDialog(context, useCases, appLocalizations, order, currentUser),
        tooltip: appLocalizations.warehouseDocumentation,
      );
    }
    if ((currentUser.userRoleEnum == UserRole.productionManager ||
            currentUser.userRoleEnum == UserRole.productionOrderPreparer) &&
        order.status == SalesOrderStatus.pendingProductionApproval) {
      return IconButton(
        icon: const Icon(Icons.check_circle, color: Colors.green),
        onPressed: () => _showProductionApprovalDialog(
            context, useCases, appLocalizations, order, currentUser),
        tooltip: appLocalizations.approveSupply,
      );
    }
    if (isManager && order.status == SalesOrderStatus.pendingFulfillment) {
      return IconButton(
        icon: const Icon(Icons.check_circle, color: Colors.green),
        onPressed: () {
          _showFulfillOrderDialog(context, useCases, appLocalizations, order.id, order.customerName);
        },
        tooltip: appLocalizations.markAsFulfilled,
      );
    }
    if (currentUser.userRoleEnum == UserRole.moldInstallationSupervisor) {
      if (!order.moldTasksEnabled) {
        return IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          onPressed: () => _showMoldApprovalDialog(
              context, useCases, productionUseCases, appLocalizations, order, currentUser),
          tooltip: appLocalizations.approve,
        );
      } else {
        return IconButton(
          icon: const Icon(Icons.camera_alt, color: AppColors.dark),
          onPressed: () => _showMoldDocDialog(context, useCases, appLocalizations, order),
          tooltip: appLocalizations.moldInstallationDocumentation,
        );
      }
    }
    return const SizedBox.shrink();
  }

  Color _getSalesOrderStatusColor(SalesOrderStatus status) {
    switch (status) {
      case SalesOrderStatus.pendingApproval:
        return AppColors.dark;
      case SalesOrderStatus.pendingFulfillment:
        return Colors.orange;
      case SalesOrderStatus.warehouseProcessing:
        return Colors.blue;
      case SalesOrderStatus.pendingProductionApproval:
        return Colors.deepPurple;
      case SalesOrderStatus.fulfilled:
        return Colors.green;
      case SalesOrderStatus.canceled:
        return Colors.red;
      case SalesOrderStatus.rejected:
        return Colors.redAccent;
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
                const SizedBox(height: 16),
                Text(appLocalizations.orderFlowDetails, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
                if (order.approvedAt != null)
                  _buildDetailRow(appLocalizations.approvalTime, intl.DateFormat('yyyy-MM-dd HH:mm').format(order.approvedAt!.toDate())),
                if (order.warehouseManagerName != null)
                  _buildDetailRow(appLocalizations.warehouseDocumentation, order.warehouseManagerName!),
                if (order.warehouseNotes != null && order.warehouseNotes!.isNotEmpty)
                  _buildDetailRow(appLocalizations.warehouseNotes, order.warehouseNotes!),
                if (order.warehouseImages.isNotEmpty)
                  Wrap(
                    children: order.warehouseImages.map((e) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.network(e, width: 60, height: 60, fit: BoxFit.cover),
                    )).toList(),
                  ),
                if (order.moldInstallationNotes != null && order.moldInstallationNotes!.isNotEmpty)
                  _buildDetailRow(appLocalizations.moldInstallationNotes, order.moldInstallationNotes!),
                if (order.moldInstallationImages.isNotEmpty)
                  Wrap(
                    children: order.moldInstallationImages.map((e) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.network(e, width: 60, height: 60, fit: BoxFit.cover),
                    )).toList(),
                  ),
                if (order.productionManagerName != null)
                  _buildDetailRow(appLocalizations.productionManager, order.productionManagerName!),
                if (order.productionRejectionReason != null)
                  _buildDetailRow(appLocalizations.rejectionReason, order.productionRejectionReason!),
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

  void _showApproveDialog(BuildContext context, SalesUseCases useCases,
      AppLocalizations appLocalizations, SalesOrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.approveOrderConfirmation),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildDetailRow(appLocalizations.customerName, order.customerName),
              _buildDetailRow(
                  appLocalizations.salesRepresentative, order.salesRepresentativeName),
              _buildDetailRow(appLocalizations.totalAmount,
                  '\$${order.totalAmount.toStringAsFixed(2)}'),
              _buildDetailRow(appLocalizations.status, order.status.toArabicString(),
                  textColor: _getSalesOrderStatusColor(order.status), isBold: true),
              _buildDetailRow('تاريخ الطلب',
                  intl.DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt.toDate())),
              const SizedBox(height: 16),
              Text(appLocalizations.orderItems,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.right),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: order.orderItems
                    .map((item) => Text(
                          '${item.productName} - ${item.quantity} ${appLocalizations.quantityUnit} @ \$${item.unitPrice.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ))
                    .toList(),
              ),
              if (order.customerSignatureUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(appLocalizations.customerSignature,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.right),
                      const SizedBox(height: 8),
                      Image.network(
                        order.customerSignatureUrl!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              if (order.warehouseNotes != null && order.warehouseNotes!.isNotEmpty)
                _buildDetailRow(
                    appLocalizations.warehouseNotes, order.warehouseNotes!),
              if (order.warehouseImages.isNotEmpty)
                Wrap(
                  children: order.warehouseImages
                      .map((e) => Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.network(e,
                                width: 60, height: 60, fit: BoxFit.cover),
                          ))
                      .toList(),
                ),
              if (order.moldInstallationNotes != null &&
                  order.moldInstallationNotes!.isNotEmpty)
                _buildDetailRow(appLocalizations.moldInstallationNotes,
                    order.moldInstallationNotes!),
              if (order.moldInstallationImages.isNotEmpty)
                Wrap(
                  children: order.moldInstallationImages
                      .map((e) => Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.network(e,
                                width: 60, height: 60, fit: BoxFit.cover),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 16),
              Text('${appLocalizations.confirmApproveOrder}: "${order.customerName}"؟',
                  textAlign: TextAlign.right),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(appLocalizations.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text(appLocalizations.approve),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final user = Provider.of<UserModel?>(context, listen: false)!;
                await useCases.approveSalesOrder(order, user);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(appLocalizations.orderApprovedSuccessfully)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${appLocalizations.errorApprovingOrder}: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, SalesUseCases useCases, AppLocalizations appLocalizations, SalesOrderModel order) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.rejectOrderConfirmation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${appLocalizations.confirmRejectOrder}: "${order.customerName}"؟'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(labelText: appLocalizations.rejectionReason),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(appLocalizations.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text(appLocalizations.reject),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.of(context).pop();
              try {
                final user = Provider.of<UserModel?>(context, listen: false)!;
                await useCases.rejectSalesOrder(order, user, reasonController.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(appLocalizations.orderRejectedSuccessfully)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${appLocalizations.errorRejectingOrder}: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showInitiateSupplyDialog(BuildContext context, SalesUseCases salesUseCases, AppLocalizations appLocalizations, SalesOrderModel order, UserModel accountant) async {
    final userUseCases = Provider.of<UserUseCases>(context, listen: false);
    final storekeepers = await userUseCases.getUsersByRole(UserRole.inventoryManager);
    if (storekeepers.isEmpty) return;
    UserModel selected = storekeepers.first;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('اختر أمين المخزن'),
          content: DropdownButton<UserModel>(
            value: selected,
            items: storekeepers
                .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                .toList(),
            onChanged: (u) => setState(() {
              if (u != null) selected = u;
            }),
          ),
          actions: [
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(appLocalizations.initiateSupply),
              onPressed: () async {
                Navigator.of(context).pop();
                await salesUseCases.initiateSupply(order, accountant, selected);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(appLocalizations.initiateSupply)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoldApprovalDialog(BuildContext context, SalesUseCases useCases, ProductionOrderUseCases productionUseCases,
      AppLocalizations appLocalizations, SalesOrderModel order, UserModel supervisor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appLocalizations.approveOrderConfirmation),
        content: Text('${appLocalizations.confirmApproveOrder}: "${order.customerName}"؟', textAlign: TextAlign.right),
        actions: [
          TextButton(
            child: Text(appLocalizations.cancel),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: Text(appLocalizations.approve),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await useCases.approveMoldTasks(order, supervisor);
                await productionUseCases.createProductionOrdersFromSalesOrder(order, supervisor);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(appLocalizations.orderApprovedSuccessfully)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${appLocalizations.errorApprovingOrder}: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showMoldDocDialog(BuildContext context, SalesUseCases useCases, AppLocalizations appLocalizations, SalesOrderModel order) {
    final TextEditingController notesController = TextEditingController(text: order.moldInstallationNotes);
    List<XFile> pickedImages = [];
    final ImagePicker picker = ImagePicker();

    Future<void> pickImages() async {
      final images = await picker.pickMultiImage();
      if (images != null) {
        pickedImages.addAll(images);
      }
    }

    Future<void> captureImage() async {
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        pickedImages.add(image);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(appLocalizations.moldInstallationDocumentation),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(labelText: appLocalizations.enterNotes),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await captureImage();
                        setState(() {});
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: Text(appLocalizations.camera),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await pickImages();
                        setState(() {});
                      },
                      icon: const Icon(Icons.photo),
                      label: Text(appLocalizations.gallery),
                    ),
                  ],
                ),
                Wrap(
                  children: pickedImages.map((e) => Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.file(File(e.path), width: 60, height: 60, fit: BoxFit.cover),
                  )).toList(),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(appLocalizations.save),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await useCases.addMoldInstallationDocs(
                    order: order,
                    notes: notesController.text.trim(),
                    attachments: pickedImages.map((e) => File(e.path)).toList(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLocalizations.documentationSaved)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorSavingDocumentation}: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWarehouseDocDialog(BuildContext context, SalesUseCases useCases, AppLocalizations appLocalizations, SalesOrderModel order, UserModel storekeeper) {
    final TextEditingController notesController = TextEditingController(text: order.warehouseNotes);
    List<XFile> pickedImages = [];
    final ImagePicker picker = ImagePicker();

    Future<void> pickImages() async {
      final images = await picker.pickMultiImage();
      if (images != null) {
        pickedImages.addAll(images);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(appLocalizations.warehouseDocumentation),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(labelText: appLocalizations.enterNotes),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        // await captureImage();
                        setState(() {});
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: Text(appLocalizations.camera),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await pickImages();
                        setState(() {});
                      },
                      icon: const Icon(Icons.photo),
                      label: Text(appLocalizations.gallery),
                    ),
                  ],
                ),
                Wrap(
                  children: pickedImages.map((e) => Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.file(File(e.path), width: 60, height: 60, fit: BoxFit.cover),
                  )).toList(),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(appLocalizations.sendToProduction),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await useCases.documentWarehouseSupply(
                    order: order,
                    storekeeper: storekeeper,
                    notes: notesController.text.trim(),
                    attachments: pickedImages.map((e) => File(e.path)).toList(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLocalizations.supplySaved)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorSavingSupply}: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProductionApprovalDialog(BuildContext context, SalesUseCases useCases,
      AppLocalizations appLocalizations, SalesOrderModel order, UserModel approver) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appLocalizations.approveSupply),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (order.warehouseNotes != null && order.warehouseNotes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('${appLocalizations.warehouseNotes}: ${order.warehouseNotes!}', textDirection: TextDirection.rtl),
                ),
              if (order.warehouseImages.isNotEmpty)
                Wrap(
                  children: order.warehouseImages
                      .map((img) => Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.network(img, width: 60, height: 60, fit: BoxFit.cover),
                          ))
                      .toList(),
                ),
              if (order.moldInstallationNotes != null && order.moldInstallationNotes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Text('${appLocalizations.moldInstallationNotes}: ${order.moldInstallationNotes!}', textDirection: TextDirection.rtl),
                ),
              if (order.moldInstallationImages.isNotEmpty)
                Wrap(
                  children: order.moldInstallationImages
                      .map((img) => Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.network(img, width: 60, height: 60, fit: BoxFit.cover),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(appLocalizations.cancel),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: Text(appLocalizations.approve),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await useCases.approveSupply(order, approver);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(appLocalizations.approveSupply)),
              );
            },
          ),
        ],
      ),
    );
  }
}
