import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';
import 'package:plastic_factory_management/data/models/factory_element_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/factory_element_usecases.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class InventoryAdjustmentScreen extends StatefulWidget {
  const InventoryAdjustmentScreen({Key? key}) : super(key: key);

  @override
  State<InventoryAdjustmentScreen> createState() => _InventoryAdjustmentScreenState();
}

class _InventoryAdjustmentScreenState extends State<InventoryAdjustmentScreen> {
  String? _type;
  String? _itemId;
  String? _itemName;
  final TextEditingController _qtyController = TextEditingController();

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final useCases = Provider.of<InventoryUseCases>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.addInventoryEntry),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<List<FactoryElementModel>>( 
              stream: elementUseCases.getElements(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final types = snapshot.data!
                    .map((e) => e.type)
                    .toSet()
                    .toList();
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                      labelText: appLocalizations.selectInventoryType),
                  value: _type,
                  items: types
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, textDirection: TextDirection.rtl),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() {
                    _type = val;
                    _itemId = null;
                  }),
                );
              },
            ),
            const SizedBox(height: 16),
            if (_type != null)
              StreamBuilder<List<FactoryElementModel>>( 
                stream: _itemsStream(elementUseCases, _type!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: appLocalizations.selectItem),
                    value: _itemId,
                    items: items
                        .map<DropdownMenuItem<String>>(
                          (e) =>
                              DropdownMenuItem(value: e.id, child: Text(e.name)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _itemId = value;
                      final itm = items.firstWhere((e) => e.id == value);
                      _itemName = itm.name;
                    }),
                  );
                },
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: appLocalizations.quantity),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _type != null && _itemId != null && _qtyController.text.isNotEmpty
                  ? () async {
                      final qty = double.tryParse(_qtyController.text) ?? 0;
                      await useCases.adjustInventoryWithNotification(
                        itemId: _itemId!,
                        itemName: _itemName ?? '',
                        type: _mapType(_type!),
                        delta: qty,
                      );
                      if (mounted) Navigator.of(context).pop();
                    }
                  : null,
              child: Text(appLocalizations.save),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<FactoryElementModel>> _itemsStream(
      FactoryElementUseCases useCases, String type) {
    return useCases
        .getElements()
        .map((list) => list.where((e) => e.type == type).toList());
  }

  InventoryItemType _mapType(String type) {
    switch (type) {
      case 'مواد خام':
        return InventoryItemType.rawMaterial;
      case 'منتج تام':
        return InventoryItemType.finishedProduct;
      case 'قطع غيار':
        return InventoryItemType.sparePart;
      default:
        return InventoryItemType.rawMaterial;
    }
  }
}
