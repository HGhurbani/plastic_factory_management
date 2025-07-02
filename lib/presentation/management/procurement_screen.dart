import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/purchase_request_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/procurement_usecases.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: currentUser == null
                ? null
                : () => _showAddDialog(context, useCases, currentUser, appLocalizations),
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
            return Center(child: Text(appLocalizations.noData));
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final r = requests[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                    '${r.requesterName} - ${intl.DateFormat.yMd().format(r.createdAt.toDate())}',
                    textDirection: TextDirection.rtl,
                  ),
                  subtitle: Text(r.status.name, textDirection: TextDirection.rtl),
                  onTap: () =>
                      _showRequestDialog(context, r, useCases, currentUser, appLocalizations),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, ProcurementUseCases useCases, UserModel user,
      AppLocalizations appLocalizations) {
    final descController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.addPurchaseRequest, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: appLocalizations.description),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyController,
              decoration: InputDecoration(labelText: appLocalizations.quantity),
              keyboardType: TextInputType.number,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLocalizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = int.tryParse(qtyController.text) ?? 1;
              final item = PurchaseRequestItem(
                itemId: '',
                itemName: descController.text,
                quantity: quantity,
              );
              final request = PurchaseRequestModel(
                id: '',
                requesterUid: user.uid,
                requesterName: user.name,
                items: [item],
                totalAmount: 0,
                status: PurchaseRequestStatus.pendingInventory,
                createdAt: Timestamp.now(),
              );
              await useCases.createPurchaseRequest(request);
              Navigator.pop(context);
            },
            child: Text(appLocalizations.save),
          ),
        ],
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
        title: Text(appLocalizations.purchaseRequests, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...request.items
                .map((e) => Text('${e.itemName} x${e.quantity}', textDirection: TextDirection.rtl)),
            const SizedBox(height: 8),
            Text(appLocalizations.statusColon + request.status.name,
                textDirection: TextDirection.rtl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLocalizations.cancel),
          ),
          if (user != null && request.status == PurchaseRequestStatus.pendingInventory)
            TextButton(
              onPressed: () async {
                await useCases.sendToSupplier(request,
                    supplierId: 'default', supplierName: 'default');
                Navigator.pop(context);
              },
              child: Text(appLocalizations.sendToSuppliers),
            ),
          if (user != null && request.status == PurchaseRequestStatus.awaitingFinance)
            TextButton(
              onPressed: () async {
                await useCases.approveFinance(request, user.uid, user.name);
                Navigator.pop(context);
              },
              child: Text(appLocalizations.financialApproval),
            ),
        ],
      ),
    );
  }
}
