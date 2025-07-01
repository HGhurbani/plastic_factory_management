import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/spare_part_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class InventoryAdjustmentScreen extends StatefulWidget {
  const InventoryAdjustmentScreen({Key? key}) : super(key: key);

  @override
  State<InventoryAdjustmentScreen> createState() => _InventoryAdjustmentScreenState();
}

class _InventoryAdjustmentScreenState extends State<InventoryAdjustmentScreen> {
  InventoryItemType? _type;
  String? _itemId;
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
            DropdownButtonFormField<InventoryItemType>(
              decoration: InputDecoration(labelText: appLocalizations.selectInventoryType),
              value: _type,
              items: const [
                DropdownMenuItem(
                  value: InventoryItemType.rawMaterial,
                  child: Text('مواد خام', textDirection: TextDirection.rtl),
                ),
                DropdownMenuItem(
                  value: InventoryItemType.finishedProduct,
                  child: Text('منتج تام', textDirection: TextDirection.rtl),
                ),
                DropdownMenuItem(
                  value: InventoryItemType.sparePart,
                  child: Text('قطع غيار', textDirection: TextDirection.rtl),
                ),
              ],
              onChanged: (value) => setState(() {
                _type = value;
                _itemId = null;
              }),
            ),
            const SizedBox(height: 16),
            if (_type != null)
              StreamBuilder<List<dynamic>>(
                stream: _itemsStream(useCases, _type!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: appLocalizations.selectItem),
                    value: _itemId,
                    items: snapshot.data!
                        .map<DropdownMenuItem<String>>(
                          (e) => DropdownMenuItem(value: _getId(e), child: Text(_getName(e))),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _itemId = value),
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
                      await useCases.adjustInventory(itemId: _itemId!, type: _type!, delta: qty);
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

  Stream<List<dynamic>> _itemsStream(InventoryUseCases useCases, InventoryItemType type) {
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
    if (item is RawMaterialModel) return item.name;
    if (item is ProductModel) return item.name;
    if (item is SparePartModel) return item.name;
    return '';
  }
}
