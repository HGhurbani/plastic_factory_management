// plastic_factory_management/lib/presentation/sales/sales_order_detail_page.dart

import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:intl/intl.dart' as intl;
import 'package:plastic_factory_management/core/constants/app_enums.dart'; // Import app_enums for SalesOrderStatusExtension
import 'package:plastic_factory_management/theme/app_colors.dart'; // Ensure this defines your app's color scheme
import 'package:plastic_factory_management/core/extensions/string_extensions.dart';
import 'package:provider/provider.dart';
import '../../data/models/user_model.dart';
import '../../data/models/shift_handover_model.dart';
import '../../domain/usecases/shift_handover_usecases.dart';
import '../../domain/usecases/sales_usecases.dart';
import '../../domain/usecases/user_usecases.dart';

class SalesOrderDetailPage extends StatefulWidget {
  final SalesOrderModel order;

  const SalesOrderDetailPage({Key? key, required this.order}) : super(key: key);

  @override
  State<SalesOrderDetailPage> createState() => _SalesOrderDetailPageState();
}

class _SalesOrderDetailPageState extends State<SalesOrderDetailPage> {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final currentUser = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${appLocalizations.salesOrder} #${widget.order.id.shortId()}...'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Directionality( // <-- إضافة هذا
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // يصبح الآن start هو اليمين
            children: [
              _buildInfoRow(appLocalizations.customerName, widget.order.customerName, icon: Icons.person),
              _buildInfoRow(appLocalizations.salesRepresentative, widget.order.salesRepresentativeName, icon: Icons.badge),
              _buildInfoRow(appLocalizations.totalAmount, '﷼${widget.order.totalAmount.toStringAsFixed(2)}', icon: Icons.currency_exchange, isBold: true, textColor: AppColors.primary),
              _buildInfoRow(appLocalizations.status, widget.order.status.toArabicString(), icon: Icons.info_outline, textColor: _getSalesOrderStatusColor(widget.order.status), isBold: true),
              _buildInfoRow(appLocalizations.orderDate, intl.DateFormat('yyyy-MM-dd HH:mm').format(widget.order.createdAt.toDate()), icon: Icons.date_range),
              const SizedBox(height: 16),
              Text(appLocalizations.orderItems,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  textAlign: TextAlign.right),
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.order.orderItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '${item.productName} - ${item.quantity} ${item.quantityUnit ?? appLocalizations.units} @ ﷼${item.unitPrice.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                  ),
                )).toList(),
              ),
              if (widget.order.customerSignatureUrl != null && widget.order.customerSignatureUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appLocalizations.customerSignature, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), textAlign: TextAlign.right),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.order.customerSignatureUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(appLocalizations.orderFlowDetails,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  textAlign: TextAlign.right),
              const Divider(),
              if (widget.order.approvedAt != null)
                _buildInfoRow(
                  appLocalizations.approvalTime,
                  '${intl.DateFormat('yyyy-MM-dd HH:mm').format(widget.order.approvedAt!.toDate())} ${appLocalizations.approvedBy} ${widget.order.approvedByName ?? appLocalizations.unknown}',
                  icon: Icons.check_circle_outline,
                ),
              if (widget.order.approvalNotes != null && widget.order.approvalNotes!.isNotEmpty)
                _buildInfoRow(appLocalizations.approvalNotes, widget.order.approvalNotes!, icon: Icons.notes),
              if (widget.order.operationsNotes != null && widget.order.operationsNotes!.isNotEmpty)
                _buildInfoRow(appLocalizations.operationsNotes, widget.order.operationsNotes!, icon: Icons.notes),
              if (widget.order.machineName != null && widget.order.machineName!.isNotEmpty)
                _buildInfoRow(appLocalizations.machine, widget.order.machineName!, icon: Icons.precision_manufacturing_outlined),
              if (widget.order.rejectionReason != null && widget.order.rejectionReason!.isNotEmpty)
                _buildInfoRow(appLocalizations.rejectionReason, widget.order.rejectionReason!, icon: Icons.cancel, textColor: Colors.red),
              if (widget.order.warehouseManagerName != null && widget.order.warehouseManagerName!.isNotEmpty)
                _buildInfoRow(appLocalizations.warehouseManager, widget.order.warehouseManagerName!, icon: Icons.warehouse),
              if (widget.order.warehouseNotes != null && widget.order.warehouseNotes!.isNotEmpty)
                _buildInfoRow(appLocalizations.warehouseNotes, widget.order.warehouseNotes!, icon: Icons.notes),
              if (widget.order.warehouseImages.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(appLocalizations.warehouseImages, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.right),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: widget.order.warehouseImages.map((e) => GestureDetector(
                    onTap: () => _showImagePreviewDialog(context, e),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(e, width: 80, height: 80, fit: BoxFit.cover),
                    ),
                  )).toList(),
                ),
              ],
              if (widget.order.deliveryTime != null)
                _buildInfoRow(appLocalizations.expectedDeliveryTime,
                    intl.DateFormat('yyyy-MM-dd HH:mm').format(widget.order.deliveryTime!.toDate()), icon: Icons.delivery_dining),
              if (widget.order.moldSupervisorName != null && widget.order.moldSupervisorName!.isNotEmpty)
                _buildInfoRow(appLocalizations.moldInstallationSupervisor, widget.order.moldSupervisorName!, icon: Icons.person_pin),
              if (widget.order.moldInstallationNotes != null && widget.order.moldInstallationNotes!.isNotEmpty)
                _buildInfoRow(appLocalizations.moldInstallationNotes, widget.order.moldInstallationNotes!, icon: Icons.notes),
              if (widget.order.moldInstallationImages.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(appLocalizations.moldInstallationImages, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.right),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: widget.order.moldInstallationImages.map((e) => GestureDetector(
                    onTap: () => _showImagePreviewDialog(context, e),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(e, width: 80, height: 80, fit: BoxFit.cover),
                    ),
                  )).toList(),
                ),
              ],
              if (widget.order.productionManagerName != null && widget.order.productionManagerName!.isNotEmpty)
                _buildInfoRow(appLocalizations.productionManager, widget.order.productionManagerName!, icon: Icons.engineering),
              if (widget.order.productionRejectionReason != null && widget.order.productionRejectionReason!.isNotEmpty)
                _buildInfoRow(appLocalizations.rejectionReason, widget.order.productionRejectionReason!, icon: Icons.cancel, textColor: Colors.red),

              if (widget.order.status == SalesOrderStatus.inProduction) ...[
                const SizedBox(height: 24),
                Text(appLocalizations.shiftHandoverHistory,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    textAlign: TextAlign.right),
                const SizedBox(height: 8),
                StreamBuilder<List<ShiftHandoverModel>>( 
                  stream: Provider.of<ShiftHandoverUseCases>(context)
                      .getHandoversForOrder(widget.order.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final handovers = snapshot.data!;
                    if (handovers.isEmpty) {
                      return Text(appLocalizations.noData);
                    }
                    return Column(
                      children: handovers.map((h) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              '${h.fromSupervisorName} ➜ ${h.toSupervisorName}',
                              textAlign: TextAlign.right,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${appLocalizations.meterReading}: ${h.meterReading}'),
                                if (h.notes != null && h.notes!.isNotEmpty)
                                  Text(h.notes!),
                                if (h.receivingMeterReading != null)
                                  Text('قراءة الاستلام: ${h.receivingMeterReading}'),
                                if (h.receivingNotes != null && h.receivingNotes!.isNotEmpty)
                                  Text(h.receivingNotes!),
                                Text(intl.DateFormat('yyyy-MM-dd HH:mm').format(h.createdAt.toDate())),
                                if (h.receivedAt != null)
                                  Text(intl.DateFormat('yyyy-MM-dd HH:mm').format(h.receivedAt!.toDate())),
                                if (h.receivedAt == null &&
                                    currentUser != null &&
                                    h.toSupervisorUid == currentUser.uid &&
                                    widget.order.shiftSupervisorUid == currentUser.uid)
                                  TextButton(
                                    onPressed: () => _showReceiveHandoverDialog(
                                        context, h, currentUser),
                                    child: Text(AppLocalizations.of(context)!.receiveOrder),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
              if (currentUser != null &&
                  currentUser.userRoleEnum == UserRole.productionShiftSupervisor &&
                  widget.order.status == SalesOrderStatus.inProduction &&
                  widget.order.shiftSupervisorUid == currentUser.uid)
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () => _showHandoverDialog(context, widget.order, currentUser),
                    child: Text(appLocalizations.shiftHandover),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSalesOrderStatusColor(SalesOrderStatus status) {
    switch (status) {
      case SalesOrderStatus.pendingApproval:
        return AppColors.accentOrange;
      case SalesOrderStatus.pendingFulfillment:
        return AppColors.secondary;
      case SalesOrderStatus.warehouseProcessing:
        return Colors.blue.shade700;
      case SalesOrderStatus.awaitingOperationsForward:
        return Colors.orange.shade700;
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
    final appLocalizations = AppLocalizations.of(context)!;
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
                              Text(appLocalizations.imageLoadError, style: TextStyle(color: Colors.white)),
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

  Future<void> _showHandoverDialog(
      BuildContext context, SalesOrderModel order, UserModel currentUser) async {
    final userUseCases = Provider.of<UserUseCases>(context, listen: false);
    final handoverUseCases =
        Provider.of<ShiftHandoverUseCases>(context, listen: false);
    final salesUseCases = Provider.of<SalesUseCases>(context, listen: false);
    final supervisors =
        await userUseCases.getUsersByRole(UserRole.productionShiftSupervisor);
    UserModel? selected;
    String? notes;
    double? meter;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.shiftHandover),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<UserModel>(
                      items: supervisors
                          .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                          .toList(),
                      onChanged: (val) => setState(() => selected = val),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.shiftSupervisor,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (v) => meter = double.tryParse(v),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.meterReading,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => notes = v,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.notes,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: selected == null || meter == null
                      ? null
                      : () async {
                          Navigator.of(dialogContext).pop();
                          await handoverUseCases.addHandover(
                            orderId: order.id,
                            fromSupervisor: currentUser,
                            toSupervisor: selected!,
                            meterReading: meter!,
                            notes: notes,
                          );
                          await salesUseCases.updateShiftSupervisor(order, selected!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.save)),
                          );
                        },
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showReceiveHandoverDialog(
      BuildContext context, ShiftHandoverModel handover, UserModel currentUser) async {
    String? notes;
    double? meter;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.receiveOrder),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (v) => meter = double.tryParse(v),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.meterReading,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) => notes = v,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.notes,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: meter == null
                      ? null
                      : () async {
                          Navigator.of(dialogContext).pop();
                          final useCases =
                              Provider.of<ShiftHandoverUseCases>(context, listen: false);
                          await useCases.receiveHandover(
                            handover: handover,
                            meterReading: meter!,
                            notes: notes,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.save)),
                          );
                        },
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );
      },
    );
  }
}