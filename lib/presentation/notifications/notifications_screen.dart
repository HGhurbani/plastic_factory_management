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
        backgroundColor: Theme.of(context).primaryColor, // Consistent theme color
        foregroundColor: Colors.white, // White text for better contrast
        elevation: 0, // No shadow for a cleaner look
      ),
      body: currentUser == null
          ? _buildNoUserPlaceholder(appLocalizations)
          : StreamBuilder<List<AppNotification>>(
        stream: notificationUseCases.getUserNotifications(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Handle error state more gracefully
            return Center(
              child: Text(
                appLocalizations.somethingWentWrong, // Assume this string exists in your localizations
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildNoNotificationsPlaceholder(appLocalizations);
          }

          final notifications = snapshot.data!;
          return ListView.separated(
            itemCount: notifications.length,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16), // Add dividers
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationTile(context, notif, appLocalizations, notificationUseCases);
            },
          );
        },
      ),
    );
  }

  Widget _buildNoUserPlaceholder(AppLocalizations appLocalizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              appLocalizations.loginRequiredForNotifications, // New localization key
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoNotificationsPlaceholder(AppLocalizations appLocalizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              appLocalizations.noNotificationsYet, // New localization key
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              appLocalizations.checkBackLaterForUpdates, // New localization key
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
      BuildContext context,
      AppNotification notif,
      AppLocalizations appLocalizations,
      NotificationUseCases notificationUseCases,
      ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: notif.read ? 0 : 2, // Highlight unread notifications
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: notif.read ? BorderSide.none : BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
      ),
      color: notif.read ? Colors.white : Theme.of(context).primaryColor.withOpacity(0.05), // Subtle background for unread
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: CircleAvatar(
          backgroundColor: notif.read ? Colors.grey[200] : Theme.of(context).primaryColor,
          child: Icon(
            notif.read ? Icons.check : Icons.notifications_active,
            color: notif.read ? Colors.grey[600] : Colors.white,
          ),
        ),
        title: Text(
          notif.title,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontWeight: notif.read ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
            color: notif.read ? Colors.black87 : Colors.black,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            notif.message,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: notif.read ? Colors.grey[600] : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
        trailing: notif.read
            ? null
            : IconButton( // Changed to IconButton for better visual cue
          icon: Icon(Icons.mark_email_unread_outlined, color: Theme.of(context).primaryColor),
          tooltip: appLocalizations.markAsRead, // Tooltip for accessibility
          onPressed: () {
            notificationUseCases.markAsRead(notif.id);
            ScaffoldMessenger.of(context).showSnackBar( // Show a snackbar on action
              SnackBar(
                content: Text(appLocalizations.notificationMarkedAsRead), // New localization key
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        onTap: () {
          if (!notif.read) {
            notificationUseCases.markAsRead(notif.id);
          }
          // Optionally, navigate to a detailed view of the notification
          // Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationDetailScreen(notification: notif)));
        },
      ),
    );
  }
}