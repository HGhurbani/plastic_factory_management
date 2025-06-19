// plastic_factory_management/lib/presentation/production/production_orders_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/production_order_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'package:plastic_factory_management/domain/usecases/production_order_usecases.dart';
import 'package:intl/intl.dart' as intl;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'create_production_order_screen.dart'; // تأكد من الاستيراد
import 'production_order_detail_screen.dart'; // تأكد من الاستيراد

// شاشة عرض طلبات الإنتاج
class ProductionOrdersListScreen extends StatefulWidget {
  @override
  _ProductionOrdersListScreenState createState() => _ProductionOrdersListScreenState();
}

class _ProductionOrdersListScreenState extends State<ProductionOrdersListScreen> {
  String _selectedStatusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final productionUseCases = Provider.of<ProductionOrderUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(appLocalizations.productionOrderManagement)),
        body: Center(child: Text('لا يمكن عرض الطلبات بدون بيانات المستخدم.')),
      );
    }

    final bool isManager = currentUser.userRoleEnum == UserRole.factoryManager ||
        currentUser.userRoleEnum == UserRole.productionManager;
    final bool isPreparer = currentUser.userRoleEnum == UserRole.productionOrderPreparer;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.productionOrderManagement),
        centerTitle: true,
        actions: [
          if (isPreparer)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateProductionOrderScreen()));
              },
              tooltip: appLocalizations.createOrder,
            ),
        ],
      ),
      body: Column(
        children: [
          if (isManager)
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
                    _buildFilterChip(appLocalizations.pending, ProductionOrderStatus.pending.toFirestoreString(), _selectedStatusFilter, (value) {
                      setState(() {
                        _selectedStatusFilter = value;
                      });
                    }),
                    _buildFilterChip(appLocalizations.approved, ProductionOrderStatus.approved.toFirestoreString(), _selectedStatusFilter, (value) {
                      setState(() {
                        _selectedStatusFilter = value;
                      });
                    }),
                    _buildFilterChip(appLocalizations.inProduction, ProductionOrderStatus.inProduction.toFirestoreString(), _selectedStatusFilter, (value) {
                      setState(() {
                        _selectedStatusFilter = value;
                      });
                    }),
                    _buildFilterChip(appLocalizations.completed, ProductionOrderStatus.completed.toFirestoreString(), _selectedStatusFilter, (value) {
                      setState(() {
                        _selectedStatusFilter = value;
                      });
                    }),
                    _buildFilterChip(appLocalizations.reject, ProductionOrderStatus.rejected.toFirestoreString(), _selectedStatusFilter, (value) {
                      setState(() {
                        _selectedStatusFilter = value;
                      });
                    }),
                    _buildFilterChip(appLocalizations.canceled, ProductionOrderStatus.canceled.toFirestoreString(), _selectedStatusFilter, (value) {
                      setState(() {
                        _selectedStatusFilter = value;
                      });
                    }),
                  ],
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ProductionOrderModel>>(
              stream: _selectedStatusFilter == 'all'
                  ? productionUseCases.getProductionOrders()
                  : productionUseCases.getProductionOrders().map((orders) {
                return orders.where((order) => order.status.toFirestoreString() == _selectedStatusFilter).toList();
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ في تحميل طلبات الإنتاج: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('لا توجد طلبات إنتاج لعرضها.'));
                }

                final List<ProductionOrderModel> filteredOrders = isPreparer
                    ? snapshot.data!.where((order) => order.orderPreparerUid == currentUser.uid).toList()
                    : snapshot.data!;

                if (filteredOrders.isEmpty) {
                  return Center(child: Text('لا توجد طلبات إنتاج بهذا الفلتر.'));
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
                          // Navigate to order details screen
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ProductionOrderDetailScreen(order: order),
                          ));
                        },
                        title: Text(
                          '${appLocalizations.product}: ${order.productName}',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${appLocalizations.requiredQuantity}: ${order.requiredQuantity}',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                            Text(
                              '${appLocalizations.batchNumber}: ${order.batchNumber}',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                            Text(
                              '${appLocalizations.orderPreparer}: ${order.orderPreparerName}',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                            Text(
                              '${appLocalizations.status}: ${order.status.toArabicString()}',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: _getStatusColor(order.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'تاريخ الإنشاء: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt.toDate())}',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: (isManager && order.status == ProductionOrderStatus.pending)
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _showApproveDialog(context, order, currentUser, appLocalizations),
                              tooltip: appLocalizations.approve,
                            ),
                            IconButton(
                              icon: Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _showRejectDialog(context, order, currentUser, appLocalizations),
                              tooltip: appLocalizations.reject,
                            ),
                          ],
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

  Color _getStatusColor(ProductionOrderStatus status) {
    switch (status) {
      case ProductionOrderStatus.pending:
        return Colors.orange;
      case ProductionOrderStatus.approved:
        return Colors.blue;
      case ProductionOrderStatus.inProduction:
        return Colors.purple;
      case ProductionOrderStatus.completed:
        return Colors.green;
      case ProductionOrderStatus.canceled:
      case ProductionOrderStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showApproveDialog(BuildContext context, ProductionOrderModel order, UserModel approver, AppLocalizations appLocalizations) {
    final TextEditingController notesController = TextEditingController();
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
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(appLocalizations.approveOrderConfirmation),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${appLocalizations.confirmApproveOrder} "${order.productName}"؟'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(labelText: appLocalizations.addNotes),
                    maxLines: 3,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final img = await picker.pickImage(source: ImageSource.camera);
                          if (img != null) setState(() => pickedImages.add(img));
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: Text(appLocalizations.camera),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await pickImages();
                          setState(() {});
                        },
                        icon: const Icon(Icons.photo_library),
                        label: Text(appLocalizations.gallery),
                      ),
                    ],
                  ),
                  if (pickedImages.isNotEmpty)
                    Wrap(
                      children: pickedImages
                          .map((e) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.file(
                                  File(e.path),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(appLocalizations.cancel),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              ElevatedButton(
                child: Text(appLocalizations.approve),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  try {
                    await Provider.of<ProductionOrderUseCases>(context, listen: false).approveProductionOrder(
                      order,
                      approver,
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      attachments: pickedImages.map((e) => File(e.path)).toList(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations.orderApprovedSuccessfully)),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${appLocalizations.errorApprovingOrder}: $e')),
                    );
                    print('Error approving order: $e');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, ProductionOrderModel order, UserModel approver, AppLocalizations appLocalizations) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.rejectOrderConfirmation),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${appLocalizations.confirmRejectOrder} "${order.productName}"؟'),
              SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: appLocalizations.rejectionReason,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: Text(appLocalizations.reject),
              onPressed: () async {
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(appLocalizations.rejectionReasonRequired)),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                try {
                  await Provider.of<ProductionOrderUseCases>(context, listen: false).rejectProductionOrder(order, approver, reasonController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLocalizations.orderRejectedSuccessfully)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorRejectingOrder}: $e')),
                  );
                  print('Error rejecting order: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }
}