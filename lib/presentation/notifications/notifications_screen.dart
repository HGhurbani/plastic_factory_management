import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.notifications),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          appLocalizations.noNotifications,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
