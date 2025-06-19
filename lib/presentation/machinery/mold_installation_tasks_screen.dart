import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/production_order_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/production_order_usecases.dart';
import 'package:plastic_factory_management/presentation/production/production_order_detail_screen.dart';

class MoldInstallationTasksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final productionUseCases = Provider.of<ProductionOrderUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(appLocalizations.moldInstallationTasks)),
        body: Center(child: Text(appLocalizations.errorLoadingUserData)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.moldInstallationTasks),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ProductionOrderModel>>(
        stream: productionUseCases.getOrdersAwaitingMoldInstallation(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(appLocalizations.noMoldInstallationOrders));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProductionOrderDetailScreen(order: order),
                    ));
                  },
                  title: Text(
                    '${appLocalizations.product}: ${order.productName}',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
