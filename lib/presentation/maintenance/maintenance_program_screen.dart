// plastic_factory_management/lib/presentation/maintenance/maintenance_program_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/maintenance_log_model.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/maintenance_usecases.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // Import for custom font

import '../../core/constants/app_enums.dart';
import '../../theme/app_colors.dart'; // Import AppColors

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
        appBar: AppBar(
          title: Text(appLocalizations.maintenanceProgram),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text('لا يمكن عرض برنامج الصيانة بدون بيانات المستخدم.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.maintenanceProgram),
        centerTitle: true,
        backgroundColor: AppColors.primary, // Apply primary color
        foregroundColor: Colors.white, // White text for AppBar title
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white), // White icon
            onPressed: () {
              _showScheduleMaintenanceDialog(context, maintenanceUseCases, appLocalizations, currentUser);
            },
            tooltip: appLocalizations.scheduleMaintenance,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: appLocalizations.scheduledMaintenance),
            Tab(text: appLocalizations.completedMaintenance),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold), // Set Tajawal font
          unselectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.normal), // Set Tajawal font
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
                return Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          'خطأ في تحميل الصيانة المجدولة: ${snapshot.error}', // Original error message for technical details
                          style: const TextStyle(fontSize: 18, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${appLocalizations.technicalDetails}: ${snapshot.error}', // Reused localization
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined, color: Colors.grey[400], size: 80),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد مهام صيانة مجدولة.', // Default message for no data
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          appLocalizations.tapToAddFirstMachine, // Reused for adding first item
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showScheduleMaintenanceDialog(context, maintenanceUseCases, appLocalizations, currentUser);
                          },
                          icon: const Icon(Icons.add, color: Colors.white,),
                          label: Text(appLocalizations.scheduleMaintenance),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Filter by date if needed, or by assigned user if applicable
              // For a Maintenance Manager, show all. For operator, show assigned to them.
              final List<MaintenanceLogModel> filteredLogs = snapshot.data!
                  .where((log) => log.status == 'scheduled' || log.status == 'in_progress')
                  .toList();

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
                return Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (snapshot.hasError) {
                return Center(child: Text('خطأ في تحميل الصيانة المكتملة: ${snapshot.error}', style: TextStyle(color: Colors.red)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('لا توجد مهام صيانة مكتملة.', style: TextStyle(color: Colors.grey)));
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getMaintenanceStatusColor(log.status),
          child: Icon(Icons.build, color: Colors.white),
        ),
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
              '${appLocalizations.status}: ${log.status == 'scheduled' ? appLocalizations.scheduled : (log.status == 'in_progress' ? 'قيد التنفيذ' : appLocalizations.completed)}',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(color: _getMaintenanceStatusColor(log.status), fontWeight: FontWeight.bold),
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
                              completer: currentUser,
                              updatedChecklist: updatedChecklist,
                            );
                          }
                        }
                            : null,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                      ),
                    );
                  }).toList(),
                ),
                if (canComplete && !isCompletedTab)
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        final allItemsCompleted = log.checklist.every((item) => item.completed);
                        if (!allItemsCompleted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(appLocalizations.completeAllChecklistItems)),
                          );
                          return;
                        }
                        _showCompleteMaintenanceDialog(context, log, useCases, currentUser, appLocalizations);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(appLocalizations.completeMaintenance),
                    ),
                  ),
                if (!isCompletedTab && currentUser.userRoleEnum == UserRole.maintenanceManager)
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      icon: Icon(Icons.edit, size: 20, color: AppColors.secondary),
                      label: Text(appLocalizations.editMaintenance, style: TextStyle(color: AppColors.secondary)),
                      onPressed: () {
                        _showScheduleMaintenanceDialog(context, useCases, appLocalizations, currentUser, maintenanceLog: log);
                      },
                    ),
                  ),
                if (!isCompletedTab && currentUser.userRoleEnum == UserRole.maintenanceManager)
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      icon: Icon(Icons.delete, size: 20, color: Colors.redAccent),
                      label: Text(appLocalizations.deleteMaintenance, style: TextStyle(color: Colors.redAccent)),
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
        return Colors.blue.shade700;
      case 'in_progress':
        return AppColors.accentOrange;
      case 'completed':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark),
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
      useCases.getAllMachines().first.then((machines) {
        setState(() {
          _selectedMachine = machines.firstWhere((m) => m.id == maintenanceLog.machineId, orElse: () => machines.first);
        });
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? appLocalizations.editMaintenance : appLocalizations.scheduleMaintenance,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
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
                            return Center(child: CircularProgressIndicator(color: AppColors.primary));
                          }
                          if (snapshot.hasError) {
                            return Text('خطأ في تحميل الآلات: ${snapshot.error}', style: TextStyle(color: Colors.red));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Text('لا توجد آلات متاحة. يرجى إضافة آلات أولاً.', style: TextStyle(color: Colors.grey));
                          }

                          if (isEditing && _selectedMachine == null) {
                            _selectedMachine = snapshot.data!.firstWhere(
                                  (m) => m.id == maintenanceLog!.machineId,
                              orElse: () => snapshot.data!.first,
                            );
                          }

                          return DropdownButtonFormField<MachineModel>(
                            value: _selectedMachine,
                            decoration: InputDecoration(
                              labelText: appLocalizations.machine,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: Icon(Icons.precision_manufacturing_outlined, color: AppColors.dark),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
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
                        decoration: InputDecoration(
                          labelText: appLocalizations.maintenanceType,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.build_circle_outlined, color: AppColors.dark),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
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
                          style: TextStyle(color: AppColors.dark),
                        ),
                        trailing: Icon(Icons.calendar_today, color: AppColors.primary),
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDateTime,
                            firstDate: DateTime.now().subtract(Duration(days: 365)),
                            lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primary, // dialog primary color
                                  onPrimary: Colors.white, // text color on primary
                                  onSurface: AppColors.dark, // text color on surface
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (pickedDate != null) {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppColors.primary,
                                    onPrimary: Colors.white,
                                    onSurface: AppColors.dark,
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                                  ),
                                ),
                                child: child!,
                              ),
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
                        decoration: InputDecoration(
                          labelText: appLocalizations.notes,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.notes_outlined, color: AppColors.dark),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        maxLines: 3,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      // Checklist Items
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(appLocalizations.checklist, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark)),
                      ),
                      ..._checklistControllers.asMap().entries.map((entry) {
                        int idx = entry.key;
                        TextEditingController controller = entry.value;
                        return Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(
                                  hintText: appLocalizations.checklistItem,
                                  border: UnderlineInputBorder(),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                ),
                                textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                                validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.redAccent),
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
                          icon: Icon(Icons.add, color: AppColors.primary),
                          label: Text(appLocalizations.addChecklistItem, style: TextStyle(color: AppColors.primary)),
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
                  style: TextButton.styleFrom(foregroundColor: AppColors.dark),
                ),
                ElevatedButton.icon(
                  icon: Icon(isEditing ? Icons.save : Icons.add_task, color: Colors.white),
                  label: Text(isEditing ? appLocalizations.save : appLocalizations.schedule, style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final List<String> tasks = _checklistControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
                      if (tasks.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.checklistRequired)));
                        return;
                      }
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext loadingContext) {
                          return Center(child: CircularProgressIndicator(color: AppColors.primary));
                        },
                      );
                      try {
                        if (isEditing) {
                          await useCases.updateMaintenanceLog(
                            id: maintenanceLog!.id,
                            machineId: _selectedMachine!.id,
                            machineName: _selectedMachine!.name,
                            maintenanceDate: _selectedDateTime,
                            type: _selectedType,
                            responsibleUid: maintenanceLog.responsibleUid,
                            responsibleName: maintenanceLog.responsibleName,
                            notes: _notesController.text.isEmpty ? null : _notesController.text,
                            checklist: tasks.map((task) => MaintenanceChecklistItem(
                                task: task,
                                completed: maintenanceLog.checklist.any((item) => item.task == task && item.completed)
                            )).toList(),
                            status: maintenanceLog.status,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.maintenanceUpdatedSuccessfully)));
                        } else {
                          await useCases.scheduleMaintenance(
                            selectedMachine: _selectedMachine!,
                            maintenanceDateTime: _selectedDateTime,
                            type: _selectedType,
                            responsibleUser: currentUser,
                            notes: _notesController.text.isEmpty ? null : _notesController.text,
                            checklistTasks: tasks,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.maintenanceScheduledSuccessfully)));
                        }
                        Navigator.of(context).pop(); // Pop loading
                        Navigator.of(dialogContext).pop();
                      } catch (e) {
                        Navigator.of(context).pop(); // Pop loading
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorSavingMaintenance}: $e')));
                        print('Error saving maintenance: $e');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            appLocalizations.completeMaintenanceConfirmation,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                appLocalizations.confirmCompleteMaintenance,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.dark),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: finalNotesController,
                decoration: InputDecoration(
                  labelText: appLocalizations.notes,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.notes_outlined, color: AppColors.dark),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
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
              style: TextButton.styleFrom(foregroundColor: AppColors.dark),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.done_all, color: Colors.white),
              label: Text(appLocalizations.complete, style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return Center(child: CircularProgressIndicator(color: AppColors.primary));
                  },
                );
                try {
                  await useCases.completeMaintenanceTask(
                    log: log,
                    completer: currentUser,
                    updatedChecklist: log.checklist.map((item) => item.copyWith(completed: true, completedAt: Timestamp.now())).toList(),
                    finalNotes: finalNotesController.text.isEmpty ? null : finalNotesController.text,
                  );
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLocalizations.maintenanceCompletedSuccessfully)),
                  );
                } catch (e) {
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorCompletingMaintenance}: $e')),
                  );
                  print('Error completing maintenance: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.confirmDeletion, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(
            '${appLocalizations.confirmDeleteMaintenance}: "$machineName"؟\n\n${appLocalizations.thisActionCannotBeUndone}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: AppColors.dark),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: Text(appLocalizations.delete, style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Pop confirmation dialog
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return Center(child: CircularProgressIndicator(color: AppColors.primary));
                  },
                );
                try {
                  await useCases.deleteMaintenanceLog(logId);
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.maintenanceDeletedSuccessfully)));
                } catch (e) {
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorDeletingMaintenance}: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}