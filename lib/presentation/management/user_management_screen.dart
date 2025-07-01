// plastic_factory_management/lib/presentation/management/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/user_usecases.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart'; // Ensure UserRole enum and extension are correctly defined here
import 'package:plastic_factory_management/theme/app_colors.dart'; // Ensure AppColors defines your primary, secondary, etc.
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final userUseCases = Provider.of<UserUseCases>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.userManagement), // Localized title
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor, // Consistent theme color
        foregroundColor: Colors.white, // White text for better contrast
        elevation: 0, // No shadow for a cleaner look
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined), // More modern/specific icon
            onPressed: () {
              _showAddEditUserDialog(context, userUseCases, appLocalizations);
            },
            tooltip: appLocalizations.addUser, // Localized tooltip
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: userUseCases.getUsers(),
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
                      appLocalizations.errorLoadingUsers, // Localized
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
                      appLocalizations.noUsersAvailable, // Localized
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.tapToAddFirstUser, // Localized
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddEditUserDialog(context, userUseCases, appLocalizations);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(appLocalizations.addUser), // Localized
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
              final user = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 1, // Increased elevation for prominence
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
                child: InkWell( // Added InkWell for tap feedback
                  onTap: () {
                    // Optional: show user details dialog
                    // _showUserDetailsDialog(context, appLocalizations, user);
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
                            // User Name with icon (الآن على اليسار)
                            Row(
                              textDirection: ui.TextDirection.rtl,
                              children: [
                                Icon(Icons.person_outline, color: AppColors.primary, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  user.name,
                                  textDirection: ui.TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            // User Role badge (الآن على اليمين)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getUserRoleColor(UserRoleExtension.fromString(user.role)).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                UserRoleExtension.fromString(user.role).toArabicString(),
                                style: TextStyle(
                                  color: _getUserRoleColor(UserRoleExtension.fromString(user.role)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 16), // Separator
                        _buildInfoRow(appLocalizations.email, user.email, icon: Icons.email_outlined), // Localized label
                        if (user.employeeId != null && user.employeeId!.isNotEmpty)
                          _buildInfoRow(appLocalizations.employeeId, user.employeeId!, icon: Icons.badge_outlined), // Localized label
                        _buildInfoRow(
                          appLocalizations.termsAcceptedAt,
                          user.termsAcceptedAt != null
                              ? _formatDate(user.termsAcceptedAt!)
                              : appLocalizations.notAcceptedYet,
                          icon: user.termsAcceptedAt != null
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_outlined,
                          textColor: user.termsAcceptedAt != null ? Colors.black87 : Colors.red,
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
                                  _showAddEditUserDialog(context, userUseCases, appLocalizations, user: user);
                                },
                                tooltip: appLocalizations.edit, // Localized
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 22, color: Colors.redAccent),
                                onPressed: () {
                                  _showDeleteConfirmationDialog(context, userUseCases, appLocalizations, user.uid, user.name);
                                },
                                tooltip: appLocalizations.delete, // Localized
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
          _showAddEditUserDialog(context, userUseCases, appLocalizations);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: appLocalizations.addUser, // Localized
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getUserRoleColor(UserRole role) {
    // Define distinct colors for each role for better visual identification
    switch (role) {
      case UserRole.factoryManager:
        return Colors.deepPurple.shade700;
      case UserRole.productionManager:
        return Colors.green.shade700;
      case UserRole.salesRepresentative:
        return Colors.blue.shade700;
      case UserRole.accountant:
        return Colors.orange.shade700;
      case UserRole.inventoryManager:
        return Colors.teal.shade700;
      case UserRole.operationsOfficer:
        return Colors.indigo.shade700;
      case UserRole.productionOrderPreparer:
        return Colors.indigo.shade400;
      case UserRole.moldInstallationSupervisor:
        return Colors.brown.shade700;
      case UserRole.productionShiftSupervisor:
        return Colors.cyan.shade700;
      case UserRole.unknown: // Fallback for unknown or unhandled roles
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
            textDirection: ui.TextDirection.rtl,
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
              textDirection: ui.TextDirection.rtl,
            ),
          ),
        ],
      ),

    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy/MM/dd').format(date);
  }

  void _showAddEditUserDialog(BuildContext context, UserUseCases useCases, AppLocalizations appLocalizations, {UserModel? user}) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController emailController = TextEditingController(text: user?.email ?? '');
    final TextEditingController nameController = TextEditingController(text: user?.name ?? '');
    final TextEditingController employeeIdController = TextEditingController(text: user?.employeeId ?? '');
    final TextEditingController passwordController = TextEditingController();
    UserRole _selectedRole = user != null ? UserRoleExtension.fromString(user.role) : UserRole.productionShiftSupervisor;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isEditing = user != null;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? appLocalizations.editUser : appLocalizations.addUser, // Localized
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.email, // Localized
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return appLocalizations.fieldRequired;
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return appLocalizations.invalidEmailFormat; // New validation
                          return null;
                        },
                        textAlign: TextAlign.right,
                        textDirection: ui.TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.name, // Localized
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right,
                        textDirection: ui.TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: appLocalizations.role, // Localized
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.account_circle_outlined),
                        ),
                        items: UserRole.values
                            .where((r) => r != UserRole.unknown) // Exclude 'unknown'
                            .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.toArabicString(), textDirection: ui.TextDirection.rtl,),
                        ))
                            .toList(),
                        onChanged: (UserRole? newValue) {
                          setState(() {
                            _selectedRole = newValue!;
                          });
                        },
                        validator: (value) => value == null ? appLocalizations.fieldRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: employeeIdController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.employeeId, // Localized
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        textAlign: TextAlign.right,
                        textDirection: ui.TextDirection.rtl,
                      ),
                      if (!isEditing) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: appLocalizations.password, // Localized
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value!.isEmpty) return appLocalizations.fieldRequired;
                            if (value.length < 6) return appLocalizations.passwordTooShort; // New validation
                            return null;
                          },
                          textAlign: TextAlign.right,
                          textDirection: ui.TextDirection.rtl,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text(appLocalizations.cancel), // Localized
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                ),
                ElevatedButton.icon(
                  icon: Icon(isEditing ? Icons.save : Icons.person_add,color: Colors.white,),
                  label: Text(isEditing ? appLocalizations.save : appLocalizations.add), // Localized
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
                          await useCases.updateUser(
                            uid: user!.uid,
                            email: emailController.text,
                            name: nameController.text,
                            role: _selectedRole,
                            employeeId: employeeIdController.text.isEmpty ? null : employeeIdController.text,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(appLocalizations.userUpdatedSuccessfully))); // Localized
                        } else {
                          await useCases.addUser(
                            email: emailController.text,
                            name: nameController.text,
                            role: _selectedRole,
                            password: passwordController.text,
                            employeeId: employeeIdController.text.isEmpty ? null : employeeIdController.text,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(appLocalizations.userAddedSuccessfully))); // Localized
                        }
                        Navigator.of(context).pop(); // Pop the loading indicator
                        Navigator.of(dialogContext).pop(); // Pop the dialog
                      } catch (e) {
                        Navigator.of(context).pop(); // Pop the loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${appLocalizations.errorSavingUser}: ${e.toString()}'))); // Localized
                        print('Error saving user: $e'); // For debugging
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

  void _showDeleteConfirmationDialog(BuildContext context, UserUseCases useCases, AppLocalizations appLocalizations, String uid, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.confirmDeletion, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)), // Localized
          content: Text(
            '${appLocalizations.confirmDeleteUser}: "$name"؟\n\n${appLocalizations.thisActionCannotBeUndone}', // Localized
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: [
            TextButton(
              child: Text(appLocalizations.cancel), // Localized
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever), // More impactful icon
              label: Text(appLocalizations.delete), // Localized
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
                  await useCases.deleteUser(uid);
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations.userDeletedSuccessfully))); // Localized
                } catch (e) {
                  Navigator.of(context).pop(); // Pop loading
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${appLocalizations.errorDeletingUser}: ${e.toString()}'))); // Localized
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