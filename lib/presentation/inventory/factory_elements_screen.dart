import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import '../../data/models/factory_element_model.dart';
import '../../core/constants/app_enums.dart';
import '../../theme/app_colors.dart';
import '../../domain/usecases/factory_element_usecases.dart';

class FactoryElementsScreen extends StatefulWidget {
  const FactoryElementsScreen({super.key});

  @override
  State<FactoryElementsScreen> createState() => _FactoryElementsScreenState();
}

class _FactoryElementsScreenState extends State<FactoryElementsScreen> {

  FactoryElementType _typeFromArabic(String type) {
    switch (type) {
      case 'مواد خام':
        return FactoryElementType.rawMaterial;
      case 'ملونات':
        return FactoryElementType.colorant;
      case 'مدخلات إنتاج':
        return FactoryElementType.productionInput;
      default:
        return FactoryElementType.custom;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'مواد خام':
        return Icons.inventory_2_outlined;
      case 'ملونات':
        return Icons.color_lens_outlined;
      case 'مدخلات إنتاج':
        return Icons.input_outlined;
      default:
        return Icons.widgets_outlined;
    }
  }

  Future<void> _deleteElement(String id) async {
    final useCases =
        Provider.of<FactoryElementUseCases>(context, listen: false);
    await useCases.deleteElement(id);
  }

  void _showEditDialog(FactoryElementModel element) {
    FactoryElementType type = _typeFromArabic(element.type);
    final nameController = TextEditingController(text: element.name);
    final customTypeController = TextEditingController(
      text: type == FactoryElementType.custom ? element.type : '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.edit,
              textAlign: TextAlign.center),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FactoryElementType>(
                  value: type,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.elementType),
                  items: const [
                    DropdownMenuItem(
                      value: FactoryElementType.rawMaterial,
                      child:
                          Text('مواد خام', textDirection: TextDirection.rtl),
                    ),
                    DropdownMenuItem(
                      value: FactoryElementType.colorant,
                      child: Text('ملونات', textDirection: TextDirection.rtl),
                    ),
                    DropdownMenuItem(
                      value: FactoryElementType.productionInput,
                      child:
                          Text('مدخلات إنتاج', textDirection: TextDirection.rtl),
                    ),
                    DropdownMenuItem(
                      value: FactoryElementType.custom,
                      child: Text('مخصص', textDirection: TextDirection.rtl),
                    ),
                  ],
                  onChanged: (val) => setState(() => type = val!),
                ),
                const SizedBox(height: 12),
                if (type == FactoryElementType.custom)
                  TextField(
                    controller: customTypeController,
                    decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.enterElementType),
                    textDirection: TextDirection.rtl,
                  ),
                if (type == FactoryElementType.custom)
                  const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.elementName),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final finalType = type == FactoryElementType.custom
                    ? customTypeController.text.trim()
                    : type.toArabicString();
                if (name.isEmpty || finalType.isEmpty) return;
                final useCases =
                    Provider.of<FactoryElementUseCases>(context, listen: false);
                useCases.updateElement(
                    id: element.id, type: finalType, name: name);
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog() {
    FactoryElementType type = FactoryElementType.rawMaterial;
    final nameController = TextEditingController();
    final customTypeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.addFactoryElement,
              textAlign: TextAlign.center),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FactoryElementType>(
                  value: type,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.elementType),
                  items: const [
                    DropdownMenuItem(
                      value: FactoryElementType.rawMaterial,
                      child:
                          Text('مواد خام', textDirection: TextDirection.rtl),
                    ),
                    DropdownMenuItem(
                      value: FactoryElementType.colorant,
                      child: Text('ملونات', textDirection: TextDirection.rtl),
                    ),
                    DropdownMenuItem(
                      value: FactoryElementType.productionInput,
                      child:
                          Text('مدخلات إنتاج', textDirection: TextDirection.rtl),
                    ),
                    DropdownMenuItem(
                      value: FactoryElementType.custom,
                      child: Text('مخصص', textDirection: TextDirection.rtl),
                    ),
                  ],
                  onChanged: (val) => setState(() => type = val!),
                ),
                const SizedBox(height: 12),
                if (type == FactoryElementType.custom)
                  TextField(
                    controller: customTypeController,
                    decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.enterElementType),
                    textDirection: TextDirection.rtl,
                  ),
                if (type == FactoryElementType.custom)
                  const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.elementName),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final finalType = type == FactoryElementType.custom
                    ? customTypeController.text.trim()
                    : type.toArabicString();
                if (name.isEmpty || finalType.isEmpty) return;
                final useCases =
                    Provider.of<FactoryElementUseCases>(context, listen: false);
                useCases.addElement(type: finalType, name: name);
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.add),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.factoryElements),
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: loc.addFactoryElement,
          ),
        ],
      ),
      body: StreamBuilder<List<FactoryElementModel>>( 
          stream:
              Provider.of<FactoryElementUseCases>(context).getElements(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final elements = snapshot.data!;
            if (elements.isEmpty) {
              return Center(child: Text(loc.noData));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: elements.length,
              itemBuilder: (context, index) {
                final element = elements[index];
                return Card(
                  color: AppColors.lightGrey,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: Icon(_iconForType(element.type),
                        color: AppColors.primary),
                    title: Text(element.name,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right),
                    subtitle: Text(element.type,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: loc.edit,
                          onPressed: () => _showEditDialog(element),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: loc.delete,
                          onPressed: () => _deleteElement(element.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
    );
  }
}
