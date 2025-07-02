import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class InventoryAddItemScreen extends StatefulWidget {
  const InventoryAddItemScreen({Key? key}) : super(key: key);

  @override
  State<InventoryAddItemScreen> createState() => _InventoryAddItemScreenState();
}

class _InventoryAddItemScreenState extends State<InventoryAddItemScreen> {
  InventoryItemType? _type;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _packagingController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _packagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final useCases = Provider.of<InventoryUseCases>(context);
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
                  _codeController.clear();
                  _nameController.clear();
                  _unitController.clear();
                  _packagingController.clear();
                }),
              ),
              const SizedBox(height: 16),
              if (_type != null) ..._buildFields(appLocalizations),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _canSubmit()
                    ? () async {
                        switch (_type) {
                          case InventoryItemType.rawMaterial:
                            await useCases.addRawMaterial(
                              code: _codeController.text,
                              name: _nameController.text,
                              unit: _unitController.text,
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
                              packagingType: _packagingController.text,
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
                              unit: _unitController.text,
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
    if (_type == null) return false;
    if (_codeController.text.isEmpty || _nameController.text.isEmpty) return false;
    if (_type == InventoryItemType.finishedProduct) {
      return true;
    }
    return _unitController.text.isNotEmpty;
  }

  List<Widget> _buildFields(AppLocalizations loc) {
    switch (_type) {
      case InventoryItemType.rawMaterial:
        return [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: loc.materialName),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _codeController,
            decoration: InputDecoration(labelText: loc.materialCode),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _unitController,
            decoration: InputDecoration(labelText: loc.unitOfMeasurement),
            onChanged: (_) => setState(() {}),
          ),
        ];
      case InventoryItemType.finishedProduct:
        return [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: loc.productName),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _codeController,
            decoration: InputDecoration(labelText: loc.productCode),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _packagingController,
            decoration: InputDecoration(labelText: loc.packagingType),
            onChanged: (_) => setState(() {}),
          ),
        ];
      case InventoryItemType.sparePart:
        return [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: loc.materialName),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _codeController,
            decoration: InputDecoration(labelText: loc.materialCode),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _unitController,
            decoration: InputDecoration(labelText: loc.unitOfMeasurement),
            onChanged: (_) => setState(() {}),
          ),
        ];
      default:
        return [];
    }
  }
}
