import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/factory_element_usecases.dart';
import 'package:plastic_factory_management/data/models/factory_element_model.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class InventoryAddItemScreen extends StatefulWidget {
  const InventoryAddItemScreen({Key? key}) : super(key: key);

  @override
  State<InventoryAddItemScreen> createState() => _InventoryAddItemScreenState();
}

class _InventoryAddItemScreenState extends State<InventoryAddItemScreen> {
  String? _type;
  String? _itemId;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final useCases = Provider.of<InventoryUseCases>(context);
    final elementUseCases = Provider.of<FactoryElementUseCases>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.addInventoryItem),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
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
                    decoration: InputDecoration(labelText: appLocalizations.selectInventoryType),
                    value: _type,
                    items: types
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t, textDirection: TextDirection.rtl),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() {
                      _type = val;
                      _itemId = null;
                      _nameController.clear();
                      _codeController.clear();
                    }),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_type != null) ..._buildFields(appLocalizations, elementUseCases),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _canSubmit()
                    ? () async {
                        switch (_mapType(_type!)) {
                          case InventoryItemType.rawMaterial:
                            await useCases.addRawMaterial(
                              code: _codeController.text,
                              name: _nameController.text,
                              unit: '',
                            );
                            break;
                          case InventoryItemType.finishedProduct:
                            await useCases.addProduct(
                              productCode: _codeController.text,
                              name: _nameController.text,
                              description: null,
                              billOfMaterials: const [],
                              colors: const [],
                              additives: const [],
                              packagingType: '',
                              requiresPackaging: false,
                              requiresSticker: false,
                              productType: 'single',
                              expectedProductionTimePerUnit: 0,
                            );
                            break;
                          case InventoryItemType.sparePart:
                            await useCases.addSparePart(
                              code: _codeController.text,
                              name: _nameController.text,
                              unit: '',
                            );
                            break;
                          default:
                            return;
                        }
                        if (mounted) Navigator.of(context).pop();
                      }
                    : null,
                child: Text(appLocalizations.add),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSubmit() {
    if (_type == null || _itemId == null) return false;
    if (_codeController.text.isEmpty || _nameController.text.isEmpty) return false;
    return true;
  }

  List<Widget> _buildFields(AppLocalizations loc, FactoryElementUseCases elementUseCases) {
    final typeEnum = _mapType(_type!);
    return [
      StreamBuilder<List<FactoryElementModel>>(
        stream: _itemsStream(elementUseCases, _type!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: loc.selectItem),
            value: _itemId,
            items: items
                .map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name, textDirection: TextDirection.rtl),
                    ))
                .toList(),
            onChanged: (val) => setState(() {
              _itemId = val;
              final itm = items.firstWhere((e) => e.id == val);
              _nameController.text = itm.name;
            }),
          );
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _codeController,
        decoration: InputDecoration(
          labelText: typeEnum == InventoryItemType.finishedProduct
              ? loc.productCode
              : loc.materialCode,
        ),
        onChanged: (_) => setState(() {}),
      ),
      // Unit field removed as per new requirements
    ];
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
