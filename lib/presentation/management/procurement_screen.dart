import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/purchase_request_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/procurement_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/spare_part_model.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';

class ProcurementScreen extends StatelessWidget {
  const ProcurementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final useCases = Provider.of<ProcurementUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.procurement),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: currentUser == null
                ? null
                : () => _showAddDialog(context, useCases, currentUser, appLocalizations),
            tooltip: appLocalizations.addPurchaseRequest,
          ),
        ],
      ),
      body: StreamBuilder<List<PurchaseRequestModel>>(
        stream: useCases.getPurchaseRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add_check_circle_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(appLocalizations.noData, style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                ],
              ),
            );
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
                  onTap: () => _showRequestDialog(context, r, useCases, currentUser, appLocalizations),
                  borderRadius: BorderRadius.circular(12),
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
                                _statusToArabic(r.status, context),
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
                        _buildInfoRow(appLocalizations.orderDate,
                            intl.DateFormat('yyyy-MM-dd').format(r.createdAt.toDate()),
                            icon: Icons.calendar_today_outlined),
                        _buildInfoRow(appLocalizations.quantity, r.items.length.toString(), icon: Icons.list_alt),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: currentUser == null
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddDialog(context, useCases, currentUser, appLocalizations),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              tooltip: appLocalizations.addPurchaseRequest,
              child: const Icon(Icons.add),
            ),
    );
  }

  void _showAddDialog(BuildContext context, ProcurementUseCases useCases, UserModel user,
      AppLocalizations appLocalizations) {
    final inventoryUseCases = Provider.of<InventoryUseCases>(context, listen: false);
    InventoryItemType? type;
    dynamic selectedItem;
    final qtyController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(appLocalizations.addPurchaseRequest, textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<InventoryItemType>(
                    value: type,
                    decoration: InputDecoration(
                      labelText: appLocalizations.selectInventoryType,
                      border: const OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: InventoryItemType.rawMaterial,
                        child: Text('المادة الأولية', textDirection: TextDirection.rtl),
                      ),
                      DropdownMenuItem(
                        value: InventoryItemType.finishedProduct,
                        child: Text('الإنتاج التام', textDirection: TextDirection.rtl),
                      ),
                      DropdownMenuItem(
                        value: InventoryItemType.sparePart,
                        child: Text('قطع الغيار', textDirection: TextDirection.rtl),
                      ),
                    ],
                    onChanged: (val) => setState(() {
                      type = val;
                      selectedItem = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  if (type != null)
                    StreamBuilder<List<dynamic>>(
                      stream: _itemsStream(inventoryUseCases, type!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final items = snapshot.data!;
                        if (items.isEmpty) {
                          return Text(appLocalizations.noData);
                        }
                        return DropdownButtonFormField<dynamic>(
                          value: selectedItem,
                          decoration: InputDecoration(
                            labelText: appLocalizations.selectItem,
                            border: const OutlineInputBorder(),
                          ),
                          items: items
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(_getName(e), textDirection: TextDirection.rtl),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setState(() => selectedItem = val),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: qtyController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.quantity,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.confirmation_num_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceAround,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(appLocalizations.cancel),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              ElevatedButton.icon(
                onPressed: selectedItem == null
                    ? null
                    : () async {
                        final quantity = int.tryParse(qtyController.text) ?? 1;
                        final item = PurchaseRequestItem(
                          itemId: _getId(selectedItem),
                          itemName: _getName(selectedItem),
                          quantity: quantity,
                        );
                        final request = PurchaseRequestModel(
                          id: '',
                          requesterUid: user.uid,
                          requesterName: user.name,
                          items: [item],
                          totalAmount: 0,
                          status: PurchaseRequestStatus.awaitingApproval,
                          createdAt: Timestamp.now(),
                        );
                        await useCases.createPurchaseRequest(request);
                        Navigator.pop(context);
                      },
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(appLocalizations.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRequestDialog(
      BuildContext context,
      PurchaseRequestModel request,
      ProcurementUseCases useCases,
      UserModel? user,
      AppLocalizations appLocalizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(appLocalizations.purchaseRequests, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...request.items.map((e) => Text('${e.itemName} x${e.quantity}', textDirection: TextDirection.rtl)),
            const SizedBox(height: 8),
            Text('${appLocalizations.statusColon}${_statusToArabic(request.status, context)}', textDirection: TextDirection.rtl),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLocalizations.cancel),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          ),
          if (user != null &&
              user.userRoleEnum == UserRole.accountant &&
              request.status == PurchaseRequestStatus.awaitingApproval)
            ElevatedButton.icon(
              onPressed: () async {
                await useCases.approveByAccountant(
                    request, user.uid, user.name);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 20),
              label: Text(appLocalizations.approve),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          if (user != null &&
              user.userRoleEnum == UserRole.accountant &&
              request.status == PurchaseRequestStatus.awaitingApproval)
            ElevatedButton.icon(
              onPressed: () async {
                await useCases.rejectByAccountant(
                    request, user.uid, user.name);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.cancel_outlined,
                  color: Colors.white, size: 20),
              label: Text(appLocalizations.reject),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          if (user != null &&
              user.userRoleEnum == UserRole.inventoryManager &&
              request.status == PurchaseRequestStatus.awaitingWarehouse)
            ElevatedButton.icon(
              onPressed: () async {
                await useCases.receiveByWarehouse(
                    request, user.uid, user.name);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.inventory_2_outlined,
                  color: Colors.white, size: 20),
              label: Text(appLocalizations.complete),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  String _statusToArabic(PurchaseRequestStatus status, BuildContext context) {
    switch (status) {
      case PurchaseRequestStatus.awaitingApproval:
        return AppLocalizations.of(context)!.pendingApproval;
      case PurchaseRequestStatus.awaitingWarehouse:
        return AppLocalizations.of(context)!.warehouseKeeper;
      case PurchaseRequestStatus.rejected:
        return AppLocalizations.of(context)!.rejected;
      case PurchaseRequestStatus.completed:
        return 'مكتمل';
    }
  }

  Color _getStatusColor(PurchaseRequestStatus status) {
    switch (status) {
      case PurchaseRequestStatus.awaitingApproval:
        return AppColors.accentOrange;
      case PurchaseRequestStatus.awaitingWarehouse:
        return Colors.blue.shade700;
      case PurchaseRequestStatus.rejected:
        return Colors.red.shade700;
      case PurchaseRequestStatus.completed:
        return Colors.green.shade700;
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

  Stream<List<dynamic>> _itemsStream(
      InventoryUseCases useCases, InventoryItemType type) {
    switch (type) {
      case InventoryItemType.rawMaterial:
        return useCases.getRawMaterials();
      case InventoryItemType.finishedProduct:
        return useCases.getProducts();
      case InventoryItemType.sparePart:
        return useCases.getSpareParts();
    }
  }

  String _getId(dynamic item) {
    if (item is RawMaterialModel) return item.id;
    if (item is ProductModel) return item.id;
    if (item is SparePartModel) return item.id;
    return '';
  }

  String _getName(dynamic item) {
    if (item is RawMaterialModel) return '${item.code} - ${item.name}';
    if (item is ProductModel) return '${item.productCode} - ${item.name}';
    if (item is SparePartModel) return '${item.code} - ${item.name}';
    return '';
  }
}
