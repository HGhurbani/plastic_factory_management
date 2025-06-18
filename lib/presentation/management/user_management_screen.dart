// plastic_factory_management/lib/presentation/management/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/user_usecases.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';

class UserManagementScreen extends StatefulWidget {
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
        title: const Text('إدارة المستخدمين'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              _showAddEditUserDialog(context, userUseCases, appLocalizations);
            },
            tooltip: 'إضافة مستخدم',
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
            return Center(child: Text('خطأ في تحميل المستخدمين: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد مستخدمون.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final user = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    user.name,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  subtitle: Text(
                    UserRoleExtension.fromString(user.role).toArabicString(),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showAddEditUserDialog(context, userUseCases, appLocalizations, user: user);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmationDialog(context, userUseCases, appLocalizations, user.uid, user.name);
                        },
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

  void _showAddEditUserDialog(BuildContext context, UserUseCases useCases, AppLocalizations appLocalizations, {UserModel? user}) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController emailController = TextEditingController(text: user?.email ?? '');
    final TextEditingController nameController = TextEditingController(text: user?.name ?? '');
    final TextEditingController employeeIdController = TextEditingController(text: user?.employeeId ?? '');
    final TextEditingController passwordController = TextEditingController();
    UserRole role = user != null ? UserRoleExtension.fromString(user.role) : UserRole.productionShiftSupervisor;

    showDialog(
      context: context,
      builder: (context) {
        final isEditing = user != null;
        return AlertDialog(
          title: Text(isEditing ? 'تعديل مستخدم' : 'إضافة مستخدم'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                    validator: (value) => value!.isEmpty ? 'هذا الحقل مطلوب' : null,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم'),
                    validator: (value) => value!.isEmpty ? 'هذا الحقل مطلوب' : null,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'الدور'),
                    items: UserRole.values
                        .where((r) => r != UserRole.unknown)
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.toArabicString(), textDirection: TextDirection.rtl),
                            ))
                        .toList(),
                    onChanged: (r) => role = r!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: employeeIdController,
                    decoration: const InputDecoration(labelText: 'رقم الموظف'),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  if (!isEditing) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'كلمة المرور'),
                      obscureText: true,
                      validator: (value) => value!.isEmpty ? 'هذا الحقل مطلوب' : null,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(isEditing ? 'حفظ' : 'إضافة'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    if (isEditing) {
                      await useCases.updateUser(
                        uid: user!.uid,
                        email: emailController.text,
                        name: nameController.text,
                        role: role,
                        employeeId: employeeIdController.text.isEmpty ? null : employeeIdController.text,
                      );
                    } else {
                      await useCases.addUser(
                        email: emailController.text,
                        name: nameController.text,
                        role: role,
                        password: passwordController.text,
                        employeeId: employeeIdController.text.isEmpty ? null : employeeIdController.text,
                      );
                    }
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, UserUseCases useCases, AppLocalizations appLocalizations, String uid, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف المستخدم "$name"؟'),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('حذف'),
              onPressed: () async {
                try {
                  await useCases.deleteUser(uid);
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                }
              },
            ),
          ],
        );
      },
    );
  }
}
