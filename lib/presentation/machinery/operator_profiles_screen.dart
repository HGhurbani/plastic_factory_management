// plastic_factory_management/lib/presentation/machinery/operator_profiles_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/operator_model.dart';
import 'package:plastic_factory_management/domain/usecases/machinery_operator_usecases.dart';
import 'package:intl/intl.dart' as intl;
import 'package:plastic_factory_management/theme/app_colors.dart';

import '../../data/models/machine_model.dart';

class OperatorProfilesScreen extends StatefulWidget {
  @override
  _OperatorProfilesScreenState createState() => _OperatorProfilesScreenState();
}

class _OperatorProfilesScreenState extends State<OperatorProfilesScreen> {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final machineryOperatorUseCases = Provider.of<MachineryOperatorUseCases>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.operatorProfiles),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddEditOperatorDialog(context, machineryOperatorUseCases, appLocalizations);
            },
            tooltip: appLocalizations.addOperator, // أضف هذا النص في ARB
          ),
        ],
      ),
      body: StreamBuilder<List<OperatorModel>>(
        stream: machineryOperatorUseCases.getOperators(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل بيانات المشغلين: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('لا يوجد مشغلون لعرضهم. يرجى إضافة مشغل جديد.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final operator = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    operator.name,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${appLocalizations.employeeID}: ${operator.employeeId}',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                      if (operator.personalData != null && operator.personalData!.isNotEmpty)
                        Text(
                          '${appLocalizations.personalData}: ${operator.personalData}',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                      Text(
                        '${appLocalizations.costPerHour}: \$${operator.costPerHour.toStringAsFixed(2)}',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        '${appLocalizations.status}: ${operator.status.toArabicString()}',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(color: _getOperatorStatusColor(operator.status)),
                      ),
                      if (operator.currentMachineId != null && operator.currentMachineId!.isNotEmpty)
                        Text(
                          '${appLocalizations.currentlyOperatingMachine}: ${operator.currentMachineId}', // يمكنك جلب اسم الآلة هنا
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
                        icon: Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () {
                          _showAddEditOperatorDialog(context, machineryOperatorUseCases, appLocalizations, operator: operator);
                        },
                        tooltip: appLocalizations.edit,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmationDialog(context, machineryOperatorUseCases, appLocalizations, operator.id, operator.name);
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

  Color _getOperatorStatusColor(OperatorStatus status) {
    switch (status) {
      case OperatorStatus.available:
        return Colors.green;
      case OperatorStatus.busy:
        return Colors.blue;
      case OperatorStatus.onBreak:
        return Colors.orange;
      case OperatorStatus.absent:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAddEditOperatorDialog(
      BuildContext context,
      MachineryOperatorUseCases useCases,
      AppLocalizations appLocalizations, {
        OperatorModel? operator,
      }) {
    final isEditing = operator != null;
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: operator?.name);
    final _employeeIdController = TextEditingController(text: operator?.employeeId);
    final _personalDataController = TextEditingController(text: operator?.personalData);
    final _costPerHourController = TextEditingController(text: operator?.costPerHour.toStringAsFixed(2));
    OperatorStatus _selectedStatus = operator?.status ?? OperatorStatus.available;
    String? _currentMachineId = operator?.currentMachineId; // Optional: for busy operators

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? appLocalizations.editOperator : appLocalizations.addOperator), // أضف هذا النص في ARB
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: appLocalizations.employeeName, border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _employeeIdController,
                        decoration: InputDecoration(labelText: appLocalizations.employeeID, border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _personalDataController,
                        decoration: InputDecoration(labelText: appLocalizations.personalData, border: OutlineInputBorder()),
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
                      // Operator Status Dropdown
                      DropdownButtonFormField<OperatorStatus>(
                        value: _selectedStatus,
                        decoration: InputDecoration(labelText: appLocalizations.status, border: OutlineInputBorder()),
                        items: OperatorStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.toArabicString(), textDirection: TextDirection.rtl),
                          );
                        }).toList(),
                        onChanged: (OperatorStatus? newValue) {
                          setState(() {
                            _selectedStatus = newValue!;
                          });
                        },
                      ),
                      SizedBox(height: 12),
                      if (_selectedStatus == OperatorStatus.busy)
                      // Optional: dropdown to select current machine if busy
                        StreamBuilder<List<MachineModel>>(
                          stream: useCases.getMachines(), // Get all machines
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }
                            if (snapshot.hasError) {
                              return Text('خطأ في تحميل الآلات: ${snapshot.error}');
                            }
                            final machines = snapshot.data ?? [];
                            return DropdownButtonFormField<String>(
                              value: _currentMachineId,
                              decoration: InputDecoration(labelText: appLocalizations.currentlyOperatingMachine, border: OutlineInputBorder()),
                              items: machines.map((machine) {
                                return DropdownMenuItem(
                                  value: machine.id, // Use machine ID
                                  child: Text('${machine.name} (${machine.machineId})', textDirection: TextDirection.rtl),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _currentMachineId = newValue;
                                });
                              },
                              validator: (value) => _selectedStatus == OperatorStatus.busy && value == null ? appLocalizations.fieldRequired : null,
                            );
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
                          await useCases.updateOperator(
                            id: operator!.id,
                            name: _nameController.text,
                            employeeId: _employeeIdController.text,
                            personalData: _personalDataController.text.isEmpty ? null : _personalDataController.text,
                            costPerHour: double.parse(_costPerHourController.text),
                            currentMachineId: _selectedStatus == OperatorStatus.busy ? _currentMachineId : null, // Clear if not busy
                            status: _selectedStatus,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.operatorUpdatedSuccessfully))); // أضف هذا النص
                        } else {
                          await useCases.addOperator(
                            name: _nameController.text,
                            employeeId: _employeeIdController.text,
                            personalData: _personalDataController.text.isEmpty ? null : _personalDataController.text,
                            costPerHour: double.parse(_costPerHourController.text),
                            status: _selectedStatus,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.operatorAddedSuccessfully))); // أضف هذا النص
                        }
                        Navigator.of(dialogContext).pop();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorSavingOperator}: $e'))); // أضف هذا النص
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
      String operatorId,
      String operatorName,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.confirmDeletion),
          content: Text('${appLocalizations.confirmDeleteOperator}: "$operatorName"؟'), // أضف هذا النص
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text(appLocalizations.delete),
              onPressed: () async {
                try {
                  await useCases.deleteOperator(operatorId);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.operatorDeletedSuccessfully))); // أضف هذا النص
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorDeletingOperator}: $e'))); // أضف هذا النص
                }
              },
            ),
          ],
        );
      },
    );
  }
}