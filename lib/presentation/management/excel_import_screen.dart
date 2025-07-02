import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class ExcelImportScreen extends StatelessWidget {
  const ExcelImportScreen({super.key});

  Future<void> _pickAndImport(BuildContext context, String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);
      // TODO: Parse [excel] according to [type] and save to Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fileImportedSuccessfully)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.excelImportTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(loc.importRawMaterials, textDirection: TextDirection.rtl),
            onTap: () => _pickAndImport(context, 'raw'),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(loc.importCustomers, textDirection: TextDirection.rtl),
            onTap: () => _pickAndImport(context, 'customers'),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(loc.importProducts, textDirection: TextDirection.rtl),
            onTap: () => _pickAndImport(context, 'products'),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(loc.importTemplates, textDirection: TextDirection.rtl),
            onTap: () => _pickAndImport(context, 'templates'),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(loc.importMachines, textDirection: TextDirection.rtl),
            onTap: () => _pickAndImport(context, 'machines'),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(loc.importOperators, textDirection: TextDirection.rtl),
            onTap: () => _pickAndImport(context, 'operators'),
          ),
        ],
      ),
    );
  }
}
