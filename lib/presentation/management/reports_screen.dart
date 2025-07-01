import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.reports),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'هنا عرض التقارير والإحصائيات',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
