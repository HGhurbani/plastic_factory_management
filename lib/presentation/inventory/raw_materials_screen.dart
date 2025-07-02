// plastic_factory_management/lib/presentation/inventory/raw_materials_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/spare_part_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'package:plastic_factory_management/presentation/routes/app_router.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';

import '../../data/models/inventory_balance_model.dart';

class RawMaterialsScreen extends StatefulWidget {
  const RawMaterialsScreen({super.key});

  @override
  _RawMaterialsScreenState createState() => _RawMaterialsScreenState();
}

class _RawMaterialsScreenState extends State<RawMaterialsScreen> {
  InventoryItemType _selectedType = InventoryItemType.rawMaterial;
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final inventoryUseCases = Provider.of<InventoryUseCases>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.rawMaterials),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedType != InventoryItemType.finishedProduct)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.inventoryAddItemRoute);
              },
              tooltip: appLocalizations.addInventoryItem,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<InventoryItemType>(
              value: _selectedType,
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
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
            ),
          ),
          Expanded(
            child: StreamBuilder<List<dynamic>>(
              stream: _itemsStream(inventoryUseCases),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            appLocalizations.errorLoadingMaterials,
                            style: const TextStyle(fontSize: 18, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${appLocalizations.technicalDetails}: ${snapshot.error}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(appLocalizations.noData));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    return _buildListItem(item, inventoryUseCases, appLocalizations);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedType == InventoryItemType.finishedProduct
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.inventoryAddItemRoute);
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              tooltip: appLocalizations.addInventoryItem,
              child: const Icon(Icons.add),
            ),
    );
  }

  Stream<List<dynamic>> _itemsStream(InventoryUseCases useCases) {
    switch (_selectedType) {
      case InventoryItemType.rawMaterial:
        return useCases.getRawMaterials();
      case InventoryItemType.finishedProduct:
        return useCases.getProducts();
      case InventoryItemType.sparePart:
        return useCases.getSpareParts();
    }
  }

  Widget _buildListItem(
      dynamic item, InventoryUseCases useCases, AppLocalizations loc) {
    if (_selectedType == InventoryItemType.finishedProduct) {
      final product = item as ProductModel;
      return ListTile(
        leading: const Icon(Icons.inventory_2),
        title: Text('${product.productCode} - ${product.name}',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    final code = _selectedType == InventoryItemType.rawMaterial
        ? (item as RawMaterialModel).code
        : (item as SparePartModel).code;
    final name = _selectedType == InventoryItemType.rawMaterial
        ? (item as RawMaterialModel).name
        : (item as SparePartModel).name;
    final id = _selectedType == InventoryItemType.rawMaterial
        ? (item as RawMaterialModel).id
        : (item as SparePartModel).id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
          title: Text(
            '$code - $name',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: () {
                  if (_selectedType == InventoryItemType.rawMaterial) {
                    _showAddEditMaterialDialog(context, useCases, loc,
                        material: item as RawMaterialModel);
                  } else {
                    _showAddEditSparePartDialog(context, useCases, loc,
                        part: item as SparePartModel);
                  }
                },
                tooltip: loc.edit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  if (_selectedType == InventoryItemType.rawMaterial) {
                    _showDeleteConfirmationDialog(context, useCases, loc, id, name);
                  } else {
                    _showDeletePartConfirmationDialog(context, useCases, loc, id, name);
                  }
                },
                tooltip: loc.delete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditMaterialDialog(
      BuildContext context,
      InventoryUseCases useCases,
      AppLocalizations appLocalizations, {
        RawMaterialModel? material,
      }) {
    final isEditing = material != null;
    final _codeController = TextEditingController(text: material?.code);
    final _nameController = TextEditingController(text: material?.name);
    final _unitController = TextEditingController(text: material?.unit);
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            isEditing ? appLocalizations.editRawMaterial : appLocalizations.addRawMaterial,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.materialName,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.article), // Icon for name
                    ),
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.materialCode,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.tag),
                    ),
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _unitController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.unitOfMeasurement,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.straighten), // Icon for unit
                    ),
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]), // Styled cancel button
            ),
            ElevatedButton.icon( // Changed to ElevatedButton.icon
              icon: Icon(isEditing ? Icons.save : Icons.add, color: Colors.white,),
              label: Text(isEditing ? appLocalizations.save : appLocalizations.add),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    if (isEditing) {
                      await useCases.updateRawMaterial(
                        id: material!.id,
                        code: _codeController.text,
                        name: _nameController.text,
                        unit: _unitController.text,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(appLocalizations.materialUpdatedSuccessfully)));
                    } else {
                      await useCases.addRawMaterial(
                        code: _codeController.text,
                        name: _nameController.text,
                        unit: _unitController.text,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(appLocalizations.materialAddedSuccessfully)));
                    }
                    Navigator.of(dialogContext).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${appLocalizations.errorSavingMaterial}: ${e.toString()}')), // Use e.toString() for better error message
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context,
      InventoryUseCases useCases,
      AppLocalizations appLocalizations,
      String materialId,
      String materialName,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.confirmDeletion, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(
            '${appLocalizations.confirmDeleteMaterial}: "$materialName"?\n\n${appLocalizations.thisActionCannotBeUndone}', // Added warning
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround, // Distribute buttons
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon( // Changed to ElevatedButton.icon
              icon: const Icon(Icons.delete_forever), // More impactful icon
              label: Text(appLocalizations.delete),
              onPressed: () async {
                try {
                  await useCases.deleteRawMaterial(materialId);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations.materialDeletedSuccessfully)));
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorDeletingMaterial}: ${e.toString()}')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddEditSparePartDialog(
      BuildContext context,
      InventoryUseCases useCases,
      AppLocalizations appLocalizations, {
        SparePartModel? part,
      }) {
    final isEditing = part != null;
    final _codeController = TextEditingController(text: part?.code);
    final _nameController = TextEditingController(text: part?.name);
    final _unitController = TextEditingController(text: part?.unit);
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            isEditing ? appLocalizations.editRawMaterial : appLocalizations.addRawMaterial,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.materialName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.materialCode,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _unitController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.unitOfMeasurement,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton.icon(
              icon: Icon(isEditing ? Icons.save : Icons.add, color: Colors.white),
              label: Text(isEditing ? appLocalizations.save : appLocalizations.add),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (isEditing) {
                    await useCases.updateSparePart(
                      id: part!.id,
                      code: _codeController.text,
                      name: _nameController.text,
                      unit: _unitController.text,
                    );
                  } else {
                    await useCases.addSparePart(
                      code: _codeController.text,
                      name: _nameController.text,
                      unit: _unitController.text,
                    );
                  }
                  if (context.mounted) Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeletePartConfirmationDialog(
      BuildContext context,
      InventoryUseCases useCases,
      AppLocalizations appLocalizations,
      String partId,
      String partName,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.confirmDeletion,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(
            '${appLocalizations.confirmDeleteMaterial}: "$partName"?\n\n${appLocalizations.thisActionCannotBeUndone}',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: Text(appLocalizations.delete),
              onPressed: () async {
                await useCases.deleteSparePart(partId);
                if (context.mounted) Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}