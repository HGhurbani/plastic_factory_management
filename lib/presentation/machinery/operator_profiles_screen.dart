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
        backgroundColor: AppColors.primary, // Apply primary color
        foregroundColor: Colors.white, // White text for AppBar title
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1_outlined, color: Colors.white), // Specific icon, white color
            onPressed: () {
              _showAddEditOperatorDialog(context, machineryOperatorUseCases, appLocalizations);
            },
            tooltip: appLocalizations.addOperator,
          ),
        ],
      ),
      body: StreamBuilder<List<OperatorModel>>(
        stream: machineryOperatorUseCases.getOperators(),
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
                      'خطأ في تحميل بيانات المشغلين: ${snapshot.error}', // Original error message for technical details
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
                    Icon(Icons.people_outline, color: Colors.grey[400], size: 80), // Specific icon
                    const SizedBox(height: 16),
                    Text(
                      'لا يوجد مشغلون لعرضهم. يرجى إضافة مشغل جديد.', // Default message for no data
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.tapToAddFirstUser, // Reused localization for adding first item
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddEditOperatorDialog(context, machineryOperatorUseCases, appLocalizations);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(appLocalizations.addOperator),
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

          return ListView.builder(
            itemCount: snapshot.data!.length,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemBuilder: (context, index) {
              final operator = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 1, // Increased elevation for prominence
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
                child: InkWell( // Added InkWell for tap feedback
                  onTap: () {
                    // Optional: Show operator details dialog
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0), // Inner padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end, // Align all content to the right
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Operator Name with icon
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Icon(Icons.person_outline, color: AppColors.primary, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  operator.name,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getOperatorStatusColor(operator.status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                operator.status.toArabicString(),
                                style: TextStyle(
                                  color: _getOperatorStatusColor(operator.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16), // Separator
                        _buildInfoRow(appLocalizations.employeeID, operator.employeeId, icon: Icons.badge_outlined),
                        if (operator.personalData != null && operator.personalData!.isNotEmpty)
                          _buildInfoRow(appLocalizations.personalData, operator.personalData!, icon: Icons.person_pin_outlined),
                        _buildInfoRow(appLocalizations.costPerHour, '﷼${operator.costPerHour.toStringAsFixed(2)}', icon: Icons.currency_exchange),
                        if (operator.currentMachineId != null && operator.currentMachineId!.isNotEmpty)
                          _buildInfoRow(appLocalizations.currentlyOperatingMachine, operator.currentMachineId!, icon: Icons.precision_manufacturing_outlined, textColor: Colors.grey[700], isBold: true),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomLeft, // Align actions to bottom left for RTL
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 22, color: AppColors.secondary),
                                onPressed: () {
                                  _showAddEditOperatorDialog(context, machineryOperatorUseCases, appLocalizations, operator: operator);
                                },
                                tooltip: appLocalizations.edit,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 22, color: Colors.redAccent),
                                onPressed: () {
                                  _showDeleteConfirmationDialog(context, machineryOperatorUseCases, appLocalizations, operator.id, operator.name);
                                },
                                tooltip: appLocalizations.delete,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditOperatorDialog(context, machineryOperatorUseCases, appLocalizations);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: appLocalizations.addOperator,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getOperatorStatusColor(OperatorStatus status) {
    switch (status) {
      case OperatorStatus.available:
        return Colors.green.shade700;
      case OperatorStatus.busy:
        return Colors.blue.shade700;
      case OperatorStatus.onBreak:
        return AppColors.accentOrange; // Using predefined accent orange
      case OperatorStatus.absent:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor, bool isBold = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.7)),
            const SizedBox(width: 8),
          ],
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: textColor ?? Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.left,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
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
    String? _currentMachineId = operator?.currentMachineId;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? appLocalizations.editOperator : appLocalizations.addOperator,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.employeeName,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.dark),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _employeeIdController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.employeeID,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.badge_outlined, color: AppColors.dark),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _personalDataController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.personalData,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.assignment_ind_outlined, color: AppColors.dark),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        maxLines: 3,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _costPerHourController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.costPerHour,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.currency_exchange, color: AppColors.dark),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
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
                        decoration: InputDecoration(
                          labelText: appLocalizations.status,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.info_outline, color: AppColors.dark),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        items: OperatorStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  status.toArabicString(),
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(color: _getOperatorStatusColor(status)),
                                ),
                                const SizedBox(width: 8),
                                Icon(_getOperatorStatusIcon(status), size: 18, color: _getOperatorStatusColor(status)),
                              ],
                            ),
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
                        StreamBuilder<List<MachineModel>>(
                          stream: useCases.getMachines(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator(color: AppColors.primary);
                            }
                            if (snapshot.hasError) {
                              return Text('خطأ في تحميل الآلات: ${snapshot.error}', style: TextStyle(color: Colors.red));
                            }
                            final machines = snapshot.data ?? [];
                            return DropdownButtonFormField<String>(
                              value: _currentMachineId,
                              decoration: InputDecoration(
                                labelText: appLocalizations.currentlyOperatingMachine,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                prefixIcon: Icon(Icons.precision_manufacturing_outlined, color: AppColors.dark),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
                              ),
                              items: machines.map((machine) {
                                return DropdownMenuItem(
                                  value: machine.id,
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
                  style: TextButton.styleFrom(foregroundColor: AppColors.dark),
                ),
                ElevatedButton.icon(
                  icon: Icon(isEditing ? Icons.save : Icons.add, color: Colors.white),
                  label: Text(isEditing ? appLocalizations.save : appLocalizations.add, style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
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
                          await useCases.updateOperator(
                            id: operator!.id,
                            name: _nameController.text,
                            employeeId: _employeeIdController.text,
                            personalData: _personalDataController.text.isEmpty ? null : _personalDataController.text,
                            costPerHour: double.parse(_costPerHourController.text),
                            currentMachineId: _selectedStatus == OperatorStatus.busy ? _currentMachineId : null,
                            status: _selectedStatus,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.operatorUpdatedSuccessfully)));
                        } else {
                          await useCases.addOperator(
                            name: _nameController.text,
                            employeeId: _employeeIdController.text,
                            personalData: _personalDataController.text.isEmpty ? null : _personalDataController.text,
                            costPerHour: double.parse(_costPerHourController.text),
                            status: _selectedStatus,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.operatorAddedSuccessfully)));
                        }
                        Navigator.of(context).pop(); // Pop loading
                        Navigator.of(dialogContext).pop();
                      } catch (e) {
                        Navigator.of(context).pop(); // Pop loading
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorSavingOperator}: $e')));
                        print('Error saving operator: $e'); // For debugging
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

  IconData _getOperatorStatusIcon(OperatorStatus status) {
    switch (status) {
      case OperatorStatus.available:
        return Icons.check_circle_outline;
      case OperatorStatus.busy:
        return Icons.play_circle_outline;
      case OperatorStatus.onBreak:
        return Icons.timer_outlined;
      case OperatorStatus.absent:
        return Icons.person_off_outlined;
      default:
        return Icons.help_outline;
    }
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.confirmDeletion, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(
            '${appLocalizations.confirmDeleteOperator}: "$operatorName"؟\n\n${appLocalizations.thisActionCannotBeUndone}',
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
                  await useCases.deleteOperator(operatorId);
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.operatorDeletedSuccessfully)));
                } catch (e) {
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorDeletingOperator}: $e')));
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