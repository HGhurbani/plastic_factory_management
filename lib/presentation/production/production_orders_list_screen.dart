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

import 'create_production_order_screen.dart';
import 'production_order_detail_screen.dart';
import '../../theme/app_colors.dart'; // Import AppColors

// شاشة عرض طلبات الإنتاج
class ProductionOrdersListScreen extends StatefulWidget {
  @override
  _ProductionOrdersListScreenState createState() => _ProductionOrdersListScreenState();
}

class _ProductionOrdersListScreenState extends State<ProductionOrdersListScreen> {
  String _selectedStatusFilter = 'all';
  ProductionOrderModel? _newlyCreatedOrder;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final productionUseCases = Provider.of<ProductionOrderUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appLocalizations.productionOrderManagement),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  appLocalizations.loginRequiredToViewOrders, // Reusing existing localization
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bool isManager = currentUser.userRoleEnum == UserRole.factoryManager ||
        currentUser.userRoleEnum == UserRole.productionManager;
    final bool isPreparer = currentUser.userRoleEnum == UserRole.operationsOfficer ||
        currentUser.userRoleEnum == UserRole.productionOrderPreparer;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.productionOrderManagement),
        centerTitle: true,
        backgroundColor: AppColors.primary, // Apply primary color
        foregroundColor: Colors.white, // White text for AppBar title
        elevation: 0,
        actions: [
          if (isPreparer)
            IconButton(
              icon: Icon(Icons.add, color: Colors.white), // White icon
              onPressed: () async {
                final newOrder = await Navigator.of(context).push<ProductionOrderModel?>(
                  MaterialPageRoute(builder: (_) => CreateProductionOrderScreen()),
                );
                if (newOrder != null) {
                  setState(() {
                    _newlyCreatedOrder = newOrder;
                    _selectedStatusFilter = 'all';
                  });
                }
              },
              tooltip: appLocalizations.createOrder,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
                  _buildFilterChip(appLocalizations.canceled, ProductionOrderStatus.canceled.toFirestoreString(), _selectedStatusFilter, (value) {
                    setState(() {
                      _selectedStatusFilter = value;
                    });
                  }),
                  _buildFilterChip(appLocalizations.rejected, ProductionOrderStatus.rejected.toFirestoreString(), _selectedStatusFilter, (value) {
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
              stream: productionUseCases.getProductionOrders(),
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
                            'خطأ في تحميل طلبات الإنتاج: ${snapshot.error}', // Original error message
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
                          Icon(Icons.assignment_outlined, color: Colors.grey[400], size: 80), // Specific icon
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد طلبات إنتاج لعرضها.', // Default no data message
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (isPreparer)
                            Text(
                              appLocalizations.tapToAddFirstOrder, // Reused localization
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          if (isPreparer) const SizedBox(height: 24),
                          if (isPreparer)
                            ElevatedButton.icon(
                              onPressed: () async {
                                final newOrder = await Navigator.of(context).push<ProductionOrderModel?>(
                                  MaterialPageRoute(builder: (_) => CreateProductionOrderScreen()),
                                );
                                if (newOrder != null) {
                                  setState(() {
                                    _newlyCreatedOrder = newOrder;
                                    _selectedStatusFilter = 'all';
                                  });
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: Text(appLocalizations.createOrder),
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

                List<ProductionOrderModel> orders = snapshot.data!
                    .where((order) => order.salesOrderId == null || order.salesOrderId!.isEmpty)
                    .toList();

                if (_newlyCreatedOrder != null) {
                  final exists = orders.any((o) => o.id == _newlyCreatedOrder!.id);
                  if (!exists) {
                    orders = [ _newlyCreatedOrder!, ...orders ];
                  }
                  orders = orders.where((o) => o.id == _newlyCreatedOrder!.id).toList();
                }

                List<ProductionOrderModel> filteredOrders = isPreparer
                    ? orders.where((order) => order.orderPreparerUid == currentUser.uid).toList()
                    : orders;

                if (_selectedStatusFilter != 'all') {
                  filteredOrders = filteredOrders
                      .where((order) => order.status.toFirestoreString() == _selectedStatusFilter)
                      .toList();
                }

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_alt_off, color: Colors.grey[400], size: 80),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد طلبات إنتاج بهذا الفلتر.', // Specific message for no results with filter
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            appLocalizations.tryDifferentFilter, // Reused localization
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 1, // Increased elevation for prominence
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
                      child: InkWell( // Added InkWell for tap feedback
                        onTap: () {
                          // Navigate to order details screen
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ProductionOrderDetailScreen(order: order),
                          ));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0), // Inner padding
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Product Name
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      Icon(Icons.category_outlined, color: AppColors.primary, size: 28),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${appLocalizations.product}: ${order.productName}',
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.right,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      order.status.toArabicString(),
                                      style: TextStyle(
                                        color: _getStatusColor(order.status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16), // Separator
                              _buildInfoRow(appLocalizations.requiredQuantity, order.requiredQuantity.toString(), icon: Icons.production_quantity_limits_outlined),
                              _buildInfoRow(appLocalizations.batchNumber, order.batchNumber, icon: Icons.batch_prediction_outlined),
                              if (order.salesOrderId != null && order.salesOrderId!.isNotEmpty)
                                _buildInfoRow(appLocalizations.salesOrder, '#${order.salesOrderId!.substring(0, 6)}', icon: Icons.shopping_cart_outlined),
                              _buildInfoRow(appLocalizations.orderPreparer, order.orderPreparerName, icon: Icons.person_outline),
                              _buildInfoRow(
                                'تاريخ الإنشاء',
                                intl.DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt.toDate()),
                                icon: Icons.calendar_today_outlined,
                                textColor: Colors.grey[700],
                              ),
                              const SizedBox(height: 8),
                              if (isManager && order.status == ProductionOrderStatus.pending)
                                Align(
                                  alignment: Alignment.bottomLeft, // Align actions to bottom left for RTL
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 22),
                                        onPressed: () => _showApproveDialog(context, order, currentUser, appLocalizations),
                                        tooltip: appLocalizations.approve,
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 22),
                                        onPressed: () => _showRejectDialog(context, order, currentUser, appLocalizations),
                                        tooltip: appLocalizations.reject,
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
          ),
        ],
      ),
    );
  }


  Color _getStatusColor(ProductionOrderStatus status) {
    switch (status) {
      case ProductionOrderStatus.pending:
        return AppColors.accentOrange; // Using predefined accent orange
      case ProductionOrderStatus.approved:
        return Colors.blue.shade700;
      case ProductionOrderStatus.inProduction:
        return Colors.purple.shade700;
      case ProductionOrderStatus.completed:
        return Colors.green.shade700;
      case ProductionOrderStatus.canceled:
      case ProductionOrderStatus.rejected:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildFilterChip(String label, String value, String selectedValue, Function(String) onSelected) {
    final bool isSelected = selectedValue == value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        showCheckmark: false,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) Icon(Icons.check, size: 18, color: AppColors.primary),
            if (isSelected) const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            onSelected(value);
          }
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        elevation: isSelected ? 0 : 1,
        side: !isSelected ? BorderSide(color: AppColors.primary, width: 0.5) : BorderSide.none,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(appLocalizations.approveOrderConfirmation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${appLocalizations.confirmApproveOrder} "${order.productName}"؟', textAlign: TextAlign.center, style: TextStyle(color: AppColors.dark)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.addNotes,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.notes_outlined, color: AppColors.dark),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    maxLines: 3,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final img = await picker.pickImage(source: ImageSource.camera);
                            if (img != null) setState(() => pickedImages.add(img));
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: Text(appLocalizations.camera),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await pickImages();
                            setState(() {});
                          },
                          icon: const Icon(Icons.photo_library),
                          label: Text(appLocalizations.gallery),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (pickedImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: pickedImages
                            .map((e) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(e.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(appLocalizations.cancel),
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(foregroundColor: AppColors.dark),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(appLocalizations.approve, style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext loadingContext) {
                      return Center(child: CircularProgressIndicator(color: AppColors.primary));
                    },
                  );
                  try {
                    await Provider.of<ProductionOrderUseCases>(context, listen: false).approveProductionOrder(
                      order,
                      approver,
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      attachments: pickedImages.map((e) => File(e.path)).toList(),
                    );
                    Navigator.of(context).pop(); // Pop the loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations.orderApprovedSuccessfully)),
                    );
                  } catch (e) {
                    Navigator.of(context).pop(); // Pop the loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${appLocalizations.errorApprovingOrder}: $e')),
                    );
                    print('Error approving order: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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

  void _showRejectDialog(BuildContext context, ProductionOrderModel order, UserModel approver, AppLocalizations appLocalizations) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.rejectOrderConfirmation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${appLocalizations.confirmRejectOrder} "${order.productName}"؟', textAlign: TextAlign.center, style: TextStyle(color: AppColors.dark)),
              SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: appLocalizations.rejectionReason,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.feedback_outlined, color: AppColors.dark),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
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
              style: TextButton.styleFrom(foregroundColor: AppColors.dark),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.close, color: Colors.white),
              label: Text(appLocalizations.reject, style: TextStyle(color: Colors.white)),
              onPressed: () async {
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(appLocalizations.rejectionReasonRequired)),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return Center(child: CircularProgressIndicator(color: AppColors.primary));
                  },
                );
                try {
                  await Provider.of<ProductionOrderUseCases>(context, listen: false).rejectProductionOrder(order, approver, reasonController.text);
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLocalizations.orderRejectedSuccessfully)),
                  );
                } catch (e) {
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorRejectingOrder}: $e')),
                  );
                  print('Error rejecting order: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      },
    );
  }
}