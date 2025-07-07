import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import '../../data/models/factory_element_model.dart';
import '../../core/constants/app_enums.dart';

class FactoryElementsScreen extends StatefulWidget {
  const FactoryElementsScreen({super.key});

  @override
  State<FactoryElementsScreen> createState() => _FactoryElementsScreenState();
}

class _FactoryElementsScreenState extends State<FactoryElementsScreen> {
  final List<FactoryElementModel> _elements = [];

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
                setState(() {
                  _elements.add(FactoryElementModel(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                    type: finalType,
                    name: name,
                  ));
                });
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
      body: _elements.isEmpty
          ? Center(child: Text(loc.noData))
          : ListView.builder(
              itemCount: _elements.length,
              itemBuilder: (context, index) {
                final element = _elements[index];
                return ListTile(
                  leading: const Icon(Icons.widgets_outlined),
                  title: Text(element.name,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right),
                  subtitle: Text(element.type,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right),
                );
              },
            ),
    );
  }
}
