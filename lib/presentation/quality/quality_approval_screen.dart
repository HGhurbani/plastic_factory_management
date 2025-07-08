import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_enums.dart';
import '../../data/models/production_order_model.dart';
import '../../data/models/sales_order_model.dart';
import '../../data/models/user_model.dart';
import '../../domain/usecases/production_order_usecases.dart';
import '../../domain/usecases/quality_usecases.dart';
import '../../domain/usecases/sales_usecases.dart';
import '../../l10n/app_localizations.dart';

class QualityApprovalScreen extends StatefulWidget {
  const QualityApprovalScreen({super.key});

  @override
  State<QualityApprovalScreen> createState() => _QualityApprovalScreenState();
}

class _QualityApprovalScreenState extends State<QualityApprovalScreen> {
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  OrderType? _orderType;
  SalesOrderModel? _salesOrder;
  ProductionOrderModel? _productionOrder;

  @override
  void dispose() {
    _orderIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrder() async {
    final id = _orderIdController.text.trim();
    if (id.isEmpty || _orderType == null) return;
    if (_orderType == OrderType.sales) {
      final salesUseCases = Provider.of<SalesUseCases>(context, listen: false);
      final order = await salesUseCases.getSalesOrderById(id);
      setState(() {
        _salesOrder = order;
        _productionOrder = null;
      });
    } else {
      final prodUseCases =
          Provider.of<ProductionOrderUseCases>(context, listen: false);
      final order = await prodUseCases.getProductionOrderById(id);
      setState(() {
        _productionOrder = order;
        _salesOrder = null;
      });
    }
  }

  Future<void> _submit(bool approved) async {
    final id = _orderIdController.text.trim();
    if (id.isEmpty || _orderType == null) return;
    final currentUser = Provider.of<UserModel?>(context, listen: false);
    if (currentUser == null) return;

    final qualityUseCases = Provider.of<QualityUseCases>(context, listen: false);
    await qualityUseCases.recordQualityCheck(
      orderId: id,
      orderType: _orderType!,
      status:
          approved ? QualityApprovalStatus.approved : QualityApprovalStatus.rejected,
      qualityInspectorUid: currentUser.uid,
      qualityInspectorName: currentUser.name,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (approved) {
      if (_salesOrder != null) {
        final salesUseCases = Provider.of<SalesUseCases>(context, listen: false);
        await salesUseCases.markOrderDelivered(_salesOrder!);
      }
      if (_productionOrder != null) {
        final prodUseCases =
            Provider.of<ProductionOrderUseCases>(context, listen: false);
        await prodUseCases.markOrderDelivered(_productionOrder!, currentUser);
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.approveRejectOrder),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<OrderType>(
                value: _orderType,
                decoration: InputDecoration(labelText: loc.orderType),
                items: [
                  DropdownMenuItem(
                    value: OrderType.sales,
                    child: Text(loc.salesOrder),
                  ),
                  DropdownMenuItem(
                    value: OrderType.production,
                    child: Text(loc.productionOrder),
                  ),
                ],
                onChanged: (val) => setState(() => _orderType = val),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _orderIdController,
                decoration: InputDecoration(labelText: loc.orderId),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchOrder,
                child: Text(loc.fetchOrder),
              ),
              if (_salesOrder != null || _productionOrder != null) ...[
                const SizedBox(height: 12),
                _buildOrderDetails(loc),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _notesController,
                decoration: InputDecoration(labelText: loc.approvalNotes),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submit(true),
                      child: Text(loc.approve),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submit(false),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text(loc.reject),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetails(AppLocalizations loc) {
    if (_salesOrder != null) {
      final o = _salesOrder!;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${loc.salesOrder} #${o.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${loc.customerName}: ${o.customerName}'),
              Text('${loc.statusColon} ${o.status.toArabicString()}'),
            ],
          ),
        ),
      );
    }
    if (_productionOrder != null) {
      final o = _productionOrder!;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${loc.productionOrder} #${o.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (o.machineName != null)
                Text('${loc.machineName}: ${o.machineName}'),
              Text('${loc.productName}: ${o.productName}'),
              Text('${loc.statusColon} ${o.status.toArabicString()}'),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
