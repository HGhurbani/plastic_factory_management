import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.returns),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'هنا يمكن إدارة عمليات المرتجع',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
