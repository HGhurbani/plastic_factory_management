import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class FinishedProductsScreen extends StatefulWidget {
  const FinishedProductsScreen({super.key});

  @override
  State<FinishedProductsScreen> createState() => _FinishedProductsScreenState();
}

class _FinishedProductsScreenState extends State<FinishedProductsScreen> {
  Map<String, String> _productNames = {};

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final useCases = Provider.of<InventoryUseCases>(context, listen: false);
    final products = await useCases.getProducts().first;
    if (mounted) {
      setState(() {
        _productNames = {for (var p in products) p.id: p.name};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final useCases = Provider.of<InventoryUseCases>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(app.finishedProducts),
        centerTitle: true,
      ),
      body: StreamBuilder<List<InventoryBalanceModel>>(
        stream: useCases.getInventoryBalances(InventoryItemType.finishedProduct),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final balances = snapshot.data!;
          if (balances.isEmpty) {
            return Center(child: Text(app.noData));
          }
          return ListView.builder(
            itemCount: balances.length,
            itemBuilder: (context, index) {
              final bal = balances[index];
              final name = _productNames[bal.itemId] ?? bal.itemId;
              final belowMin = bal.quantity <= bal.minQuantity;
              return ListTile(
                leading: Icon(
                  belowMin ? Icons.warning : Icons.inventory_2,
                  color: belowMin ? Colors.red : null,
                ),
                title: Text(name, textDirection: TextDirection.rtl),
                subtitle: Text(
                  '${bal.quantity} / ${bal.minQuantity}',
                  textDirection: TextDirection.rtl,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
