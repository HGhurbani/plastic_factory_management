import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/return_request_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/returns_usecases.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final useCases = Provider.of<ReturnsUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.returns),
        centerTitle: true,
        actions: [
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () =>
                  _showAddDialog(context, useCases, currentUser, appLocalizations),
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
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(r.requesterName, textDirection: TextDirection.rtl),
                  subtitle:
                      Text(r.status.toArabicString(), textDirection: TextDirection.rtl),
                  onTap: () => _showRequestDialog(
                      context, r, useCases, currentUser, appLocalizations),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

void _showAddDialog(BuildContext context, ReturnsUseCases useCases, UserModel user,
    AppLocalizations appLocalizations) {
  final reasonController = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(appLocalizations.addReturnRequest, textAlign: TextAlign.center),
      content: TextField(
        controller: reasonController,
        decoration: InputDecoration(labelText: appLocalizations.reason),
        textDirection: TextDirection.rtl,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(appLocalizations.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            final request = ReturnRequestModel(
              id: '',
              requesterUid: user.uid,
              requesterName: user.name,
              reason: reasonController.text,
              status: ReturnRequestStatus.pendingOperations,
              createdAt: Timestamp.now(),
            );
            await useCases.createReturnRequest(request);
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
    ReturnRequestModel request,
    ReturnsUseCases useCases,
    UserModel? user,
    AppLocalizations appLocalizations) {
  final driverController = TextEditingController();
  final warehouseController = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(appLocalizations.returnRequests, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${appLocalizations.reason}: ${request.reason}',
              textDirection: TextDirection.rtl),
          const SizedBox(height: 8),
          Text(appLocalizations.statusColon +
              request.status.toArabicString(),
              textDirection: TextDirection.rtl),
          if (request.status == ReturnRequestStatus.awaitingPickup) ...[
            const SizedBox(height: 8),
            TextField(
              controller: driverController,
              decoration: InputDecoration(labelText: appLocalizations.driver),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: warehouseController,
              decoration:
                  InputDecoration(labelText: appLocalizations.warehouseKeeper),
              textDirection: TextDirection.rtl,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(appLocalizations.cancel),
        ),
        if (user != null &&
            user.userRoleEnum == UserRole.operationsOfficer &&
            request.status == ReturnRequestStatus.pendingOperations)
          TextButton(
            onPressed: () async {
              await useCases.approveOperations(request, user.uid, user.name);
              Navigator.pop(context);
            },
            child: Text(appLocalizations.operationsReview),
          ),
        if (user != null &&
            user.userRoleEnum == UserRole.salesRepresentative &&
            request.status == ReturnRequestStatus.pendingSalesApproval)
          TextButton(
            onPressed: () async {
              await useCases.approveSales(request, user.uid, user.name);
              Navigator.pop(context);
            },
            child: Text(appLocalizations.salesApproval),
          ),
        if (user != null &&
            request.status == ReturnRequestStatus.awaitingPickup)
          TextButton(
            onPressed: () async {
              await useCases.schedulePickup(request,
                  driverName: driverController.text,
                  warehouseKeeperName: warehouseController.text);
              Navigator.pop(context);
            },
            child: Text(appLocalizations.schedulePickup),
          ),
        if (user != null &&
            request.status == ReturnRequestStatus.awaitingPickup)
          TextButton(
            onPressed: () async {
              await useCases.markCompleted(request);
              Navigator.pop(context);
            },
            child: Text(appLocalizations.complete),
          ),
      ],
    ),
  );
}
