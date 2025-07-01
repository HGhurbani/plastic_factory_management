import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class ProcurementScreen extends StatelessWidget {
  const ProcurementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.procurement),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'هنا إدارة عمليات المشتريات',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
