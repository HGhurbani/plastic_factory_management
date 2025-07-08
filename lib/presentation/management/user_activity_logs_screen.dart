import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/domain/usecases/user_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/user_activity_log_usecases.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/data/models/user_activity_log_model.dart';
import 'package:intl/intl.dart';

class UserActivityLogsScreen extends StatefulWidget {
  const UserActivityLogsScreen({super.key});

  @override
  State<UserActivityLogsScreen> createState() => _UserActivityLogsScreenState();
}

class _UserActivityLogsScreenState extends State<UserActivityLogsScreen> {
  UserModel? _selectedUser;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final userUseCases = Provider.of<UserUseCases>(context);
    final logUseCases = Provider.of<UserActivityLogUseCases>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.userActivityLogs),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder<List<UserModel>>(
              stream: userUseCases.getUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final users = snapshot.data!;
                return DropdownButton<UserModel>(
                  value: _selectedUser,
                  hint: Text(loc.selectUser),
                  items: users
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u.name),
                          ))
                      .toList(),
                  onChanged: (u) {
                    setState(() {
                      _selectedUser = u;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            if (_selectedUser != null)
              Expanded(
                child: StreamBuilder<List<UserActivityLog>>(
                  stream: logUseCases.getLogsForUser(_selectedUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('${snapshot.error}'));
                    }
                    final logs = snapshot.data ?? [];
                    if (logs.isEmpty) {
                      return Center(child: Text(loc.noActivityLogs));
                    }
                    return ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(log.action),
                          subtitle: Text(log.details ?? ''),
                          trailing: Text(DateFormat('yyyy-MM-dd HH:mm')
                              .format(log.timestamp.toDate())),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
