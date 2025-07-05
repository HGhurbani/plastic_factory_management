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
import 'sales_order_detail_page.dart';
import 'create_sales_order_screen.dart';
import '../../theme/app_colors.dart'; // Ensure this defines your app's color scheme
import '../../core/extensions/string_extensions.dart';

class SalesOrdersListScreen extends StatefulWidget {
  const SalesOrdersListScreen({super.key});

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
        appBar: AppBar(
          title: Text(appLocalizations.salesOrders),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_outlined, // More descriptive icon
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  appLocalizations.loginRequiredToViewOrders, // New localization key
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bool isSalesRepresentative = currentUser.userRoleEnum == UserRole.salesRepresentative;
    final bool isManager = currentUser.userRoleEnum == UserRole.factoryManager ||
        currentUser.userRoleEnum == UserRole.productionManager ||
        currentUser.userRoleEnum == UserRole.accountant;
    final bool isAccountant = currentUser.userRoleEnum == UserRole.accountant;
    final bool isProductionOrderPreparer = currentUser.userRoleEnum == UserRole.operationsOfficer ||
        currentUser.userRoleEnum == UserRole.productionOrderPreparer;
    final bool isInventoryManager = currentUser.userRoleEnum == UserRole.inventoryManager;
    final bool isMoldInstallationSupervisor = currentUser.userRoleEnum == UserRole.moldInstallationSupervisor;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.salesOrders),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isSalesRepresentative)
            IconButton(
              icon: const Icon(Icons.add_shopping_cart_outlined), // More specific icon
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) =>  CreateSalesOrderScreen()));
              },
              tooltip: appLocalizations.createSalesOrder,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
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
                  _buildFilterChip(appLocalizations.warehouseProcessing, SalesOrderStatus.warehouseProcessing.toFirestoreString(), _selectedStatusFilter, (value) {
                    setState(() {
                      _selectedStatusFilter = value;
                    });
                  }),
                  // _buildFilterChip(appLocalizations.awaitingMoldApproval, SalesOrderStatus.awaitingMoldApproval.toFirestoreString(), _selectedStatusFilter, (value) {
                  //   setState(() {
                  //     _selectedStatusFilter = value;
                  //   });
                  // }),
                  _buildFilterChip(appLocalizations.inProduction, SalesOrderStatus.inProduction.toFirestoreString(), _selectedStatusFilter, (value) {
                    setState(() {
                      _selectedStatusFilter = value;
                    });
                  }),
                  // _buildFilterChip(appLocalizations.fulfilled, SalesOrderStatus.fulfilled.toFirestoreString(), _selectedStatusFilter, (value) {
                  //   setState(() {
                  //     _selectedStatusFilter = value;
                  //   });
                  // }),
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
                  ? salesUseCases.getSalesOrders(salesRepUid: currentUser.uid)
                  : salesUseCases.getSalesOrders(),
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
                            appLocalizations.errorLoadingSalesOrders,
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
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, color: Colors.grey[400], size: 80),
                          const SizedBox(height: 16),
                          Text(
                            appLocalizations.noSalesOrdersAvailable,
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (isSalesRepresentative)
                            Text(
                              appLocalizations.tapToAddFirstOrder, // New localization key
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          if (isSalesRepresentative) const SizedBox(height: 24),
                          if (isSalesRepresentative)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) =>  CreateSalesOrderScreen()));
                              },
                              icon: const Icon(Icons.add),
                              label: Text(appLocalizations.createSalesOrder),
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

                final List<SalesOrderModel> filteredOrders = _selectedStatusFilter == 'all'
                    ? snapshot.data!
                    : snapshot.data!.where((order) => order.status.toFirestoreString() == _selectedStatusFilter).toList();

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
                            appLocalizations.noSalesOrdersWithFilter,
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            appLocalizations.tryDifferentFilter, // New localization key
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
                      elevation: 1, // More prominent card
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell( // Use InkWell for better visual feedback on tap
                        onTap: () {
                          // Navigate to the new SalesOrderDetailPage
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SalesOrderDetailPage(order: order),
                          ));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0), // Padding inside the card
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Order ID and Status at top
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getSalesOrderStatusColor(order.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      order.status.toArabicString(),
                                      style: TextStyle(
                                        color: _getSalesOrderStatusColor(order.status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '#${order.id.shortId()}', // Short ID for card
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ),
                              const Divider(height: 16), // Separator
                              _buildInfoRow(appLocalizations.customerName, order.customerName, icon: Icons.person_outline),
                              _buildInfoRow(appLocalizations.salesRepresentative, order.salesRepresentativeName, icon: Icons.badge_outlined),
                              _buildInfoRow(appLocalizations.totalAmount, '﷼${order.totalAmount.toStringAsFixed(2)}', icon: Icons.currency_exchange, isBold: true),
                              _buildInfoRow(appLocalizations.orderDate, intl.DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt.toDate()), icon: Icons.calendar_today_outlined),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.bottomLeft, // Align actions to bottom left for RTL
                                child: _buildTrailingActions(
                                  context,
                                  order,
                                  currentUser,
                                  salesUseCases,
                                  productionUseCases,
                                  appLocalizations,
                                  isManager,
                                  isAccountant,
                                  isProductionOrderPreparer,
                                  isInventoryManager,
                                  isMoldInstallationSupervisor,
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


  Widget _buildFilterChip(String label, String value, String selectedValue, Function(String) onSelected) {
    final bool isSelected = selectedValue == value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        showCheckmark: false,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(Icons.check, size: 18, color: AppColors.primary),
            if (isSelected)
              const SizedBox(width: 4),
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
        side: !isSelected
            ? BorderSide(color: AppColors.primary, width: 0.5)
            : BorderSide.none,
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
      bool isAccountant,
      bool isProductionOrderPreparer,
      bool isInventoryManager,
      bool isMoldInstallationSupervisor) {
    List<Widget> actions = [];

    // Common actions (e.g., delete for sales representative, or maybe for managers)
    if (currentUser.userRoleEnum == UserRole.salesRepresentative &&
        (order.status == SalesOrderStatus.pendingApproval || order.status == SalesOrderStatus.rejected)) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _showDeleteOrderConfirmationDialog(context, useCases, appLocalizations, order.id, order.customerName),
          tooltip: appLocalizations.delete,
        ),
      );
    }

    // Role-specific actions
    if (isAccountant && order.status == SalesOrderStatus.pendingApproval) {
      actions.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: Text(appLocalizations.approve),
              onPressed: () => _showApproveDialog(context, useCases, appLocalizations, order),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 12), // ← المسافة بين الزرين
            ElevatedButton.icon(
              icon: const Icon(Icons.cancel_outlined, color: Colors.white),
              label: Text(appLocalizations.reject),
              onPressed: () => _showRejectDialog(context, useCases, appLocalizations, order),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );

    } else if (isProductionOrderPreparer &&
        order.status == SalesOrderStatus.pendingFulfillment) {
      actions.add(
        ElevatedButton.icon(
          icon: const Icon(Icons.local_shipping_outlined, color: Colors.white,),
          label: Text(appLocalizations.initiateSupply),
          onPressed: () => _showInitiateSupplyDialog(
              context, useCases, appLocalizations, order, currentUser),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    } else if (isInventoryManager && order.status == SalesOrderStatus.warehouseProcessing) {
      actions.add(
        ElevatedButton.icon(
          icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
          label: Text(appLocalizations.warehouseDocumentation), // أو استخدم 'تجهيز الطلب'
          onPressed: () => _showWarehouseDocDialog(context, useCases, appLocalizations, order, currentUser),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );

    }  else if (isMoldInstallationSupervisor &&
        order.status == SalesOrderStatus.awaitingMoldApproval) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
          onPressed: () => _showMoldApprovalDialog(
              context, useCases, productionUseCases, appLocalizations, order, currentUser),
          tooltip: appLocalizations.approveMoldTasks, // New localization
        ),
      );
    } else if (isMoldInstallationSupervisor && order.moldTasksEnabled) {
      // This is for documenting the mold installation
      actions.add(
        IconButton(
          icon: const Icon(Icons.camera_alt_outlined, color: AppColors.dark),
          onPressed: () => _showMoldDocDialog(context, useCases, appLocalizations, order),
          tooltip: appLocalizations.moldInstallationDocumentation,
        ),
      );
    }

    // If there are actions, wrap them in a Row. Otherwise, return an empty SizedBox.
    return actions.isNotEmpty
        ? Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    )
        : const SizedBox.shrink();
  }

  Color _getSalesOrderStatusColor(SalesOrderStatus status) {
    switch (status) {
      case SalesOrderStatus.pendingApproval:
        return AppColors.accentOrange; // Defined in AppColors if available
      case SalesOrderStatus.pendingFulfillment:
        return AppColors.secondary; // Use a distinct color for this stage
      case SalesOrderStatus.warehouseProcessing:
        return Colors.blue.shade700;
      case SalesOrderStatus.inProduction:
        return Colors.deepPurple.shade700;
      case SalesOrderStatus.fulfilled:
        return Colors.green.shade700;
      case SalesOrderStatus.canceled:
        return Colors.red.shade700;
      case SalesOrderStatus.rejected:
        return Colors.red.shade900;
      case SalesOrderStatus.awaitingMoldApproval:
        return Colors.brown.shade600; // New status color
      default:
        return Colors.grey.shade600;
    }
  }



  Widget _buildInfoRow(String label, String value, {Color? textColor, bool isBold = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.7)),
          ],
          const SizedBox(width: 8),

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
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),

        ],
      ),
    );
  }

  void _showImagePreviewDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer( // Allows zoom and pan
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    final expected = loadingProgress.expectedTotalBytes;
                    final value = expected != null
                        ? loadingProgress.cumulativeBytesLoaded / expected
                        : null;
                    return Center(
                      child: CircularProgressIndicator(
                        value: value,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 50, color: Colors.red),
                              Text(AppLocalizations.of(context)!.imageLoadError, style: TextStyle(color: Colors.white)), // New localization
                            ],
                          ),
                        ),
                      ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFulfillOrderDialog(BuildContext context, SalesUseCases useCases, AppLocalizations appLocalizations, String orderId, String customerName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.markAsFulfilledConfirmation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text('${appLocalizations.confirmFulfillOrder}: "$customerName"؟', textAlign: TextAlign.center),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.done_all, color: Colors.white,),
              label: Text(appLocalizations.fulfill),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Pop the confirmation dialog
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );
                try {
                  await useCases.updateSalesOrderStatus(orderId, SalesOrderStatus.fulfilled);
                  Navigator.of(context).pop(); // Pop the loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLocalizations.orderFulfilledSuccessfully)),
                  );
                } catch (e) {
                  Navigator.of(context).pop(); // Pop the loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorFulfillingOrder}: ${e.toString()}')),
                  );
                  print('Error fulfilling order: $e'); // For debugging
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showApproveDialog(BuildContext parentContext, SalesUseCases useCases,
      AppLocalizations appLocalizations, SalesOrderModel order) {
    final TextEditingController notesController = TextEditingController();
    showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(appLocalizations.approveOrderConfirmation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${appLocalizations.reviewOrderDetails}', style: TextStyle(color: Colors.grey[700]), textAlign: TextAlign.right), // New instruction
              const Divider(),
              _buildInfoRow(appLocalizations.customerName, order.customerName, icon: Icons.person_outline),
              _buildInfoRow(
                  appLocalizations.salesRepresentative, order.salesRepresentativeName, icon: Icons.badge_outlined),
                _buildInfoRow(appLocalizations.totalAmount,
                    '﷼${order.totalAmount.toStringAsFixed(2)}', icon: Icons.currency_exchange, isBold: true, textColor: AppColors.primary),
              _buildInfoRow(appLocalizations.status, order.status.toArabicString(),
                  icon: Icons.info_outline, textColor: _getSalesOrderStatusColor(order.status), isBold: true),
              _buildInfoRow(appLocalizations.orderDate,
                  intl.DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt.toDate()), icon: Icons.calendar_today_outlined),
              const SizedBox(height: 16),
              Text(appLocalizations.orderItems,
                  style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  textAlign: TextAlign.right),
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: order.orderItems
                    .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                      '${item.productName} - ${item.quantity} ${item.quantityUnit ?? appLocalizations.units} @ ﷼${item.unitPrice.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                  ),
                ))
                    .toList(),
              ),
              if (order.customerSignatureUrl != null && order.customerSignatureUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(appLocalizations.customerSignature,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                          textAlign: TextAlign.right),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          order.customerSignatureUrl!,
                          height: 100,
                          // Avoid using double.infinity which causes layout issues
                          // inside the IntrinsicWidth of AlertDialog
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            final expected = loadingProgress.expectedTotalBytes;
                            final value = expected != null
                                ? loadingProgress.cumulativeBytesLoaded / expected
                                : null;
                            return Center(child: CircularProgressIndicator(value: value));
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 100,
                                color: Colors.grey[200],
                                child: Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey[400])),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: appLocalizations.enterApprovalNotes,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              Text('${appLocalizations.confirmApproveOrderQuestion}: "${order.customerName}"؟', // More explicit question
                  textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(appLocalizations.cancel),
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check,color: Colors.white,),
            label: Text(appLocalizations.approve),
            onPressed: () async {
              Navigator.of(context).pop(); // Pop the confirmation dialog
              // Show loading indicator
              showDialog(
                context: parentContext,
                barrierDismissible: false,
                builder: (BuildContext loadingContext) {
                  return const Center(child: CircularProgressIndicator());
                },
              );
              try {
                final user = Provider.of<UserModel?>(context, listen: false);
                if (user == null) {
                  Navigator.of(parentContext).pop(); // Pop the loading indicator
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text(appLocalizations.loginPrompt)),
                  );
                  return;
                }

                await useCases.approveSalesOrder(
                  order,
                  user,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );
                Navigator.of(parentContext).pop(); // Pop the loading indicator
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                      content: Text(appLocalizations.orderApprovedSuccessfully)),
                );
              } catch (e) {
                Navigator.of(parentContext).pop(); // Pop the loading indicator
                final msg = e.toString().contains('CREDIT_LIMIT_EXCEEDED')
                    ? appLocalizations.creditLimitExceeded
                    : '${appLocalizations.errorApprovingOrder}: ${e.toString()}';
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
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
  }

  void _showRejectDialog(BuildContext parentContext, SalesUseCases useCases, AppLocalizations appLocalizations, SalesOrderModel order) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(appLocalizations.rejectOrderConfirmation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${appLocalizations.confirmRejectOrderQuestion}: "${order.customerName}"؟', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: appLocalizations.rejectionReason,
                border: const OutlineInputBorder(),
                hintText: appLocalizations.enterRejectionReason, // New hint text
                prefixIcon: const Icon(Icons.feedback_outlined),
              ),
              maxLines: 3,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(appLocalizations.cancel),
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.close),
            label: Text(appLocalizations.reject),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(appLocalizations.rejectionReasonRequired)), // New snackbar
                );
                return;
              }
              Navigator.of(context).pop(); // Pop the confirmation dialog
              // Show loading indicator
              showDialog(
                context: parentContext,
                barrierDismissible: false,
                builder: (BuildContext loadingContext) {
                  return const Center(child: CircularProgressIndicator());
                },
              );
              try {
                final user = Provider.of<UserModel?>(context, listen: false)!;
                await useCases.rejectSalesOrder(order, user, reasonController.text.trim());
                Navigator.of(parentContext).pop(); // Pop the loading indicator
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text(appLocalizations.orderRejectedSuccessfully)),
                );
              } catch (e) {
                Navigator.of(parentContext).pop(); // Pop the loading indicator
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text('${appLocalizations.errorRejectingOrder}: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showInitiateSupplyDialog(BuildContext parentContext, SalesUseCases salesUseCases, AppLocalizations appLocalizations, SalesOrderModel order, UserModel preparer) async {
    final userUseCases = Provider.of<UserUseCases>(parentContext, listen: false);
    final storekeepers = await userUseCases.getUsersByRole(UserRole.inventoryManager);
    if (storekeepers.isEmpty) {
      // Show an error or informative message if no storekeepers are found
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(content: Text(appLocalizations.noStorekeepersFound)), // New localization
      );
      return;
    }
    // Pre-select the first storekeeper if available, otherwise null
    UserModel? _selectedStorekeeper = storekeepers.isNotEmpty ? storekeepers.first : null;
    final TextEditingController notesController =
        TextEditingController(text: order.warehouseNotes);

    await showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.selectStorekeeper, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(appLocalizations.assignOrderToStorekeeper, textAlign: TextAlign.right, style: TextStyle(color: Colors.grey[700])), // New instruction
              const SizedBox(height: 12),
              DropdownButtonFormField<UserModel>(
                value: _selectedStorekeeper,
                decoration: InputDecoration(
                  labelText: appLocalizations.storekeeper, // New localization
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                items: storekeepers
                    .map((u) => DropdownMenuItem(value: u, child: Text(u.name, textDirection: TextDirection.rtl)))
                    .toList(),
                onChanged: (u) => setState(() {
                  _selectedStorekeeper = u;
                }),
                validator: (value) => value == null ? appLocalizations.fieldRequired : null, // Added validation
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: appLocalizations.enterNotes,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send, color: Colors.white,), // Send icon
              label: Text(appLocalizations.initiateSupply),
              onPressed: () async {
                if (_selectedStorekeeper == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(appLocalizations.selectStorekeeperError)), // New snackbar
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(); // Pop the dialog
                // Show loading indicator
                showDialog(
                  context: parentContext,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );
                try {
                  await salesUseCases.initiateSupply(
                    order,
                    preparer,
                    _selectedStorekeeper!,
                    notes: notesController.text.trim(),
                  );
                  Navigator.of(parentContext).pop(); // Pop the loading indicator
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text(appLocalizations.supplyInitiatedSuccessfully)), // New confirmation
                  );
                } catch (e) {
                  Navigator.of(parentContext).pop(); // Pop the loading indicator
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorInitiatingSupply}: ${e.toString()}')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(appLocalizations.approveMoldTasks, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '${appLocalizations.confirmApproveMoldTasks}: "${order.customerName}"؟\n\n${appLocalizations.thisActionWillCreateProductionOrder}', // Added warning
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            child: Text(appLocalizations.cancel),
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: Text(appLocalizations.approve),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Pop the confirmation dialog
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext loadingContext) {
                  return const Center(child: CircularProgressIndicator());
                },
              );
              try {
                await useCases.approveMoldTasks(order, supervisor);
                await productionUseCases.createProductionOrdersFromSalesOrder(order, supervisor);
                Navigator.of(context).pop(); // Pop the loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(appLocalizations.moldTasksApprovedSuccessfully)), // New confirmation
                );
              } catch (e) {
                Navigator.of(context).pop(); // Pop the loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${appLocalizations.errorApprovingMoldTasks}: ${e.toString()}')), // New error message
                );
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
  }

  void _showMoldDocDialog(BuildContext parentContext, SalesUseCases useCases, AppLocalizations appLocalizations, SalesOrderModel order) {
    final TextEditingController notesController = TextEditingController(text: order.moldInstallationNotes);
    List<XFile> pickedImages = [];
    // Initialize with existing images
    if (order.moldInstallationImages.isNotEmpty) {
      pickedImages.addAll(order.moldInstallationImages.map((url) => XFile(url))); // Assuming XFile can take a URL or path for display
    }

    final ImagePicker picker = ImagePicker();

    Future<void> _pickImages(ImageSource source) async {
      if (source == ImageSource.camera) {
        final image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          pickedImages.add(image);
        }
      } else {
        final images = await picker.pickMultiImage();
        if (images != null) {
          pickedImages.addAll(images);
        }
      }
    }

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.moldInstallationDocumentation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.enterNotes,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                  maxLines: 3,
                  textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 16),
                Text(appLocalizations.addImages, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _pickImages(ImageSource.camera);
                          setState(() {});
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
                          await _pickImages(ImageSource.gallery);
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
                const SizedBox(height: 16),
                pickedImages.isEmpty
                    ? Text(appLocalizations.noImagesSelected, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center)
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: pickedImages.length,
                  itemBuilder: (context, index) {
                    final imageFile = pickedImages[index];
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageFile.path.startsWith('http')
                              ? Image.network(imageFile.path, width: 100, height: 100, fit: BoxFit.cover)
                              : Image.file(File(imageFile.path), width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              pickedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.remove_circle, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: Text(appLocalizations.save),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Pop the dialog
                // Show loading indicator
                showDialog(
                  context: parentContext,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );
                try {
                  await useCases.addMoldInstallationDocs(
                    order: order,
                    notes: notesController.text.trim(),
                    attachments: pickedImages.map((e) => File(e.path)).toList(), // Convert XFile to File
                  );
                  Navigator.of(parentContext).pop(); // Pop loading
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text(appLocalizations.documentationSavedSuccessfully)), // New confirmation
                  );
                } catch (e) {
                  Navigator.of(parentContext).pop(); // Pop loading
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorSavingDocumentation}: ${e.toString()}')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWarehouseDocDialog(BuildContext parentContext, SalesUseCases useCases, AppLocalizations appLocalizations, SalesOrderModel order, UserModel storekeeper) {
    final TextEditingController notesController = TextEditingController(text: order.warehouseNotes);
    List<XFile> pickedImages = [];
    // Initialize with existing images
    if (order.warehouseImages.isNotEmpty) {
      pickedImages.addAll(order.warehouseImages.map((url) => XFile(url)));
    }

    final ImagePicker picker = ImagePicker();
    DateTime? selectedDeliveryTime = order.deliveryTime?.toDate(); // Initialize with existing delivery time

    Future<void> _pickImages(ImageSource source) async {
      if (source == ImageSource.camera) {
        final image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          pickedImages.add(image);
        }
      } else {
        final images = await picker.pickMultiImage();
        if (images != null) {
          pickedImages.addAll(images);
        }
      }
    }

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.warehouseDocumentation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.enterNotes,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                  maxLines: 3,
                  textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 16),
                Text(appLocalizations.addImages, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _pickImages(ImageSource.camera);
                          setState(() {});
                        },
                        icon: const Icon(Icons.camera_alt,color: Colors.white,),
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
                          await _pickImages(ImageSource.gallery);
                          setState(() {});
                        },
                        icon: const Icon(Icons.photo_library, color: Colors.white,),
                        label: Text(appLocalizations.gallery),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                pickedImages.isEmpty
                    ? Text(appLocalizations.noImagesSelected, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center)
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: pickedImages.length,
                  itemBuilder: (context, index) {
                    final imageFile = pickedImages[index];
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageFile.path.startsWith('http')
                              ? Image.network(imageFile.path, width: 100, height: 100, fit: BoxFit.cover)
                              : Image.file(File(imageFile.path), width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              pickedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.remove_circle, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(appLocalizations.selectDeliveryTime, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDeliveryTime ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primary, // dialog primary color
                            onPrimary: Colors.white, // text color on primary
                            onSurface: AppColors.dark, // text color on surface
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDeliveryTime ?? DateTime.now()),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              onSurface: AppColors.dark,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDeliveryTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.event),
                  label: Text(
                    selectedDeliveryTime == null
                        ? appLocalizations.selectDeliveryDateAndTime // New localization
                        : intl.DateFormat('yyyy-MM-dd HH:mm').format(selectedDeliveryTime!),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: AppColors.dark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_to_mobile,color: Colors.white,), // Specific icon for "send to production"
              label: Text(appLocalizations.sendToProduction),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Pop the dialog
                // Show loading indicator
                showDialog(
                  context: parentContext,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );
                try {
                  await useCases.documentWarehouseSupply(
                    order: order,
                    storekeeper: storekeeper,
                    notes: notesController.text.trim(),
                    attachments: pickedImages.map((e) => File(e.path)).toList(),
                    deliveryTime: selectedDeliveryTime,
                  );
                  Navigator.of(parentContext).pop(); // Pop loading
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text(appLocalizations.warehouseSupplyDocumentedSuccessfully)), // New confirmation
                  );
                } catch (e) {
                  Navigator.of(parentContext).pop(); // Pop loading
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorDocumentingWarehouseSupply}: ${e.toString()}')), // New error message
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteOrderConfirmationDialog(
      BuildContext context,
      SalesUseCases useCases,
      AppLocalizations appLocalizations,
      String orderId,
      String customerName,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.confirmDeletion, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(
            '${appLocalizations.confirmDeleteOrder}: "$customerName"?\n\n${appLocalizations.thisActionCannotBeUndone}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: Text(appLocalizations.delete),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Pop confirmation dialog
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );
                try {
                  await useCases.deleteSalesOrder(orderId);
                  Navigator.of(context).pop(); // Pop loading
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(content: Text(appLocalizations.orderDeletedSuccessfully)));
                } catch (e) {
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorDeletingOrder}: ${e.toString()}')),
                  );
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