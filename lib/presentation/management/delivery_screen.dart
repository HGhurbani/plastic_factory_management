import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/domain/usecases/sales_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/user_usecases.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final salesUseCases = Provider.of<SalesUseCases>(context);
    final userUseCases = Provider.of<UserUseCases>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.delivery),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showScheduleDialog(context, salesUseCases, userUseCases, order, appLocalizations),
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
                                const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  order.customerName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.secondary),
                              onPressed: () => _showScheduleDialog(context, salesUseCases, userUseCases, order, appLocalizations),
                              tooltip: appLocalizations.scheduleDelivery,
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        _buildInfoRow(
                          appLocalizations.expectedDeliveryTime,
                          intl.DateFormat('yyyy-MM-dd HH:mm').format(order.deliveryTime!.toDate()),
                          icon: Icons.calendar_today_outlined,
                        ),
                        if (order.driverName != null)
                          _buildInfoRow(
                            appLocalizations.driver,
                            '${order.driverName} - ${order.transportMode?.toArabicString() ?? ''}',
                            icon: Icons.drive_eta_outlined,
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
    );
  }

  void _showScheduleDialog(BuildContext context, SalesUseCases salesUseCases,
      UserUseCases userUseCases, SalesOrderModel order, AppLocalizations loc) {
    DateTime selectedTime = order.deliveryTime?.toDate() ?? DateTime.now();
    TransportMode mode = order.transportMode ?? TransportMode.company;
    UserModel? selectedDriver;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(loc.scheduleDelivery, textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedTime),
                        );
                        if (time != null) {
                          setState(() {
                            selectedTime = DateTime(
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
                    child: Text(intl.DateFormat('yyyy-MM-dd HH:mm')
                        .format(selectedTime)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<TransportMode>(
                    value: mode,
                    onChanged: (val) => setState(() => mode = val!),
                    items: TransportMode.values
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child:
                                  Text(e.toArabicString(), textDirection: TextDirection.rtl),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<UserModel>>(
                    future: userUseCases.getUsersByRole(UserRole.driver),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const SizedBox();
                      }
                      final drivers = snap.data!;
                      return DropdownButton<UserModel>(
                        value: drivers.firstWhere(
                            (d) => d.uid == (selectedDriver?.uid ?? order.driverUid),
                            orElse: () => drivers.isNotEmpty ? drivers.first : UserModel(uid: '', email: '', name: '', role: UserRole.driver.toFirestoreString(), createdAt: Timestamp.now())),
                        hint: Text(loc.driver),
                        onChanged: (val) => setState(() => selectedDriver = val),
                        items: drivers
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d.name, textDirection: TextDirection.rtl),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  await salesUseCases.scheduleDelivery(
                    order: order,
                    deliveryTime: selectedTime,
                    transportMode: mode,
                    driverUid: selectedDriver?.uid,
                    driverName: selectedDriver?.name,
                  );
                  Navigator.pop(context);
                },
                child: Text(loc.save),
              ),
            ],
          );
        });
      },
    );
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
}
