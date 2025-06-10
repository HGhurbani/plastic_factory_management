// plastic_factory_management/lib/presentation/machinery/machine_profiles_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/domain/usecases/machinery_operator_usecases.dart';
import 'package:intl/intl.dart' as intl;

class MachineProfilesScreen extends StatefulWidget {
  @override
  _MachineProfilesScreenState createState() => _MachineProfilesScreenState();
}

class _MachineProfilesScreenState extends State<MachineProfilesScreen> {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final machineryOperatorUseCases = Provider.of<MachineryOperatorUseCases>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.machineProfiles),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddEditMachineDialog(context, machineryOperatorUseCases, appLocalizations);
            },
            tooltip: appLocalizations.addMachine, // أضف هذا النص في ARB
          ),
        ],
      ),
      body: StreamBuilder<List<MachineModel>>(
        stream: machineryOperatorUseCases.getMachines(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل بيانات الآلات: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('لا توجد آلات لعرضها. يرجى إضافة آلة جديدة.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final machine = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    machine.name,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${appLocalizations.machineID}: ${machine.machineId}',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                      if (machine.details != null && machine.details!.isNotEmpty)
                        Text(
                          '${appLocalizations.machineDetails}: ${machine.details}',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                      Text(
                        '${appLocalizations.costPerHour}: \$${machine.costPerHour.toStringAsFixed(2)}',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        '${appLocalizations.machineStatus}: ${machine.status.toArabicString()}',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(color: _getMachineStatusColor(machine.status)),
                      ),
                      if (machine.lastMaintenance != null)
                        Text(
                          'آخر صيانة: ${machine.lastMaintenance != null ? _formatDate(machine.lastMaintenance!) : ''}', // تحتاج لتنسيق التاريخ
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showAddEditMachineDialog(context, machineryOperatorUseCases, appLocalizations, machine: machine);
                        },
                        tooltip: appLocalizations.edit,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmationDialog(context, machineryOperatorUseCases, appLocalizations, machine.id, machine.name);
                        },
                        tooltip: appLocalizations.delete,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getMachineStatusColor(MachineStatus status) {
    switch (status) {
      case MachineStatus.ready:
        return Colors.green;
      case MachineStatus.inOperation:
        return Colors.blue;
      case MachineStatus.underMaintenance:
        return Colors.orange;
      case MachineStatus.outOfService:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    final formatter = intl.DateFormat('yyyy-MM-dd HH:mm'); // قم باستيراد intl في الأعلى
    return formatter.format(date);
  }

  void _showAddEditMachineDialog(
      BuildContext context,
      MachineryOperatorUseCases useCases,
      AppLocalizations appLocalizations, {
        MachineModel? machine,
      }) {
    final isEditing = machine != null;
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: machine?.name);
    final _machineIdController = TextEditingController(text: machine?.machineId);
    final _detailsController = TextEditingController(text: machine?.details);
    final _costPerHourController = TextEditingController(text: machine?.costPerHour.toStringAsFixed(2));
    MachineStatus _selectedStatus = machine?.status ?? MachineStatus.ready;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? appLocalizations.editMachine : appLocalizations.addMachine), // أضف هذا النص في ARB
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: appLocalizations.machineName, border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _machineIdController,
                        decoration: InputDecoration(labelText: appLocalizations.machineID, border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _detailsController,
                        decoration: InputDecoration(labelText: appLocalizations.machineDetails, border: OutlineInputBorder()),
                        maxLines: 3,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _costPerHourController,
                        decoration: InputDecoration(labelText: appLocalizations.costPerHour, border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return appLocalizations.fieldRequired;
                          if (double.tryParse(value) == null || double.parse(value)! < 0) return appLocalizations.invalidNumber;
                          return null;
                        },
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      // Machine Status Dropdown
                      DropdownButtonFormField<MachineStatus>(
                        value: _selectedStatus,
                        decoration: InputDecoration(labelText: appLocalizations.machineStatus, border: OutlineInputBorder()),
                        items: MachineStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.toArabicString(), textDirection: TextDirection.rtl),
                          );
                        }).toList(),
                        onChanged: (MachineStatus? newValue) {
                          setState(() {
                            _selectedStatus = newValue!;
                          });
                        },
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
                  child: Text(isEditing ? appLocalizations.save : appLocalizations.add),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        if (isEditing) {
                          await useCases.updateMachine(
                            id: machine!.id,
                            name: _nameController.text,
                            machineId: _machineIdController.text,
                            details: _detailsController.text.isEmpty ? null : _detailsController.text,
                            costPerHour: double.parse(_costPerHourController.text),
                            status: _selectedStatus,
                            lastMaintenance: machine.lastMaintenance, // Keep existing maintenance date
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.machineUpdatedSuccessfully))); // أضف هذا النص
                        } else {
                          await useCases.addMachine(
                            name: _nameController.text,
                            machineId: _machineIdController.text,
                            details: _detailsController.text.isEmpty ? null : _detailsController.text,
                            costPerHour: double.parse(_costPerHourController.text),
                            status: _selectedStatus,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.machineAddedSuccessfully))); // أضف هذا النص
                        }
                        Navigator.of(dialogContext).pop();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorSavingMachine}: $e'))); // أضف هذا النص
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

  void _showDeleteConfirmationDialog(
      BuildContext context,
      MachineryOperatorUseCases useCases,
      AppLocalizations appLocalizations,
      String machineId,
      String machineName,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.confirmDeletion),
          content: Text('${appLocalizations.confirmDeleteMachine}: "$machineName"؟'), // أضف هذا النص
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text(appLocalizations.delete),
              onPressed: () async {
                try {
                  await useCases.deleteMachine(machineId);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.machineDeletedSuccessfully))); // أضف هذا النص
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorDeletingMachine}: $e'))); // أضف هذا النص
                }
              },
            ),
          ],
        );
      },
    );
  }
}