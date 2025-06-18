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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'المهام المتاحة:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('فحص المنتجات النهائية', textDirection: TextDirection.rtl),
          ),
          ListTile(
            leading: Icon(Icons.photo),
            title: Text('إرفاق صور وملاحظات توثيقية', textDirection: TextDirection.rtl),
          ),
          ListTile(
            leading: Icon(Icons.thumb_up_alt_outlined),
            title: Text('الموافقة على السليم ورفض المعيب', textDirection: TextDirection.rtl),
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              'هنا يمكن لمراقب الجودة تسجيل فحوصات الجودة ومراجعة النتائج.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}
