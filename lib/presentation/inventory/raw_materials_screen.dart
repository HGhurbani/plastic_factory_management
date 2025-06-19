// plastic_factory_management/lib/presentation/inventory/raw_materials_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';

class RawMaterialsScreen extends StatefulWidget {
  @override
  _RawMaterialsScreenState createState() => _RawMaterialsScreenState();
}

class _RawMaterialsScreenState extends State<RawMaterialsScreen> {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final inventoryUseCases = Provider.of<InventoryUseCases>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.rawMaterials),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddEditMaterialDialog(context, inventoryUseCases, appLocalizations);
            },
            tooltip: appLocalizations.addRawMaterial, // أضف هذا النص في ARB
          ),
        ],
      ),
      body: StreamBuilder<List<RawMaterialModel>>(
        stream: inventoryUseCases.getRawMaterials(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل المواد الأولية: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('لا توجد مواد أولية لعرضها.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final material = snapshot.data![index];
              final isBelowMin = material.currentQuantity <= material.minStockLevel;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                color: isBelowMin ? Colors.red[50] : null, // لون خلفية إذا كان أقل من الحد الأدنى
                child: ListTile(
                  title: Text(
                    material.name,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${appLocalizations.currentQuantity}: ${material.currentQuantity} ${material.unit}',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(color: isBelowMin ? Colors.red[700] : null),
                      ),
                      Text(
                        '${appLocalizations.minStockLevel}: ${material.minStockLevel} ${material.unit}',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                      if (isBelowMin)
                        Text(
                          appLocalizations.lowStockWarning, // أضف هذا النص في ARB
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () {
                          _showAddEditMaterialDialog(context, inventoryUseCases, appLocalizations, material: material);
                        },
                        tooltip: appLocalizations.edit, // أضف هذا النص في ARB
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmationDialog(context, inventoryUseCases, appLocalizations, material.id, material.name);
                        },
                        tooltip: appLocalizations.delete, // أضف هذا النص في ARB
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
    final _nameController = TextEditingController(text: material?.name);
    final _quantityController = TextEditingController(text: material?.currentQuantity.toString());
    final _unitController = TextEditingController(text: material?.unit);
    final _minStockController = TextEditingController(text: material?.minStockLevel.toString());
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? appLocalizations.editRawMaterial : appLocalizations.addRawMaterial),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: appLocalizations.materialName, border: OutlineInputBorder()), // أضف هذا النص في ARB
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(labelText: appLocalizations.currentQuantity, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return appLocalizations.fieldRequired;
                      if (double.tryParse(value) == null) return appLocalizations.invalidNumber; // أضف هذا النص في ARB
                      return null;
                    },
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _unitController,
                    decoration: InputDecoration(labelText: appLocalizations.unitOfMeasurement, border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _minStockController,
                    decoration: InputDecoration(labelText: appLocalizations.minStockLevel, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return appLocalizations.fieldRequired;
                      if (double.tryParse(value) == null) return appLocalizations.invalidNumber;
                      return null;
                    },
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
            ElevatedButton(
              child: Text(isEditing ? appLocalizations.save : appLocalizations.add), // أضف هذا النص في ARB
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    if (isEditing) {
                      await useCases.updateRawMaterial(
                        id: material!.id,
                        name: _nameController.text,
                        currentQuantity: double.parse(_quantityController.text),
                        unit: _unitController.text,
                        minStockLevel: double.parse(_minStockController.text),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.materialUpdatedSuccessfully))); // أضف هذا النص في ARB
                    } else {
                      await useCases.addRawMaterial(
                        name: _nameController.text,
                        currentQuantity: double.parse(_quantityController.text),
                        unit: _unitController.text,
                        minStockLevel: double.parse(_minStockController.text),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.materialAddedSuccessfully))); // أضف هذا النص في ARB
                    }
                    Navigator.of(dialogContext).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorSavingMaterial}: $e'))); // أضف هذا النص في ARB
                  }
                }
              },
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
          title: Text(appLocalizations.confirmDeletion), // أضف هذا النص في ARB
          content: Text('${appLocalizations.confirmDeleteMaterial}: "$materialName"؟'), // أضف هذا النص في ARB
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text(appLocalizations.delete),
              onPressed: () async {
                try {
                  await useCases.deleteRawMaterial(materialId);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.materialDeletedSuccessfully))); // أضف هذا النص في ARB
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorDeletingMaterial}: $e'))); // أضف هذا النص في ARB
                }
              },
            ),
          ],
        );
      },
    );
  }
}