import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/return_request_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/domain/usecases/returns_usecases.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';
import 'package:intl/intl.dart' as intl;
import 'package:plastic_factory_management/domain/usecases/sales_usecases.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final useCases = Provider.of<ReturnsUseCases>(context);
    final salesUseCases = Provider.of<SalesUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.returns),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              onPressed: () =>
                  _showAddDialog(context, useCases, salesUseCases, currentUser, appLocalizations),
              tooltip: appLocalizations.addReturnRequest,
            ),
        ],
      ),
      body: StreamBuilder<List<ReturnRequestModel>>(
        stream: useCases.getReturnRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return Center(child: Text(appLocalizations.noData));
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final r = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showRequestDialog(
                      context, r, useCases, currentUser, appLocalizations),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                const Icon(Icons.person_outline, color: AppColors.primary, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  r.requesterName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(r.status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                r.status.toArabicString(),
                                style: TextStyle(
                                  color: _getStatusColor(r.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        _buildInfoRow(appLocalizations.orderId, r.salesOrderId, icon: Icons.confirmation_number_outlined),
                        _buildInfoRow(appLocalizations.reason, r.reason, icon: Icons.help_outline),
                        _buildInfoRow(appLocalizations.orderDate,
                            '${intl.DateFormat('yyyy-MM-dd').format(r.createdAt.toDate())}',
                            icon: Icons.calendar_today_outlined),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

void _showAddDialog(BuildContext context, ReturnsUseCases useCases,
    SalesUseCases salesUseCases, UserModel user, AppLocalizations appLocalizations) {
  final reasonController = TextEditingController();
  final orderIdController = TextEditingController();
  SalesOrderModel? fetchedOrder;
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            Text(appLocalizations.addReturnRequest, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: orderIdController,
                decoration: InputDecoration(
                  labelText: appLocalizations.orderId,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final id = orderIdController.text.trim();
                  if (id.isEmpty) return;
                  final order = await salesUseCases.getSalesOrderById(id);
                  setState(() => fetchedOrder = order);
                },
                icon: const Icon(Icons.search),
                label: Text(appLocalizations.fetchOrder),
              ),
              if (fetchedOrder != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(appLocalizations.customerName,
                    fetchedOrder!.customerName, icon: Icons.person),
                _buildInfoRow(appLocalizations.totalAmount,
                    '﷼${fetchedOrder!.totalAmount.toStringAsFixed(2)}',
                    icon: Icons.currency_exchange),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: appLocalizations.reason,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.help_outline),
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLocalizations.cancel),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () async {
              if (fetchedOrder == null) return;
              final request = ReturnRequestModel(
                id: '',
                requesterUid: user.uid,
                requesterName: user.name,
                salesOrderId: fetchedOrder!.id,
                reason: reasonController.text,
                status: ReturnRequestStatus.pendingOperations,
                createdAt: Timestamp.now(),
              );
              await useCases.createReturnRequest(request);
              Navigator.pop(context);
            },
            label: Text(appLocalizations.save),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showRequestDialog(
    BuildContext context,
    ReturnRequestModel request,
    ReturnsUseCases useCases,
    UserModel? user,
    AppLocalizations appLocalizations) {
  final driverController = TextEditingController();
  final warehouseController = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(appLocalizations.returnRequests, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(appLocalizations.orderId, request.salesOrderId,
              icon: Icons.confirmation_number_outlined),
          _buildInfoRow(appLocalizations.reason, request.reason, icon: Icons.help_outline),
          _buildInfoRow(appLocalizations.status, request.status.toArabicString(), icon: Icons.info_outline),
          if (request.status == ReturnRequestStatus.awaitingPickup) ...[
            const SizedBox(height: 8),
            TextField(
              controller: driverController,
              decoration: InputDecoration(
                labelText: appLocalizations.driver,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.drive_eta_outlined),
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: warehouseController,
              decoration: InputDecoration(
                labelText: appLocalizations.warehouseKeeper,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.inventory_2_outlined),
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(appLocalizations.cancel),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
        ),
        if (user != null &&
            user.userRoleEnum == UserRole.operationsOfficer &&
            request.status == ReturnRequestStatus.pendingOperations)
          ElevatedButton.icon(
            icon: const Icon(Icons.check, color: Colors.white, size: 20),
            onPressed: () async {
              await useCases.approveOperations(request, user.uid, user.name);
              Navigator.pop(context);
            },
            label: Text(appLocalizations.operationsReview),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        if (user != null &&
            user.userRoleEnum == UserRole.salesRepresentative &&
            request.status == ReturnRequestStatus.pendingSalesApproval)
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            onPressed: () async {
              await useCases.approveSales(request, user.uid, user.name);
              Navigator.pop(context);
            },
            label: Text(appLocalizations.salesApproval),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        if (user != null &&
            request.status == ReturnRequestStatus.awaitingPickup)
          ElevatedButton.icon(
            icon: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 20),
            onPressed: () async {
              await useCases.schedulePickup(request,
                  driverName: driverController.text,
                  warehouseKeeperName: warehouseController.text);
              Navigator.pop(context);
            },
            label: Text(appLocalizations.schedulePickup),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        if (user != null &&
            request.status == ReturnRequestStatus.awaitingPickup)
          ElevatedButton.icon(
            icon: const Icon(Icons.done_all, color: Colors.white, size: 20),
            onPressed: () async {
              await useCases.markCompleted(request);
              Navigator.pop(context);
            },
            label: Text(appLocalizations.complete),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    ),
  );
}

Color _getStatusColor(ReturnRequestStatus status) {
  switch (status) {
    case ReturnRequestStatus.pendingOperations:
      return AppColors.accentOrange;
    case ReturnRequestStatus.pendingSalesApproval:
      return Colors.blue.shade700;
    case ReturnRequestStatus.awaitingPickup:
      return AppColors.secondary;
    case ReturnRequestStatus.completed:
      return Colors.green.shade700;
    default:
      return Colors.grey.shade600;
  }
}

Widget _buildInfoRow(String label, String value, {IconData? icon}) {
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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    ),
  );
}
