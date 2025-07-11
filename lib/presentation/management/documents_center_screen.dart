import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class DocumentsCenterScreen extends StatelessWidget {
  const DocumentsCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.documentCenter),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'هنا مركز الوثائق والسياسات',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
