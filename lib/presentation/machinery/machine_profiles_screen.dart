// plastic_factory_management/lib/presentation/machinery/machine_profiles_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/domain/usecases/machinery_operator_usecases.dart';
import 'package:intl/intl.dart' as intl; // Alias for clarity
import 'package:plastic_factory_management/theme/app_colors.dart'; // Ensure this defines your app's color scheme

class MachineProfilesScreen extends StatefulWidget {
  const MachineProfilesScreen({super.key});

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
        backgroundColor: Theme.of(context).primaryColor, // Consistent theme color
        foregroundColor: Colors.white, // White text for better contrast
        elevation: 0, // No shadow for a cleaner look
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined), // More specific icon for adding a machine
            onPressed: () {
              _showAddEditMachineDialog(context, machineryOperatorUseCases, appLocalizations);
            },
            tooltip: appLocalizations.addMachine,
          ),
        ],
      ),
      body: StreamBuilder<List<MachineModel>>(
        stream: machineryOperatorUseCases.getMachines(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                      appLocalizations.errorLoadingMachines, // New localization key
                      style: const TextStyle(fontSize: 18, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${appLocalizations.technicalDetails}: ${snapshot.error}',
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
                    Icon(Icons.precision_manufacturing_outlined, color: Colors.grey[400], size: 80), // Specific icon
                    const SizedBox(height: 16),
                    Text(
                      appLocalizations.noMachinesAvailable, // New localization key
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.tapToAddFirstMachine, // New localization key
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddEditMachineDialog(context, machineryOperatorUseCases, appLocalizations);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(appLocalizations.addMachine),
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
              final machine = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 1, // Increased elevation for prominence
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
                child: InkWell( // Added InkWell for tap feedback
                  onTap: () {
                    // Optionally, show a detailed view of the machine
                    // _showMachineDetailsDialog(context, appLocalizations, machine);
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
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getMachineStatusColor(machine.status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                machine.status.toArabicString(),
                                style: TextStyle(
                                  color: _getMachineStatusColor(machine.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            // Machine Name with icon
                            Row(
                              children: [
                                Text(
                                  machine.name,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.precision_manufacturing, color: AppColors.primary, size: 28),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 16), // Separator
                        _buildInfoRow(appLocalizations.machineID, machine.machineId, icon: Icons.qr_code_2),
                        if (machine.details != null && machine.details!.isNotEmpty)
                          _buildInfoRow(appLocalizations.machineDetails, machine.details!, icon: Icons.info_outline),
                        _buildInfoRow(appLocalizations.costPerHour, '\$${machine.costPerHour.toStringAsFixed(2)}', icon: Icons.attach_money),
                        if (machine.lastMaintenance != null)
                          _buildInfoRow(
                            appLocalizations.lastMaintenance,
                            _formatDate(machine.lastMaintenance!),
                            icon: Icons.calendar_today_outlined,
                            textColor: Colors.grey[700],
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomLeft, // Align actions to bottom left for RTL
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 22, color: AppColors.secondary),
                                onPressed: () {
                                  _showAddEditMachineDialog(context, machineryOperatorUseCases, appLocalizations, machine: machine);
                                },
                                tooltip: appLocalizations.edit,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 22, color: Colors.redAccent),
                                onPressed: () {
                                  _showDeleteConfirmationDialog(context, machineryOperatorUseCases, appLocalizations, machine.id, machine.name);
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
          _showAddEditMachineDialog(context, machineryOperatorUseCases, appLocalizations);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: appLocalizations.addMachine,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getMachineStatusColor(MachineStatus status) {
    switch (status) {
      case MachineStatus.ready:
        return Colors.green.shade700;
      case MachineStatus.inOperation:
        return Colors.blue.shade700;
      case MachineStatus.underMaintenance:
        return Colors.orange.shade700;
      case MachineStatus.outOfService:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    final formatter = intl.DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(date);
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor, bool isBold = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: textColor ?? Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(width: 8),
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
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.7)),
          ]
        ],
      ),
    );
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? appLocalizations.editMachine : appLocalizations.addMachine,
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
                          labelText: appLocalizations.machineName,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.precision_manufacturing_outlined), // Icon for name
                        ),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _machineIdController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.machineID,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.qr_code_2), // Icon for machine ID
                        ),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _detailsController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.machineDetails,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.info_outline), // Icon for details
                        ),
                        maxLines: 3,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _costPerHourController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.costPerHour,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.money), // Icon for cost
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return appLocalizations.fieldRequired;
                          if (double.tryParse(value) == null || double.parse(value)! < 0) return appLocalizations.invalidNumberPositive; // New localization
                          return null;
                        },
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      // Machine Status Dropdown
                      DropdownButtonFormField<MachineStatus>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: appLocalizations.machineStatus,
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(_getMachineStatusIcon(_selectedStatus)), // Icon changes with status
                        ),
                        items: MachineStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  status.toArabicString(),
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(color: _getMachineStatusColor(status)),
                                ),
                                const SizedBox(width: 8),
                                Icon(_getMachineStatusIcon(status), size: 18, color: _getMachineStatusColor(status)),
                              ],
                            ),
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
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                ),
                ElevatedButton.icon(
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? appLocalizations.save : appLocalizations.add),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext loadingContext) {
                          return const Center(child: CircularProgressIndicator());
                        },
                      );
                      try {
                        if (isEditing) {
                          await useCases.updateMachine(
                            id: machine!.id,
                            name: _nameController.text,
                            machineId: _machineIdController.text,
                            details: _detailsController.text.isEmpty ? null : _detailsController.text,
                            costPerHour: double.parse(_costPerHourController.text),
                            status: _selectedStatus,
                            lastMaintenance: machine.lastMaintenance,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.machineUpdatedSuccessfully)));
                        } else {
                          await useCases.addMachine(
                            name: _nameController.text,
                            machineId: _machineIdController.text,
                            details: _detailsController.text.isEmpty ? null : _detailsController.text,
                            costPerHour: double.parse(_costPerHourController.text),
                            status: _selectedStatus,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.machineAddedSuccessfully)));
                        }
                        Navigator.of(context).pop(); // Pop the loading indicator
                        Navigator.of(dialogContext).pop(); // Pop the dialog
                      } catch (e) {
                        Navigator.of(context).pop(); // Pop the loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorSavingMachine}: ${e.toString()}')));
                        print('Error saving machine: $e'); // For debugging
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

  // Helper to get an icon based on machine status
  IconData _getMachineStatusIcon(MachineStatus status) {
    switch (status) {
      case MachineStatus.ready:
        return Icons.check_circle_outline;
      case MachineStatus.inOperation:
        return Icons.play_circle_outline;
      case MachineStatus.underMaintenance:
        return Icons.build_outlined;
      case MachineStatus.outOfService:
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.confirmDeletion, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(
            '${appLocalizations.confirmDeleteMachine}: "$machineName"؟\n\n${appLocalizations.thisActionCannotBeUndone}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: Text(appLocalizations.delete),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Pop confirmation dialog
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );
                try {
                  await useCases.deleteMachine(machineId);
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.machineDeletedSuccessfully)));
                } catch (e) {
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorDeletingMachine}: ${e.toString()}')));
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