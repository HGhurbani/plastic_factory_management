import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class ExcelColumnMappingDialog extends StatefulWidget {
  final List<String> fields;
  final List<String> columns;
  const ExcelColumnMappingDialog({
    required this.fields,
    required this.columns,
    super.key,
  });

  @override
  State<ExcelColumnMappingDialog> createState() => _ExcelColumnMappingDialogState();
}

class _ExcelColumnMappingDialogState extends State<ExcelColumnMappingDialog> {
  late Map<String, String?> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {for (final f in widget.fields) f: null};
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.mapColumnsTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.fields.map((f) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: loc.selectColumnForField(f)),
                value: _selected[f],
                items: widget.columns
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selected[f] = v),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _selected.values.any((v) => v == null)
              ? null
              : () => Navigator.pop(context, _selected.cast<String, String>()),
          child: Text(loc.importAction),
        ),
      ],
    );
  }
}
