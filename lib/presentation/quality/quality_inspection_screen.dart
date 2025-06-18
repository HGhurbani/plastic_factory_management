// plastic_factory_management/lib/presentation/quality/quality_inspection_screen.dart

import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class QualityInspectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.qualityModule),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'هنا يمكن لمراقب الجودة تسجيل فحوصات الجودة ومراجعة النتائج.',
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
