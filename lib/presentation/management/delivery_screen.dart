import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.delivery),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'هنا إدارة عمليات التوصيل',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
