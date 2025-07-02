import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/spare_part_request_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/financial_usecases.dart';

class SparePartRequestsScreen extends StatelessWidget {
  const SparePartRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final financialUseCases = Provider.of<FinancialUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.sparePartRequests),
      ),
      body: StreamBuilder<List<SparePartRequestModel>>(
        stream: financialUseCases.getSparePartRequests(),
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
                  onTap: () => _showRequestDialog(context, r, financialUseCases, currentUser, appLocalizations),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRequestDialog(
      BuildContext context,
      SparePartRequestModel request,
      FinancialUseCases useCases,
      UserModel? currentUser,
      AppLocalizations appLocalizations) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(appLocalizations.sparePartRequestDetails, textAlign: TextAlign.center),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...request.items.map((e) => Text('${e.partName} x${e.quantity}', textDirection: TextDirection.rtl)),
                const SizedBox(height: 8),
                Text('${appLocalizations.totalAmount}: ${request.totalAmount}', textDirection: TextDirection.rtl),
                const SizedBox(height: 8),
                Text(appLocalizations.statusColon + request.status.name,
                    textDirection: TextDirection.rtl),
                if (request.rejectionReason != null)
                  Text('${appLocalizations.rejectionReason}: ${request.rejectionReason}', textDirection: TextDirection.rtl),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.cancel),
            ),
            if (currentUser != null && request.status == SparePartRequestStatus.pendingApproval)
              TextButton(
                onPressed: () async {
                  await useCases.approveSparePartRequest(request, currentUser.uid, currentUser.name);
                  Navigator.pop(context);
                },
                child: Text(appLocalizations.approve),
              ),
            if (currentUser != null && request.status == SparePartRequestStatus.pendingApproval)
              TextButton(
                onPressed: () async {
                  final reasonController = TextEditingController();
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(appLocalizations.rejectRequest, textAlign: TextAlign.center),
                      content: TextField(
                        controller: reasonController,
                        decoration: InputDecoration(labelText: appLocalizations.reason),
                        textDirection: TextDirection.rtl,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(appLocalizations.cancel),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(appLocalizations.reject),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await useCases.rejectSparePartRequest(
                        request, currentUser.uid, currentUser.name, reasonController.text);
                    Navigator.pop(context);
                  }
                },
                child: Text(appLocalizations.reject),
              ),
          ],
        );
      },
    );
  }
}
