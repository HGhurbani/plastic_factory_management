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
import '../../theme/app_colors.dart'; // Ensure this defines your app's color scheme

class SalesOrdersListScreen extends StatefulWidget {
  const SalesOrdersListScreen({super.key});

  @override
  _SalesOrdersListScreenState createState() => _SalesOrdersListScreenState();
}

class _SalesOrdersListScreenState extends State<SalesOrdersListScreen> {
  // Use a nullable string for the filter to represent "all" more clearly and align with enum values.
  String? _selectedStatusFilter; // Changed to nullable to represent 'all'
  final ImagePicker _picker = ImagePicker(); // Initialize ImagePicker once

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final salesUseCases = Provider.of<SalesUseCases>(context);
    final productionUseCases = Provider.of<ProductionOrderUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context);

    // --- User Not Logged In State ---
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
                  Icons.person_off_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  appLocalizations.loginRequiredToViewOrders,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Provide a clear action button for login if applicable
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement navigation to login screen
                    // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations.loginPrompt)),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: Text(appLocalizations.login),
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
        ),
      );
    }

    // Determine user roles for conditional UI elements
    final bool isSalesRepresentative = currentUser.userRoleEnum == UserRole.salesRepresentative;
    final bool isManager = currentUser.userRoleEnum == UserRole.factoryManager ||
        currentUser.userRoleEnum == UserRole.productionManager ||
        currentUser.userRoleEnum == UserRole.accountant;
    final bool isAccountant = currentUser.userRoleEnum == UserRole.accountant;
    final bool isProductionOrderPreparer = currentUser.userRoleEnum == UserRole.productionOrderPreparer;
    final bool isInventoryManager = currentUser.userRoleEnum == UserRole.inventoryManager;
    final bool isMoldInstallationSupervisor = currentUser.userRoleEnum == UserRole.moldInstallationSupervisor;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.salesOrders),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4, // Added elevation for a more prominent AppBar
        actions: [
          if (isSalesRepresentative)
            IconButton(
              icon: const Icon(Icons.add_shopping_cart_outlined),
              onPressed: () {
                // Navigate with a more descriptive route name if using named routes
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateSalesOrderScreen()));
              },
              tooltip: appLocalizations.createSalesOrder,
            ),
          const SizedBox(width: 8), // Add some spacing
        ],
      ),
      body: Column(
        children: [
          // --- Filter Chips ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Added padding to the Row for better spacing around chips
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFilterChip(appLocalizations.all, null, _selectedStatusFilter, (value) {
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
                    _buildFilterChip(appLocalizations.inProduction, SalesOrderStatus.inProduction.toFirestoreString(), _selectedStatusFilter, (value) {
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
                    _buildFilterChip(appLocalizations.warehouseProcessing, SalesOrderStatus.warehouseProcessing.toFirestoreString(), _selectedStatusFilter, (value) {
                      setState(() {
                        _selectedStatusFilter = value;
                      });
                    }),
                    _buildFilterChip(appLocalizations.awaitingMoldApproval, SalesOrderStatus.awaitingMoldApproval.toFirestoreString(), _selectedStatusFilter, (value) {
                      setState(() {
                        _selectedStatusFilter = value;
                      });
                    }),
                  ],
                ),
              ),
            ),
          ),
          // --- Sales Orders List ---
          Expanded(
            child: StreamBuilder<List<SalesOrderModel>>(
              stream: isSalesRepresentative
                  ? salesUseCases.getSalesOrders(salesRepUid: currentUser.uid)
                  : salesUseCases.getSalesOrders(),
              builder: (context, snapshot) {
                // --- Loading State ---
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // --- Error State ---
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0), // Increased padding
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 70), // Themed error color
                          const SizedBox(height: 20), // Increased spacing
                          Text(
                            appLocalizations.errorLoadingSalesOrders,
                            style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${appLocalizations.technicalDetails}: ${snapshot.error}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey), // Slightly larger font for details
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Optionally, add a retry mechanism by re-fetching data
                              setState(() {}); // Rebuilds the widget, re-triggering the StreamBuilder
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(appLocalizations.tryAgain), // New localization key for retry
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
                // --- No Data State ---
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, color: Colors.grey[400], size: 90), // Larger icon
                          const SizedBox(height: 20),
                          Text(
                            appLocalizations.noSalesOrdersAvailable,
                            style: TextStyle(fontSize: 20, color: Colors.grey[700], fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          if (isSalesRepresentative)
                            Text(
                              appLocalizations.tapToAddFirstOrder,
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          if (isSalesRepresentative) const SizedBox(height: 32),
                          if (isSalesRepresentative)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateSalesOrderScreen()));
                              },
                              icon: const Icon(Icons.add),
                              label: Text(appLocalizations.createSalesOrder),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Larger button
                                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                // --- Filtering Logic ---
                final List<SalesOrderModel> filteredOrders = _selectedStatusFilter == null
                    ? snapshot.data!
                    : snapshot.data!.where((order) => order.status.toFirestoreString() == _selectedStatusFilter).toList();

                // --- No Filtered Data State ---
                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_alt_off, color: Colors.grey[400], size: 90),
                          const SizedBox(height: 20),
                          Text(
                            appLocalizations.noSalesOrdersWithFilter,
                            style: TextStyle(fontSize: 20, color: Colors.grey[700], fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            appLocalizations.tryDifferentFilter,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedStatusFilter = null; // Clear filter
                              });
                            },
                            icon: const Icon(Icons.clear_all),
                            label: Text(appLocalizations.clearFilter), // New localization key
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary, // Different color for clear filter
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // --- Display Sales Orders ---
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8), // Add vertical padding to the list
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3, // Increased elevation for a richer look
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias, // Ensures content is clipped to rounded corners
                      child: InkWell(
                        onTap: () {
                          _showSalesOrderDetailDialog(context, appLocalizations, order);
                        },
                        // Added a subtle splash color for better feedback
                        splashColor: AppColors.primary.withOpacity(0.1),
                        highlightColor: AppColors.primary.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0), // Increased padding inside the card
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Order ID and Status at top
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Larger padding
                                    decoration: BoxDecoration(
                                      color: _getSalesOrderStatusColor(order.status).withOpacity(0.15), // Slightly more opaque
                                      borderRadius: BorderRadius.circular(20), // More rounded
                                    ),
                                    child: Text(
                                      order.status.toArabicString(),
                                      style: TextStyle(
                                        color: _getSalesOrderStatusColor(order.status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15, // Slightly larger font
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${appLocalizations.orderId}: #${order.id.substring(0, 6).toUpperCase()}', // Added "Order ID:" and uppercase for clarity
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w500),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ),
                              const Divider(height: 20, thickness: 1), // Thicker separator
                              _buildInfoRow(appLocalizations.customerName, order.customerName, icon: Icons.person_outline),
                              _buildInfoRow(appLocalizations.salesRepresentative, order.salesRepresentativeName, icon: Icons.badge_outlined),
                              _buildInfoRow(appLocalizations.totalAmount, '\$${order.totalAmount.toStringAsFixed(2)}', icon: Icons.attach_money, isBold: true),
                              _buildInfoRow(appLocalizations.orderDate, intl.DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt.toDate()), icon: Icons.calendar_today_outlined),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.bottomLeft,
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

  // --- Helper Widgets ---

  Widget _buildFilterChip(String label, String? value, String? selectedValue, Function(String?) onSelected) {
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
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: selectedValue == value ? AppColors.primary : Colors.black87,
          fontWeight: selectedValue == value ? FontWeight.bold : FontWeight.normal,
        ),
        elevation: selectedValue == value ? 2 : 0, // Add elevation when selected
        pressElevation: 4, // More pronounced press effect
        backgroundColor: Colors.grey[100], // Default background color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // More rounded chip
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
        Tooltip(
          message: appLocalizations.delete,
          child: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _showDeleteOrderConfirmationDialog(context, useCases, appLocalizations, order.id, order.customerName),
          ),
        ),
      );
    }

    // Role-specific actions
    if (isAccountant && order.status == SalesOrderStatus.pendingApproval) {
      actions.add(
        Tooltip(
          message: appLocalizations.approve,
          child: IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => _showApproveDialog(context, useCases, appLocalizations, order),
          ),
        ),
      );
      actions.add(
        Tooltip(
          message: appLocalizations.reject,
          child: IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            onPressed: () => _showRejectDialog(context, useCases, appLocalizations, order),
          ),
        ),
      );
    } else if (isProductionOrderPreparer &&
        order.status == SalesOrderStatus.pendingFulfillment) {
      actions.add(
        Tooltip(
          message: appLocalizations.initiateSupply,
          child: IconButton(
            icon: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
            onPressed: () => _showInitiateSupplyDialog(
                context, useCases, appLocalizations, order, currentUser),
          ),
        ),
      );
    } else if (isInventoryManager && order.status == SalesOrderStatus.warehouseProcessing) {
      actions.add(
        Tooltip(
          message: appLocalizations.warehouseDocumentation,
          child: IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: AppColors.secondary),
            onPressed: () => _showWarehouseDocDialog(context, useCases, appLocalizations, order, currentUser),
          ),
        ),
      );
    } else if (isManager && order.status == SalesOrderStatus.warehouseProcessing) {
      actions.add(
        Tooltip(
          message: appLocalizations.markAsFulfilled,
          child: IconButton(
            icon: const Icon(Icons.done_all, color: Colors.green),
            onPressed: () {
              _showFulfillOrderDialog(context, useCases, appLocalizations, order.id, order.customerName);
            },
          ),
        ),
      );
    } else if (isMoldInstallationSupervisor &&
        order.status == SalesOrderStatus.awaitingMoldApproval) {
      actions.add(
        Tooltip(
          message: appLocalizations.approveMoldTasks,
          child: IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => _showMoldApprovalDialog(
                context, useCases, productionUseCases, appLocalizations, order, currentUser),
          ),
        ),
      );
    } else if (isMoldInstallationSupervisor && order.moldTasksEnabled) {
      actions.add(
        Tooltip(
          message: appLocalizations.moldInstallationDocumentation,
          child: IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: AppColors.dark),
            onPressed: () => _showMoldDocDialog(context, useCases, appLocalizations, order),
          ),
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
        return AppColors.accentOrange;
      case SalesOrderStatus.pendingFulfillment:
        return AppColors.secondary;
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
        return Colors.brown.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  void _showSalesOrderDetailDialog(BuildContext context, AppLocalizations appLocalizations, SalesOrderModel order) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            '${appLocalizations.salesOrder} #${order.id.substring(0, 6)}...',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.dark), // Larger title, themed color
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildInfoRow(appLocalizations.customerName, order.customerName, icon: Icons.person),
                _buildInfoRow(appLocalizations.salesRepresentative, order.salesRepresentativeName, icon: Icons.badge),
                _buildInfoRow(appLocalizations.totalAmount, '\$${order.totalAmount.toStringAsFixed(2)}', icon: Icons.monetization_on, isBold: true, textColor: AppColors.primary),
                _buildInfoRow(appLocalizations.status, order.status.toArabicString(), icon: Icons.info_outline, textColor: _getSalesOrderStatusColor(order.status), isBold: true),
                _buildInfoRow(appLocalizations.orderDate, intl.DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt.toDate()), icon: Icons.date_range),
                const SizedBox(height: 20), // Increased spacing
                Text(appLocalizations.orderItems, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.dark), textAlign: TextAlign.right),
                const Divider(height: 16, thickness: 1),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: order.orderItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0), // Increased vertical padding
                    child: Text(
                      '${item.productName} - ${item.quantity} ${item.quantityUnit ?? appLocalizations.units} @ \$${item.unitPrice.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]), // Slightly larger font
                    ),
                  )).toList(),
                ),
                if (order.customerSignatureUrl != null && order.customerSignatureUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0), // Increased top padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(appLocalizations.customerSignature, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.dark), textAlign: TextAlign.right),
                        const SizedBox(height: 12), // Increased spacing
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12), // More rounded image
                          child: Image.network(
                            order.customerSignatureUrl!,
                            height: 150, // Increased height
                            width: double.infinity,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppColors.primary, // Themed color for progress indicator
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, size: 60, color: Colors.grey[400]),
                                        Text(appLocalizations.imageLoadError, style: TextStyle(color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Text(appLocalizations.orderFlowDetails, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.dark), textAlign: TextAlign.right),
                const Divider(height: 16, thickness: 1),
                if (order.approvedAt != null)
                  _buildInfoRow(
                    appLocalizations.approvalTime,
                    '${intl.DateFormat('yyyy-MM-dd HH:mm').format(order.approvedAt!.toDate())} ${appLocalizations.approvedBy} ${order.approvedByUid ?? appLocalizations.unknown}',
                    icon: Icons.check_circle_outline,
                  ),
                if (order.warehouseManagerName != null && order.warehouseManagerName!.isNotEmpty)
                  _buildInfoRow(appLocalizations.warehouseManager, order.warehouseManagerName!, icon: Icons.warehouse),
                if (order.warehouseNotes != null && order.warehouseNotes!.isNotEmpty)
                  _buildInfoRow(appLocalizations.warehouseNotes, order.warehouseNotes!, icon: Icons.notes),
                if (order.warehouseImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(appLocalizations.warehouseImages, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10.0, // Increased spacing
                    runSpacing: 10.0,
                    children: order.warehouseImages.map((e) => GestureDetector(
                      onTap: () => _showImagePreviewDialog(context, e),
                      child: Hero( // Added Hero animation for smoother image transition
                        tag: e, // Unique tag for each image
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10), // More rounded
                          child: Image.network(e, width: 90, height: 90, fit: BoxFit.cover), // Larger preview
                        ),
                      ),
                    )).toList(),
                  ),
                ],
                if (order.deliveryTime != null)
                  _buildInfoRow(appLocalizations.expectedDeliveryTime,
                      intl.DateFormat('yyyy-MM-dd HH:mm').format(order.deliveryTime!.toDate()), icon: Icons.delivery_dining),
                if (order.moldSupervisorName != null && order.moldSupervisorName!.isNotEmpty)
                  _buildInfoRow(appLocalizations.moldInstallationSupervisor, order.moldSupervisorName!, icon: Icons.person_pin),
                if (order.moldInstallationNotes != null && order.moldInstallationNotes!.isNotEmpty)
                  _buildInfoRow(appLocalizations.moldInstallationNotes, order.moldInstallationNotes!, icon: Icons.notes),
                if (order.moldInstallationImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(appLocalizations.moldInstallationImages, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: order.moldInstallationImages.map((e) => GestureDetector(
                      onTap: () => _showImagePreviewDialog(context, e),
                      child: Hero(
                        tag: e,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(e, width: 90, height: 90, fit: BoxFit.cover),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
                if (order.productionManagerName != null && order.productionManagerName!.isNotEmpty)
                  _buildInfoRow(appLocalizations.productionManager, order.productionManagerName!, icon: Icons.engineering),
                if (order.productionRejectionReason != null && order.productionRejectionReason!.isNotEmpty)
                  _buildInfoRow(appLocalizations.rejectionReason, order.productionRejectionReason!, icon: Icons.cancel, textColor: Colors.red),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.close),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.dark, // Themed color
                textStyle: const TextStyle(fontWeight: FontWeight.w600), // Slightly bolder
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor, bool isBold = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Increased vertical padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the top if it wraps
        children: [
          Expanded( // Allows text to wrap
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16, // Slightly larger font
                color: textColor ?? Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(width: 12), // Increased spacing
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark, // Themed color
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 22, color: AppColors.primary.withOpacity(0.8)), // Slightly larger and more opaque icon
          ],
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
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Hero( // Use Hero for smoother transition back
                tag: imageUrl,
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
                                Icon(Icons.error, size: 60, color: Colors.red), // Larger error icon
                                const SizedBox(height: 10),
                                Text(appLocalizations.imageLoadError, style: const TextStyle(color: Colors.white, fontSize: 16)), // Larger error text
                              ],
                            ),
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
          title: Text(appLocalizations.markAsFulfilledConfirmation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Text('${appLocalizations.confirmFulfillOrder}: "$customerName"؟', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          actionsAlignment: MainAxisAlignment.spaceEvenly, // Better spacing for actions
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.done_all),
              label: Text(appLocalizations.fulfill),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Pop the confirmation dialog
                _showLoadingDialog(context); // Show loading indicator
                try {
                  await useCases.updateSalesOrderStatus(orderId, SalesOrderStatus.fulfilled);
                  Navigator.of(context).pop(); // Pop the loading indicator
                  _showSnackBar(context, appLocalizations.orderFulfilledSuccessfully);
                } catch (e) {
                  Navigator.of(context).pop(); // Pop the loading indicator
                  _showSnackBar(context, '${appLocalizations.errorFulfillingOrder}: ${e.toString()}', isError: true);
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

  void _showApproveDialog(BuildContext context, SalesUseCases useCases,
      AppLocalizations appLocalizations, SalesOrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(appLocalizations.approveOrderConfirmation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(appLocalizations.reviewOrderDetails, style: TextStyle(color: Colors.grey[700], fontSize: 15), textAlign: TextAlign.right),
              const Divider(height: 20, thickness: 1),
              _buildInfoRow(appLocalizations.customerName, order.customerName, icon: Icons.person_outline),
              _buildInfoRow(
                  appLocalizations.salesRepresentative, order.salesRepresentativeName, icon: Icons.badge_outlined),
              _buildInfoRow(appLocalizations.totalAmount,
                  '\$${order.totalAmount.toStringAsFixed(2)}', icon: Icons.attach_money, isBold: true, textColor: AppColors.primary),
              _buildInfoRow(appLocalizations.status, order.status.toArabicString(),
                  icon: Icons.info_outline, textColor: _getSalesOrderStatusColor(order.status), isBold: true),
              _buildInfoRow(appLocalizations.orderDate,
                  intl.DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt.toDate()), icon: Icons.calendar_today_outlined),
              const SizedBox(height: 20),
              Text(appLocalizations.orderItems,
                  style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.dark),
                  textAlign: TextAlign.right),
              const Divider(height: 16, thickness: 1),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: order.orderItems
                    .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Text(
                    '${item.productName} - ${item.quantity} ${item.quantityUnit ?? appLocalizations.units} @ \$${item.unitPrice.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                ))
                    .toList(),
              ),
              if (order.customerSignatureUrl != null && order.customerSignatureUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(appLocalizations.customerSignature,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.dark),
                          textAlign: TextAlign.right),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          order.customerSignatureUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            final expected = loadingProgress.expectedTotalBytes;
                            final value = expected != null
                                ? loadingProgress.cumulativeBytesLoaded / expected
                                : null;
                            return Center(child: CircularProgressIndicator(value: value, color: AppColors.primary));
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey[400])),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Text('${appLocalizations.confirmApproveOrderQuestion}: "${order.customerName}"؟',
                  textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            child: Text(appLocalizations.cancel),
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: Text(appLocalizations.approve),
            onPressed: () async {
              Navigator.of(context).pop();
              _showLoadingDialog(context);
              try {
                final user = Provider.of<UserModel?>(context, listen: false)!;
                await useCases.approveSalesOrder(order, user);
                Navigator.of(context).pop();
                _showSnackBar(context, appLocalizations.orderApprovedSuccessfully);
              } catch (e) {
                Navigator.of(context).pop();
                _showSnackBar(context, '${appLocalizations.errorApprovingOrder}: ${e.toString()}', isError: true);
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

  void _showRejectDialog(BuildContext context, SalesUseCases useCases, AppLocalizations appLocalizations, SalesOrderModel order) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(appLocalizations.rejectOrderConfirmation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${appLocalizations.confirmRejectOrderQuestion}: "${order.customerName}"؟', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: appLocalizations.rejectionReason,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)), // More rounded input
                ),
                hintText: appLocalizations.enterRejectionReason,
                prefixIcon: const Icon(Icons.feedback_outlined, color: AppColors.primary), // Themed icon color
                alignLabelWithHint: true, // Aligns label with hint text
              ),
              maxLines: 3,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              keyboardType: TextInputType.multiline, // Soft keyboard optimized for multiple lines
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
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
                _showSnackBar(context, appLocalizations.rejectionReasonRequired, isError: true);
                return;
              }
              Navigator.of(context).pop();
              _showLoadingDialog(context);
              try {
                final user = Provider.of<UserModel?>(context, listen: false)!;
                await useCases.rejectSalesOrder(order, user, reasonController.text.trim());
                Navigator.of(context).pop();
                _showSnackBar(context, appLocalizations.orderRejectedSuccessfully);
              } catch (e) {
                Navigator.of(context).pop();
                _showSnackBar(context, '${appLocalizations.errorRejectingOrder}: ${e.toString()}', isError: true);
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

  void _showInitiateSupplyDialog(BuildContext context, SalesUseCases salesUseCases, AppLocalizations appLocalizations, SalesOrderModel order, UserModel preparer) async {
    final userUseCases = Provider.of<UserUseCases>(context, listen: false);
    final storekeepers = await userUseCases.getUsersByRole(UserRole.inventoryManager);

    if (storekeepers.isEmpty) {
      _showSnackBar(context, appLocalizations.noStorekeepersFound, isError: true);
      return;
    }

    UserModel? _selectedStorekeeper = storekeepers.isNotEmpty ? storekeepers.first : null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.selectStorekeeper, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(appLocalizations.assignOrderToStorekeeper, textAlign: TextAlign.right, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserModel>(
                value: _selectedStorekeeper,
                decoration: InputDecoration(
                  labelText: appLocalizations.storekeeper,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adjust padding
                ),
                items: storekeepers
                    .map((u) => DropdownMenuItem(value: u, child: Text(u.name, textDirection: TextDirection.rtl)))
                    .toList(),
                onChanged: (u) => setState(() {
                  _selectedStorekeeper = u;
                }),
                validator: (value) => value == null ? appLocalizations.fieldRequired : null,
                isExpanded: true, // Make dropdown expand
                style: TextStyle(color: Colors.black87, fontSize: 16), // Text style
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary), // Icon color
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: Text(appLocalizations.initiateSupply),
              onPressed: () async {
                if (_selectedStorekeeper == null) {
                  _showSnackBar(context, appLocalizations.selectStorekeeperError, isError: true);
                  return;
                }
                Navigator.of(context).pop();
                _showLoadingDialog(context);
                try {
                  await salesUseCases.initiateSupply(order, preparer, _selectedStorekeeper!);
                  Navigator.of(context).pop();
                  _showSnackBar(context, appLocalizations.supplyInitiatedSuccessfully);
                } catch (e) {
                  Navigator.of(context).pop();
                  _showSnackBar(context, '${appLocalizations.errorInitiatingSupply}: ${e.toString()}', isError: true);
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
        title: Text(appLocalizations.approveMoldTasks, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(
          '${appLocalizations.confirmApproveMoldTasks}: "${order.customerName}"؟\n\n${appLocalizations.thisActionWillCreateProductionOrder}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
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
              Navigator.of(ctx).pop();
              _showLoadingDialog(context);
              try {
                await useCases.approveMoldTasks(order, supervisor);
                await productionUseCases.createProductionOrdersFromSalesOrder(order, supervisor);
                Navigator.of(context).pop();
                _showSnackBar(context, appLocalizations.moldTasksApprovedSuccessfully);
              } catch (e) {
                Navigator.of(context).pop();
                _showSnackBar(context, '${appLocalizations.errorApprovingMoldTasks}: ${e.toString()}', isError: true);
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

  void _showMoldDocDialog(BuildContext context, SalesUseCases useCases, AppLocalizations appLocalizations, SalesOrderModel order) {
    final TextEditingController notesController = TextEditingController(text: order.moldInstallationNotes);
    List<XFile> pickedImages = [];
    if (order.moldInstallationImages.isNotEmpty) {
      pickedImages.addAll(order.moldInstallationImages.map((url) => XFile(url)));
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.moldInstallationDocumentation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.enterNotes,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.primary),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 20),
                Text(appLocalizations.addImages, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final image = await _picker.pickImage(source: ImageSource.camera);
                          if (image != null) {
                            setState(() {
                              pickedImages.add(image);
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: Text(appLocalizations.camera),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final images = await _picker.pickMultiImage();
                          if (images != null && images.isNotEmpty) {
                            setState(() {
                              pickedImages.addAll(images);
                            });
                          }
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
                const SizedBox(height: 20),
                pickedImages.isEmpty
                    ? Text(appLocalizations.noImagesSelected, style: TextStyle(color: Colors.grey[600], fontSize: 15), textAlign: TextAlign.center)
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: pickedImages.length,
                  itemBuilder: (context, index) {
                    final imageFile = pickedImages[index];
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageFile.path.startsWith('http')
                              ? Image.network(imageFile.path, width: 120, height: 120, fit: BoxFit.cover)
                              : Image.file(File(imageFile.path), width: 120, height: 120, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                pickedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: Text(appLocalizations.save),
              onPressed: () async {
                Navigator.of(context).pop();
                _showLoadingDialog(context);
                try {
                  await useCases.addMoldInstallationDocs(
                    order: order,
                    notes: notesController.text.trim(),
                    // Filter out network URLs if you only want to upload new files
                    attachments: pickedImages.where((xfile) => !xfile.path.startsWith('http')).map((e) => File(e.path)).toList(),
                  );
                  Navigator.of(context).pop();
                  _showSnackBar(context, appLocalizations.documentationSavedSuccessfully);
                } catch (e) {
                  Navigator.of(context).pop();
                  _showSnackBar(context, '${appLocalizations.errorSavingDocumentation}: ${e.toString()}', isError: true);
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

  void _showWarehouseDocDialog(BuildContext context, SalesUseCases useCases, AppLocalizations appLocalizations, SalesOrderModel order, UserModel storekeeper) {
    final TextEditingController notesController = TextEditingController(text: order.warehouseNotes);
    List<XFile> pickedImages = [];
    if (order.warehouseImages.isNotEmpty) {
      pickedImages.addAll(order.warehouseImages.map((url) => XFile(url)));
    }

    DateTime? selectedDeliveryTime = order.deliveryTime?.toDate();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.warehouseDocumentation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.enterNotes,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.primary),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 20),
                Text(appLocalizations.addImages, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final image = await _picker.pickImage(source: ImageSource.camera);
                          if (image != null) {
                            setState(() {
                              pickedImages.add(image);
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: Text(appLocalizations.camera),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final images = await _picker.pickMultiImage();
                          if (images != null && images.isNotEmpty) {
                            setState(() {
                              pickedImages.addAll(images);
                            });
                          }
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
                const SizedBox(height: 20),
                pickedImages.isEmpty
                    ? Text(appLocalizations.noImagesSelected, style: TextStyle(color: Colors.grey[600], fontSize: 15), textAlign: TextAlign.center)
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: pickedImages.length,
                  itemBuilder: (context, index) {
                    final imageFile = pickedImages[index];
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageFile.path.startsWith('http')
                              ? Image.network(imageFile.path, width: 120, height: 120, fit: BoxFit.cover)
                              : Image.file(File(imageFile.path), width: 120, height: 120, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                pickedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(appLocalizations.selectDeliveryTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
                const SizedBox(height: 12),
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
                        ? appLocalizations.selectDeliveryDateAndTime
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
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_to_mobile),
              label: Text(appLocalizations.sendToProduction),
              onPressed: () async {
                Navigator.of(context).pop();
                _showLoadingDialog(context);
                try {
                  await useCases.documentWarehouseSupply(
                    order: order,
                    storekeeper: storekeeper,
                    notes: notesController.text.trim(),
                    attachments: pickedImages.where((xfile) => !xfile.path.startsWith('http')).map((e) => File(e.path)).toList(),
                    deliveryTime: selectedDeliveryTime,
                  );
                  Navigator.of(context).pop();
                  _showSnackBar(context, appLocalizations.warehouseSupplyDocumentedSuccessfully);
                } catch (e) {
                  Navigator.of(context).pop();
                  _showSnackBar(context, '${appLocalizations.errorDocumentingWarehouseSupply}: ${e.toString()}', isError: true);
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
          title: Text(appLocalizations.confirmDeletion, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18)),
          content: Text(
            '${appLocalizations.confirmDeleteOrder}: "$customerName"?\n\n${appLocalizations.thisActionCannotBeUndone}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
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
                Navigator.of(dialogContext).pop();
                _showLoadingDialog(context);
                try {
                  await useCases.deleteSalesOrder(orderId);
                  Navigator.of(context).pop();
                  _showSnackBar(context, appLocalizations.orderDeletedSuccessfully); // Confirmation snackbar
                } catch (e) {
                  Navigator.of(context).pop();
                  _showSnackBar(context, '${appLocalizations.errorDeletingOrder}: ${e.toString()}', isError: true);
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

  // Helper method to show loading dialog
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  // Helper method to show SnackBar
  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating, // For a more modern look
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}