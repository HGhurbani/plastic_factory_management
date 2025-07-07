import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/factory_element_usecases.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'package:plastic_factory_management/data/models/template_model.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';

class AddEditTemplateScreen extends StatefulWidget {
  final TemplateModel? template;
  const AddEditTemplateScreen({super.key, this.template});

  @override
  State<AddEditTemplateScreen> createState() => _AddEditTemplateScreenState();
}

class _AddEditTemplateScreenState extends State<AddEditTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _costController;

  Map<String, String> _rawMaterialNames = {};
  List<TemplateMaterial> _materials = [];
  List<String> _colors = [];
  List<String> _productionInputs = [];

  List<String> _availableColors = [];
  List<String> _availableInputs = [];

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _codeController = TextEditingController(text: t?.code);
    _nameController = TextEditingController(text: t?.name);
    _weightController = TextEditingController(text: t?.weight.toString());
    _costController = TextEditingController(text: t?.costPerHour.toString());
    _materials = List<TemplateMaterial>.from(t?.materialsUsed ?? []);
    _colors = List<String>.from(t?.colors ?? []);
    _productionInputs = List<String>.from(t?.productionInputs ?? []);
    _fetchRawMaterialNames();
    _fetchFactoryElements();
  }

  Future<void> _fetchRawMaterialNames() async {
    final inventoryUseCases =
        Provider.of<InventoryUseCases>(context, listen: false);
    final materials = await inventoryUseCases.getRawMaterials().first;
    if (mounted) {
      setState(() {
        _rawMaterialNames = {for (var m in materials) m.id: m.name};
      });
    }
  }

  Future<void> _fetchFactoryElements() async {
    final useCases = Provider.of<FactoryElementUseCases>(context, listen: false);
    final elements = await useCases.getElements().first;
    if (mounted) {
      setState(() {
        _availableColors = elements
            .where((e) => e.type ==
                FactoryElementType.colorant.toArabicString())
            .map((e) => e.name)
            .toList();
        _availableInputs = elements
            .where((e) => e.type ==
                FactoryElementType.productionInput.toArabicString())
            .map((e) => e.name)
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final useCases = Provider.of<InventoryUseCases>(context);
    final isEditing = widget.template != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? loc.editTemplate : loc.addTemplate),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: loc.templateCode,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.qr_code),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? loc.fieldRequired : null,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: loc.templateName,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? loc.fieldRequired : null,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    labelText: loc.templateWeight,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.scale),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value!.isEmpty) return loc.fieldRequired;
                    if (double.tryParse(value) == null) return loc.invalidNumber;
                    return null;
                  },
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _costController,
                  decoration: InputDecoration(
                    labelText: loc.templateHourlyCost,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value!.isEmpty) return loc.fieldRequired;
                    if (double.tryParse(value) == null) return loc.invalidNumber;
                    return null;
                  },
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(loc.materialsUsed,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Column(
                  children: _materials.asMap().entries.map((entry) {
                    final i = entry.key;
                    final m = entry.value;
                    final name =
                        _rawMaterialNames[m.materialId] ?? loc.unknownMaterial;
                    return ListTile(
                      title: Text('$name - ${m.ratio}'),
                      leading: IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () => setState(() {
                          _materials.removeAt(i);
                        }),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final newMat = await _showAddMaterialDialog(
                        context,
                        useCases,
                        loc,
                        _materials.map((e) => e.materialId).toList());
                    if (newMat != null) {
                      setState(() {
                        _materials.add(newMat);
                      });
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(loc.addMaterial),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(loc.colors,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    ..._colors.map((c) => Chip(
                          label: Text(c),
                          onDeleted: () {
                            setState(() {
                              _colors.remove(c);
                            });
                          },
                        )),
                    ActionChip(
                      avatar: const Icon(Icons.add_circle_outline,
                          color: AppColors.primary),
                      label: Text(loc.add),
                      onPressed: () async {
                        final newColor = await _showOptionsDialog(
                            context, loc.colors, _availableColors);
                        if (newColor != null && newColor.isNotEmpty &&
                            !_colors.contains(newColor)) {
                          setState(() {
                            _colors.add(newColor);
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(loc.productionInputs,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    ..._productionInputs.map((p) => Chip(
                          label: Text(p),
                          onDeleted: () {
                            setState(() {
                              _productionInputs.remove(p);
                            });
                          },
                        )),
                    ActionChip(
                      avatar: const Icon(Icons.add_circle_outline,
                          color: AppColors.primary),
                      label: Text(loc.add),
                      onPressed: () async {
                        final newInput = await _showOptionsDialog(
                            context, loc.productionInputs, _availableInputs);
                        if (newInput != null &&
                            !_productionInputs.contains(newInput)) {
                          setState(() {
                            _productionInputs.add(newInput);
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(isEditing ? Icons.save : Icons.add,
                      color: Colors.white),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        if (isEditing) {
                          await useCases.updateTemplate(
                            id: widget.template!.id,
                            code: _codeController.text,
                            name: _nameController.text,
                            weight: double.parse(_weightController.text),
                            costPerHour: double.parse(_costController.text),
                            materialsUsed: _materials,
                            colors: _colors,
                            productionInputs: _productionInputs,
                          );
                        } else {
                          await useCases.addTemplate(
                            code: _codeController.text,
                            name: _nameController.text,
                            weight: double.parse(_weightController.text),
                            costPerHour: double.parse(_costController.text),
                            materialsUsed: _materials,
                            colors: _colors,
                            productionInputs: _productionInputs,
                          );
                        }
                        if (mounted) Navigator.of(context).pop();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${loc.somethingWentWrong}: $e')),
                        );
                      }
                    }
                  },
                  label: Text(isEditing ? loc.save : loc.add),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<TemplateMaterial?> _showAddMaterialDialog(
    BuildContext context,
    InventoryUseCases useCases,
    AppLocalizations loc,
    List<String> existingIds,
  ) async {
    final ratioController = TextEditingController();
    RawMaterialModel? selected;
    final formKey = GlobalKey<FormState>();
    String? unit;
    return showDialog<TemplateMaterial>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(loc.addMaterial, textAlign: TextAlign.center),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<List<RawMaterialModel>>(
                        stream: useCases.getRawMaterials(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox();
                          }
                          final materials = snapshot.data!
                              .where((m) => !existingIds.contains(m.id))
                              .toList();
                          return DropdownButtonFormField<RawMaterialModel>(
                            value: selected,
                            decoration: InputDecoration(
                              labelText: loc.rawMaterial,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.inventory_2),
                            ),
                            isExpanded: true,
                            items: materials
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m.name),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                selected = val;
                                unit = val?.unit;
                              });
                            },
                            validator: (val) =>
                                val == null ? loc.fieldRequired : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: ratioController,
                        decoration: InputDecoration(
                          labelText: loc.percentage,
                          border: const OutlineInputBorder(),
                          suffixText: unit ?? '',
                          prefixIcon: const Icon(Icons.percent),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value!.isEmpty) return loc.fieldRequired;
                          if (double.tryParse(value) == null)
                            return loc.invalidNumber;
                          return null;
                        },
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(loc.cancel),
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    if (formKey.currentState!.validate() && selected != null) {
                      Navigator.pop(
                        dialogContext,
                        TemplateMaterial(
                          materialId: selected!.id,
                          ratio: double.parse(ratioController.text),
                        ),
                      );
                    }
                  },
                  label: Text(loc.add),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<String?> _showTextInputDialog(BuildContext context, String title) {
    final controller = TextEditingController();
    final loc = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title, textAlign: TextAlign.center),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: title,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.text_fields),
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(loc.cancel),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
                label: Text(loc.add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _showOptionsDialog(
      BuildContext context, String title, List<String> options) {
    final loc = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title, textAlign: TextAlign.center),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: options
                    .map(
                      (o) => ListTile(
                        title: Text(o, textDirection: TextDirection.rtl),
                        onTap: () => Navigator.pop(dialogContext, o),
                      ),
                    )
                    .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(loc.cancel),
              ),
            ],
          ),
        );
      },
    );
  }
}
