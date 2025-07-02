import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/domain/usecases/sales_usecases.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final salesUseCases = Provider.of<SalesUseCases>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.delivery),
        centerTitle: true,
      ),
      body: StreamBuilder<List<SalesOrderModel>>(
        stream: salesUseCases.getSalesOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${appLocalizations.errorLoadingSalesOrders}: ${snapshot.error}'));
          }
          final orders = snapshot.data!
              .where((o) => o.deliveryTime != null && o.status != SalesOrderStatus.fulfilled && o.status != SalesOrderStatus.canceled && o.status != SalesOrderStatus.rejected)
              .toList()
            ..sort((a, b) => a.deliveryTime!.compareTo(b.deliveryTime!));
          if (orders.isEmpty) {
            return Center(child: Text(appLocalizations.noSalesOrdersAvailable));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return ListTile(
                title: Text(order.customerName, textDirection: TextDirection.rtl),
                subtitle: Text(intl.DateFormat('yyyy-MM-dd HH:mm').format(order.deliveryTime!.toDate()), textDirection: TextDirection.rtl),
                trailing: Text(order.status.toArabicString(), textDirection: TextDirection.rtl),
              );
            },
          );
        },
      ),
    );
  }
}
