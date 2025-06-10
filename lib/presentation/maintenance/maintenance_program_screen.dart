// plastic_factory_management/lib/presentation/maintenance/maintenance_program_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/maintenance_log_model.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/maintenance_usecases.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart'; // لاستخدام Timestamp

class MaintenanceProgramScreen extends StatefulWidget {
  @override
  _MaintenanceProgramScreenState createState() => _MaintenanceProgramScreenState();
}

class _MaintenanceProgramScreenState extends State<MaintenanceProgramScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // For Scheduled and Completed
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final maintenanceUseCases = Provider.of<MaintenanceUseCases>(context);
    final currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(appLocalizations.maintenanceProgram)),
        body: Center(child: Text('لا يمكن عرض برنامج الصيانة بدون بيانات المستخدم.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.maintenanceProgram),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showScheduleMaintenanceDialog(context, maintenanceUseCases, appLocalizations, currentUser);
            },
            tooltip: appLocalizations.scheduleMaintenance, // أضف هذا النص في ARB
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: appLocalizations.scheduledMaintenance), // أضف هذا النص في ARB
            Tab(text: appLocalizations.completedMaintenance), // أضف هذا النص في ARB
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Scheduled Maintenance Tab
          StreamBuilder<List<MaintenanceLogModel>>(
            stream: maintenanceUseCases.getScheduledMaintenance(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('خطأ في تحميل الصيانة المجدولة: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('لا توجد مهام صيانة مجدولة.'));
              }

              // Filter by date if needed, or by assigned user if applicable
              // For a Maintenance Manager, show all. For operator, show assigned to them.
              final List<MaintenanceLogModel> filteredLogs = snapshot.data!
                  .where((log) => log.status == 'scheduled' || log.status == 'in_progress')
                  .toList(); // Or filter based on user role/assignment

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: filteredLogs.length,
                itemBuilder: (context, index) {
                  final log = filteredLogs[index];
                  return _buildMaintenanceCard(log, appLocalizations, maintenanceUseCases, currentUser);
                },
              );
            },
          ),
          // Completed Maintenance Tab
          StreamBuilder<List<MaintenanceLogModel>>(
            stream: maintenanceUseCases.getCompletedMaintenance(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('خطأ في تحميل الصيانة المكتملة: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('لا توجد مهام صيانة مكتملة.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final log = snapshot.data![index];
                  return _buildMaintenanceCard(log, appLocalizations, maintenanceUseCases, currentUser, isCompletedTab: true);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(MaintenanceLogModel log, AppLocalizations appLocalizations, MaintenanceUseCases useCases, UserModel currentUser, {bool isCompletedTab = false}) {
    final bool canComplete = (log.status == 'scheduled' || log.status == 'in_progress') &&
        (currentUser.userRoleEnum == UserRole.maintenanceManager || currentUser.uid == log.responsibleUid);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          'صيانة ${log.machineName} - ${log.type.toArabicString()}',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${appLocalizations.maintenanceDate}: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(log.maintenanceDate.toDate())}',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            Text(
              '${appLocalizations.responsiblePerson}: ${log.responsibleName}',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            Text(
              '${appLocalizations.status}: ${log.status == 'scheduled' ? appLocalizations.scheduled : (log.status == 'in_progress' ? 'قيد التنفيذ' : appLocalizations.completed)}', // أضف 'قيد التنفيذ' و 'مجدولة' في ARB
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(color: _getMaintenanceStatusColor(log.status)),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (log.notes != null && log.notes!.isNotEmpty)
                  _buildDetailRow(appLocalizations.notes, log.notes!),
                SizedBox(height: 8),
                Text(appLocalizations.checklist, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
                Column(
                  children: log.checklist.map((item) {
                    return Directionality(
                      textDirection: TextDirection.rtl,
                      child: CheckboxListTile(
                        title: Text(
                          item.task,
                          style: TextStyle(
                            decoration: item.completed ? TextDecoration.lineThrough : null,
                            color: item.completed ? Colors.grey : Colors.black,
                          ),
                        ),
                        value: item.completed,
                        onChanged: canComplete && !isCompletedTab
                            ? (bool? newValue) async {
                          final updatedChecklist = List<MaintenanceChecklistItem>.from(log.checklist);
                          final itemIndex = updatedChecklist.indexWhere((e) => e.task == item.task);
                          if (itemIndex != -1) {
                            updatedChecklist[itemIndex] = item.copyWith(
                              completed: newValue,
                              completedAt: newValue == true ? Timestamp.now() : null,
                            );
                            // Update the log in Firestore
                            await useCases.completeMaintenanceTask(
                              log: log,
                              completer: currentUser, // This assumes current user is the one completing
                              updatedChecklist: updatedChecklist,
                            );
                          }
                        }
                            : null, // Disable if not completable or already completed
                        controlAffinity: ListTileControlAffinity.leading, // Checkbox on the right for RTL
                      ),
                    );
                  }).toList(),
                ),
                if (canComplete && !isCompletedTab)
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        // Check if all items are completed
                        final allItemsCompleted = log.checklist.every((item) => item.completed);
                        if (!allItemsCompleted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(appLocalizations.completeAllChecklistItems)), // أضف هذا النص
                          );
                          return;
                        }
                        _showCompleteMaintenanceDialog(context, log, useCases, currentUser, appLocalizations);
                      },
                      child: Text(appLocalizations.completeMaintenance), // أضف هذا النص
                    ),
                  ),
                if (!isCompletedTab && currentUser.userRoleEnum == UserRole.maintenanceManager)
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      icon: Icon(Icons.edit, size: 20),
                      label: Text(appLocalizations.editMaintenance), // أضف هذا النص
                      onPressed: () {
                        _showScheduleMaintenanceDialog(context, useCases, appLocalizations, currentUser, maintenanceLog: log);
                      },
                    ),
                  ),
                if (!isCompletedTab && currentUser.userRoleEnum == UserRole.maintenanceManager)
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      icon: Icon(Icons.delete, size: 20, color: Colors.red),
                      label: Text(appLocalizations.deleteMaintenance), // أضف هذا النص
                      onPressed: () {
                        _showDeleteConfirmationDialog(context, useCases, appLocalizations, log.id, log.machineName);
                      },
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMaintenanceStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          SizedBox(width: 4),
          Text(
            '$label:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  void _showScheduleMaintenanceDialog(
      BuildContext context,
      MaintenanceUseCases useCases,
      AppLocalizations appLocalizations,
      UserModel currentUser, {
        MaintenanceLogModel? maintenanceLog,
      }) {
    final isEditing = maintenanceLog != null;
    final _formKey = GlobalKey<FormState>();
    MachineModel? _selectedMachine;
    MaintenanceType _selectedType = maintenanceLog?.type ?? MaintenanceType.preventive;
    DateTime _selectedDateTime = maintenanceLog?.maintenanceDate.toDate() ?? DateTime.now();
    final TextEditingController _notesController = TextEditingController(text: maintenanceLog?.notes);
    List<TextEditingController> _checklistControllers = maintenanceLog?.checklist
        .map((item) => TextEditingController(text: item.task))
        .toList() ??
        [TextEditingController()]; // Start with one empty controller

    if (isEditing && maintenanceLog!.machineId.isNotEmpty) {
      // Try to pre-select the machine for editing
      useCases.getAllMachines().first.then((machines) {
        setState(() {
          _selectedMachine = machines.firstWhere((m) => m.id == maintenanceLog.machineId, orElse: () => machines.first); // Fallback
        });
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? appLocalizations.editMaintenance : appLocalizations.scheduleMaintenance),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Machine Selection
                      StreamBuilder<List<MachineModel>>(
                        stream: useCases.getAllMachines(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text('خطأ في تحميل الآلات: ${snapshot.error}');
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Text('لا توجد آلات متاحة. يرجى إضافة آلات أولاً.');
                          }

                          // Set initial value only if not set and in editing mode
                          if (isEditing && _selectedMachine == null) {
                            _selectedMachine = snapshot.data!.firstWhere(
                                  (m) => m.id == maintenanceLog!.machineId,
                              orElse: () => snapshot.data!.first,
                            );
                          }

                          return DropdownButtonFormField<MachineModel>(
                            value: _selectedMachine,
                            decoration: InputDecoration(labelText: appLocalizations.machine, border: OutlineInputBorder()), // أضف هذا النص
                            items: snapshot.data!.map((machine) {
                              return DropdownMenuItem(
                                value: machine,
                                child: Text('${machine.name} (${machine.machineId})', textDirection: TextDirection.rtl),
                              );
                            }).toList(),
                            onChanged: (MachineModel? newValue) {
                              setState(() {
                                _selectedMachine = newValue;
                              });
                            },
                            validator: (value) => value == null ? appLocalizations.fieldRequired : null,
                          );
                        },
                      ),
                      SizedBox(height: 12),
                      // Maintenance Type
                      DropdownButtonFormField<MaintenanceType>(
                        value: _selectedType,
                        decoration: InputDecoration(labelText: appLocalizations.maintenanceType, border: OutlineInputBorder()),
                        items: MaintenanceType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toArabicString(), textDirection: TextDirection.rtl),
                          );
                        }).toList(),
                        onChanged: (MaintenanceType? newValue) {
                          setState(() {
                            _selectedType = newValue!;
                          });
                        },
                      ),
                      SizedBox(height: 12),
                      // Date and Time Picker
                      ListTile(
                        title: Text(
                          '${appLocalizations.maintenanceDate}: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime)}',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDateTime,
                            firstDate: DateTime.now().subtract(Duration(days: 365)),
                            lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                          );
                          if (pickedDate != null) {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                _selectedDateTime = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(labelText: appLocalizations.notes, border: OutlineInputBorder()),
                        maxLines: 3,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      // Checklist Items
                      Text(appLocalizations.checklist, style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                      ..._checklistControllers.asMap().entries.map((entry) {
                        int idx = entry.key;
                        TextEditingController controller = entry.value;
                        return Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(hintText: appLocalizations.checklistItem, border: UnderlineInputBorder()), // أضف هذا النص
                                textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                                validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _checklistControllers.removeAt(idx);
                                });
                              },
                            ),
                          ],
                        );
                      }).toList(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: Icon(Icons.add),
                          label: Text(appLocalizations.addChecklistItem), // أضف هذا النص
                          onPressed: () {
                            setState(() {
                              _checklistControllers.add(TextEditingController());
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(appLocalizations.cancel),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: Text(isEditing ? appLocalizations.save : appLocalizations.schedule), // أضف هذا النص
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final List<String> tasks = _checklistControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
                      if (tasks.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.checklistRequired))); // أضف هذا النص
                        return;
                      }

                      try {
                        if (isEditing) {
                          await useCases.updateMaintenanceLog(
                            id: maintenanceLog!.id,
                            machineId: _selectedMachine!.id,
                            machineName: _selectedMachine!.name,
                            maintenanceDate: _selectedDateTime,
                            type: _selectedType,
                            responsibleUid: maintenanceLog.responsibleUid, // Keep original responsible for now
                            responsibleName: maintenanceLog.responsibleName,
                            notes: _notesController.text.isEmpty ? null : _notesController.text,
                            checklist: tasks.map((task) => MaintenanceChecklistItem(
                                task: task,
                                completed: maintenanceLog.checklist.any((item) => item.task == task && item.completed) // Preserve completion status
                            )).toList(),
                            status: maintenanceLog.status, // Preserve status (scheduled/in_progress)
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.maintenanceUpdatedSuccessfully))); // أضف هذا النص
                        } else {
                          await useCases.scheduleMaintenance(
                            selectedMachine: _selectedMachine!,
                            maintenanceDateTime: _selectedDateTime,
                            type: _selectedType,
                            responsibleUser: currentUser, // Current user is the one scheduling/responsible
                            notes: _notesController.text.isEmpty ? null : _notesController.text,
                            checklistTasks: tasks,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.maintenanceScheduledSuccessfully))); // أضف هذا النص
                        }
                        Navigator.of(dialogContext).pop();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorSavingMaintenance}: $e'))); // أضف هذا النص
                        print('Error saving maintenance: $e');
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCompleteMaintenanceDialog(
      BuildContext context,
      MaintenanceLogModel log,
      MaintenanceUseCases useCases,
      UserModel currentUser,
      AppLocalizations appLocalizations,
      ) {
    final TextEditingController finalNotesController = TextEditingController(text: log.notes);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.completeMaintenanceConfirmation), // أضف هذا النص
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(appLocalizations.confirmCompleteMaintenance), // أضف هذا النص
              SizedBox(height: 16),
              TextFormField(
                controller: finalNotesController,
                decoration: InputDecoration(
                  labelText: appLocalizations.notes,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text(appLocalizations.complete),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await useCases.completeMaintenanceTask(
                    log: log,
                    completer: currentUser,
                    updatedChecklist: log.checklist.map((item) => item.copyWith(completed: true, completedAt: Timestamp.now())).toList(),
                    finalNotes: finalNotesController.text.isEmpty ? null : finalNotesController.text,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLocalizations.maintenanceCompletedSuccessfully)), // أضف هذا النص
                  );
                  // TODO: Update machine status to 'ready' via MachineryOperatorUseCases
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorCompletingMaintenance}: $e')), // أضف هذا النص
                  );
                  print('Error completing maintenance: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context,
      MaintenanceUseCases useCases,
      AppLocalizations appLocalizations,
      String logId,
      String machineName,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.confirmDeletion),
          content: Text('${appLocalizations.confirmDeleteMaintenance}: "$machineName"؟'), // أضف هذا النص
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text(appLocalizations.delete),
              onPressed: () async {
                try {
                  await useCases.deleteMaintenanceLog(logId);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.maintenanceDeletedSuccessfully))); // أضف هذا النص
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorDeletingMaintenance}: $e'))); // أضف هذا النص
                }
              },
            ),
          ],
        );
      },
    );
  }
}