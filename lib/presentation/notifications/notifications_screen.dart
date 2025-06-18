import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/notification_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/notification_usecases.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final currentUser = Provider.of<UserModel?>(context);
    final notificationUseCases = Provider.of<NotificationUseCases>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.notifications),
        centerTitle: true,
      ),
      body: currentUser == null
          ? Center(child: Text(appLocalizations.noNotifications))
          : StreamBuilder<List<AppNotification>>(
              stream:
                  notificationUseCases.getUserNotifications(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      appLocalizations.noNotifications,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  );
                }

                final notifications = snapshot.data!;
                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return ListTile(
                      title: Text(notif.title, textDirection: TextDirection.rtl),
                      subtitle:
                          Text(notif.message, textDirection: TextDirection.rtl),
                      trailing: notif.read
                          ? null
                          : TextButton(
                              onPressed: () => notificationUseCases
                                  .markAsRead(notif.id),
                              child: Text(appLocalizations.markAsRead),
                            ),
                    );
                  },
                );
              },
            ),
    );
  }
}
