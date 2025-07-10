// plastic_factory_management/lib/presentation/production/production_order_detail_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/core/services/file_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/production_order_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'package:plastic_factory_management/domain/usecases/production_order_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/machinery_operator_usecases.dart';
import 'package:plastic_factory_management/data/models/template_model.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/domain/usecases/production_daily_log_usecases.dart';
import 'package:plastic_factory_management/data/models/production_daily_log_model.dart';
import 'package:intl/intl.dart' as intl;
import 'package:image_picker/image_picker.dart'; // لإرفاق الصور
import 'package:signature/signature.dart'; // للتوقيع الرقمي
import 'dart:io'; // لاستخدام File
import 'dart:typed_data'; // لاستخدام Uint8List
import 'package:flutter/foundation.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';
import 'package:plastic_factory_management/domain/usecases/shift_handover_usecases.dart';
import 'package:plastic_factory_management/data/models/shift_handover_model.dart';
import 'package:plastic_factory_management/domain/usecases/user_usecases.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/domain/usecases/sales_usecases.dart';
import 'accept_responsibility_screen.dart';

// شاشة تفاصيل طلب الإنتاج
class ProductionOrderDetailScreen extends StatefulWidget {
  final ProductionOrderModel order;

  const ProductionOrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  _ProductionOrderDetailScreenState createState() => _ProductionOrderDetailScreenState();
}

class _ProductionOrderDetailScreenState extends State<ProductionOrderDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  List<File> _pickedImages = [];
  final FileUploadService _uploadService = FileUploadService();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  String? _rejectionReason; // For delay justification
  TemplateModel? _template;
  MachineModel? _machine;
  SalesOrderModel? _salesOrder;

  @override
  void initState() {
    super.initState();
    final inventoryUseCases =
        Provider.of<InventoryUseCases>(context, listen: false);
    final machineryUseCases =
        Provider.of<MachineryOperatorUseCases>(context, listen: false);

    if (widget.order.templateId != null) {
      inventoryUseCases
          .getTemplateById(widget.order.templateId!)
          .then((value) {
        if (mounted) setState(() => _template = value);
      });
    }
    if (widget.order.machineId != null) {
      machineryUseCases.getMachineById(widget.order.machineId!).then((value) {
        if (mounted) setState(() => _machine = value);
      });
    }
    if (widget.order.salesOrderId != null) {
      final salesUseCases =
          Provider.of<SalesUseCases>(context, listen: false);
      salesUseCases
          .getSalesOrderById(widget.order.salesOrderId!)
          .then((value) {
        if (mounted) setState(() => _salesOrder = value);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _pickedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<Uint8List?> _exportSignature() async {
    if (_signatureController.isEmpty) {
      return null;
    }
    final Uint8List? data = await _signatureController.toPngBytes();
    return data;
  }


  // Function to determine if a stage is awaiting action by the current user
  bool _isStageAwaitingCurrentUserAction(
      ProductionWorkflowStage stage, UserModel currentUser) {
    if (stage.status == 'pending') {
      if (stage.stageName == 'استلام مشرف تركيب القوالب' && currentUser.userRoleEnum == UserRole.moldInstallationSupervisor) {
        return true;
      }
      if (stage.stageName == 'بدء الإنتاج' && currentUser.userRoleEnum == UserRole.productionShiftSupervisor) {
        return true;
      }
      if (stage.stageName == 'انتهاء الإنتاج' && currentUser.userRoleEnum == UserRole.productionShiftSupervisor) {
        return true;
      }
      if (stage.stageName == 'تسليم للمخزون' && currentUser.userRoleEnum == UserRole.productionShiftSupervisor) {
        return true;
      }
    }
    // Also consider if the stage is 'in_progress' and assigned to operator for 'start'/'complete'
    if (stage.status == 'in_progress' && stage.assignedToUid == currentUser.uid) {
      if (stage.stageName == 'بدء الإنتاج' && currentUser.userRoleEnum == UserRole.machineOperator) {
        return true;
      }
    }
    return false;
  }


  // Main action button based on current stage and user role
  Widget _buildActionButton(AppLocalizations appLocalizations, ProductionOrderModel order, UserModel currentUser, ProductionOrderUseCases useCases) {
    final currentActiveStage = order.workflowStages.lastWhere(
          (stage) => stage.status == 'pending' || stage.status == 'accepted' || stage.status == 'in_progress',
      orElse: () => ProductionWorkflowStage(stageName: 'completed', status: 'completed'),
    );

    // If order is completed or rejected, no action button
    if (order.status == ProductionOrderStatus.completed || order.status == ProductionOrderStatus.rejected || order.status == ProductionOrderStatus.canceled) {
      return SizedBox.shrink();
    }

    // Mold Installation Supervisor actions
    if (currentUser.userRoleEnum == UserRole.moldInstallationSupervisor && currentActiveStage.stageName == 'استلام مشرف تركيب القوالب' && currentActiveStage.status == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () async {
              final accepted = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AcceptResponsibilityScreen(
                    order: order,
                    stageName: 'استلام مشرف تركيب القوالب',
                    currentUser: currentUser,
                    requiresSignature: true,
                  ),
                ),
              );
              if (accepted == true) setState(() {});
            },
            child: Text(appLocalizations.acceptResponsibility),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => _showRejectStageDialog(context, order, 'استلام مشرف تركيب القوالب', currentUser, useCases),
            child: Text(appLocalizations.reject),
          ),
        ],
      );
    }
    if (currentUser.userRoleEnum == UserRole.moldInstallationSupervisor && currentActiveStage.stageName == 'استلام مشرف تركيب القوالب' && currentActiveStage.status == 'accepted') {
      return ElevatedButton(
        onPressed: () => _showCompleteStageDialog(context, order, 'تركيب القالب', currentUser, useCases, false, false, true, true),
        child: Text(appLocalizations.handoverToShiftSupervisor),
      );
    }

    // Production Shift Supervisor actions
    if (currentUser.userRoleEnum == UserRole.productionShiftSupervisor && currentActiveStage.stageName == 'بدء الإنتاج' && currentActiveStage.status == 'pending') {
      return ElevatedButton(
        onPressed: () => _showStartProductionDialog(context, order, 'بدء الإنتاج', currentUser, useCases),
        child: Text('بدء الإنتاج'), // Add to ARB
      );
    }
    if (currentUser.userRoleEnum == UserRole.productionShiftSupervisor && currentActiveStage.stageName == 'انتهاء الإنتاج' && currentActiveStage.status == 'pending') {
      return ElevatedButton(
        onPressed: () => _showCompleteStageDialog(context, order, 'انتهاء الإنتاج', currentUser, useCases, false),
        child: Text('إتمام الإنتاج'), // Add to ARB
      );
    }
    if (currentUser.userRoleEnum == UserRole.productionShiftSupervisor && currentActiveStage.stageName == 'تسليم للمخزون' && currentActiveStage.status == 'pending') {
      return ElevatedButton(
        onPressed: () => _showCompleteStageDialog(context, order, 'تسليم للمخزون', currentUser, useCases, true), // Signature for inventory handoff
        child: Text('تسليم للمخزون'), // Add to ARB
      );
    }

    // Machine Operator actions (if assigned to this order's current stage)
    if (currentUser.userRoleEnum == UserRole.machineOperator &&
        currentActiveStage.assignedToUid == currentUser.uid &&
        currentActiveStage.stageName == 'بدء الإنتاج' && currentActiveStage.status == 'in_progress') {
      return ElevatedButton(
        onPressed: () => _showCompleteStageDialog(context, order, 'بدء الإنتاج', currentUser, useCases, false, true), // Operator completes their part of 'بدء الإنتاج'
        child: Text('إنهاء عمل المكينة'), // Add to ARB
      );
    }

    return SizedBox.shrink(); // No action button for other roles or stages
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final currentUser = Provider.of<UserModel?>(context);
    final productionUseCases = Provider.of<ProductionOrderUseCases>(context);
    final logUseCases = Provider.of<ProductionDailyLogUseCases>(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(appLocalizations.productionOrderManagement)),
        body: Center(child: Text('لا يمكن عرض التفاصيل بدون بيانات المستخدم.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${appLocalizations.productionOrder}: ${widget.order.batchNumber}'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(appLocalizations.product, widget.order.productName,
                icon: Icons.inventory_2),
            _buildDetailRow(appLocalizations.requiredQuantity, widget.order.requiredQuantity.toString(),
                icon: Icons.format_list_numbered),
            _buildDetailRow(appLocalizations.batchNumber, widget.order.batchNumber,
                icon: Icons.confirmation_number),
            _buildDetailRow(appLocalizations.orderPreparer, widget.order.orderPreparerName,
                icon: Icons.person),
            _buildDetailRow(appLocalizations.moldInstallationSupervisor,
                widget.order.moldSupervisorName ?? '-',
                icon: Icons.person_pin),
            _buildDetailRow(appLocalizations.shiftSupervisor,
                widget.order.shiftSupervisorName ?? '-',
                icon: Icons.supervisor_account_outlined),
            if (_template != null) ...[
              const SizedBox(height: 8),
              Text(appLocalizations.templateDetails,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _buildDetailRow(appLocalizations.templateName, _template!.name,
                  icon: Icons.dashboard_customize_outlined),
              _buildSubDetailRow(appLocalizations.templateCode, _template!.code),
              _buildSubDetailRow(appLocalizations.templateWeight,
                  _template!.weight.toString()),
              _buildSubDetailRow(appLocalizations.templateHourlyCost,
                  _template!.costPerHour.toString()),
            ],
            if (_machine != null) ...[
              const SizedBox(height: 8),
              Text(appLocalizations.machineDetails,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _buildDetailRow(appLocalizations.machineName, _machine!.name,
                  icon: Icons.precision_manufacturing_outlined),
              _buildSubDetailRow(appLocalizations.machineID, _machine!.machineId),
              if (_machine!.details != null && _machine!.details!.isNotEmpty)
                _buildSubDetailRow(
                    appLocalizations.machineDetails, _machine!.details!),
            ],
            _buildDetailRow(appLocalizations.status, widget.order.status.toArabicString(),
                textColor: _getStatusColor(widget.order.status), isBold: true, icon: Icons.info_outline),
            _buildDetailRow('تاريخ الإنشاء',
                intl.DateFormat('yyyy-MM-dd HH:mm').format(widget.order.createdAt.toDate()),
                icon: Icons.date_range),
            if (widget.order.rejectionReason != null && widget.order.rejectionReason!.isNotEmpty)
              _buildDetailRow(appLocalizations.rejectionReason, widget.order.rejectionReason!,
                  textColor: Colors.red, icon: Icons.cancel),
            _buildDetailRow(appLocalizations.currentStage, widget.order.currentStage,
                icon: Icons.engineering),

            Divider(height: 32),
            Text(
              '${appLocalizations.productionWorkflowTracking}:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
            SizedBox(height: 16),
            ...widget.order.workflowStages.map((stage) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.stageName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.right,
                      ),
                      _buildSubDetailRow('الحالة', stage.status),
                      if (stage.assignedToName != null)
                        _buildSubDetailRow('المسؤول', stage.assignedToName!),
                      if (stage.machineId != null)
                        _buildSubDetailRow('الآلة', stage.machineId!), // يمكنك جلب اسم الآلة هنا
                      if (stage.startedAt != null)
                        _buildSubDetailRow(appLocalizations.startTime, intl.DateFormat('yyyy-MM-dd HH:mm').format(stage.startedAt!.toDate())),
                      if (stage.completedAt != null)
                        _buildSubDetailRow(appLocalizations.endTime, intl.DateFormat('yyyy-MM-dd HH:mm').format(stage.completedAt!.toDate())),
                      if (stage.actualTimeMinutes != null)
                        _buildSubDetailRow('الوقت الفعلي', '${stage.actualTimeMinutes!.toStringAsFixed(0)} دقيقة'), // Add to ARB
                      if (stage.delayReason != null && stage.delayReason!.isNotEmpty)
                        _buildSubDetailRow(appLocalizations.delayReason, stage.delayReason!),
                      if (stage.notes != null && stage.notes!.isNotEmpty)
                        _buildSubDetailRow(appLocalizations.notes, stage.notes!),
                      if (stage.signatureImageUrl != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('التوقيع:', style: TextStyle(fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Image.network(
                                  stage.signatureImageUrl!,
                                  height: 80,
                                  width: 150,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (stage.attachments.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('المرفقات:', style: TextStyle(fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  textDirection: TextDirection.rtl,
                                  children: stage.attachments.map((url) {
                                    return GestureDetector(
                                      onTap: () {
                                        // TODO: Implement image viewer for full screen
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8.0),
                                        child: Image.network(
                                          url,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            SizedBox(height: 24),
            Text(
              appLocalizations.shiftSupervisorFollowUp,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<ProductionDailyLogModel>>(
              stream: logUseCases.getLogsForOrder(widget.order.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final logs = snapshot.data!;
                if (logs.isEmpty) {
                  return Text(appLocalizations.noData);
                }
                return Column(
                  children: logs.map((log) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              intl.DateFormat('yyyy-MM-dd').format(log.createdAt.toDate()),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                            if (log.counterReading != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('قراءة العداد: ${log.counterReading}',
                                    textAlign: TextAlign.right),
                              ),
                            if (log.notes != null && log.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(log.notes!, textAlign: TextAlign.right),
                              ),
                            if (log.imageUrls.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: log.imageUrls
                                    .map((u) => Image.network(u, width: 60, height: 60))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            if (currentUser.userRoleEnum == UserRole.productionShiftSupervisor &&
                widget.order.status == ProductionOrderStatus.inProduction)
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () => _showAddDailyLogDialog(
                      context, logUseCases, widget.order, currentUser),
                  child: Text(appLocalizations.addFollowUp),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              appLocalizations.shiftHandoverHistory,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<ShiftHandoverModel>>(
              stream: Provider.of<ShiftHandoverUseCases>(context)
                  .getHandoversForOrder(widget.order.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final handovers = snapshot.data!;
                if (handovers.isEmpty) {
                  return Text(appLocalizations.noData);
                }
                return Column(
                  children: handovers.map((h) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                            '${h.fromSupervisorName} ➜ ${h.toSupervisorName}',
                            textAlign: TextAlign.right),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('قراءة العداد: ${h.meterReading}'),
                            if (h.notes != null && h.notes!.isNotEmpty)
                              Text(h.notes!),
                            Text(intl.DateFormat('yyyy-MM-dd HH:mm')
                                .format(h.createdAt.toDate())),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            if (currentUser.userRoleEnum == UserRole.productionShiftSupervisor &&
                widget.order.status == ProductionOrderStatus.inProduction &&
                widget.order.shiftSupervisorUid == currentUser.uid)
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () => _showHandoverDialog(
                      context, widget.order, currentUser),
                  child: Text(appLocalizations.shiftHandover),
                ),
              ),
            SizedBox(height: 24),
            // Action button for the current user based on their role and stage
            Align(
              alignment: Alignment.center, // Center the action button
              child: _buildActionButton(appLocalizations, widget.order, currentUser, productionUseCases),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildDetailRow(String label, String value,
      {Color? textColor, bool isBold = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.7)),
          ],
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
          const SizedBox(width: 8),
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
        ],
      ),
    );
  }

  Widget _buildSubDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
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

  Color _getStatusColor(ProductionOrderStatus status) {
    switch (status) {
      case ProductionOrderStatus.pending:
        return Colors.orange;
      case ProductionOrderStatus.approved:
        return Colors.blue;
      case ProductionOrderStatus.inProduction:
        return Colors.purple;
      case ProductionOrderStatus.completed:
        return Colors.green;
      case ProductionOrderStatus.canceled:
      case ProductionOrderStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }


  Future<void> _showRejectStageDialog(
      BuildContext context,
      ProductionOrderModel order,
      String stageName,
      UserModel currentUser,
      ProductionOrderUseCases useCases,) async {
    final TextEditingController reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final appLocalizations = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(appLocalizations.rejectStageConfirmation),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${appLocalizations.confirmRejectStage} "$stageName"؟'),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: appLocalizations.rejectionReason,
                  border: const OutlineInputBorder(),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(appLocalizations.reject),
              onPressed: () async {
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(appLocalizations.rejectionReasonRequired)),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                try {
                  await useCases.rejectStage(
                    order: order,
                    stageName: stageName,
                    responsibleUser: currentUser,
                    reason: reasonController.text,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.stageRejectedSuccessfully}$stageName')),
                  );
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorRejectingStage}: $e')),
                  );
                  print('Error rejecting stage: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showStartProductionDialog(
      BuildContext context,
      ProductionOrderModel order,
      String stageName,
      UserModel currentUser,
      ProductionOrderUseCases useCases,
      ) async {
    String? selectedMachineId;
    // TODO: Fetch list of available machines from a MachineDatasource

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final appLocalizations = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text('${appLocalizations.startProduction}: ${stageName}'), // Add to ARB
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('اختر الآلة التي سيتم تشغيلها لهذا الطلب:'), // Add to ARB
              // TODO: Replace with actual machine dropdown from fetched data
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'الآلة'),
                items: ['MACH001', 'MACH002', 'MACH003'].map((String machine) { // Dummy machines
                  return DropdownMenuItem(
                    value: machine,
                    child: Text(machine, textDirection: TextDirection.rtl),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  selectedMachineId = newValue;
                },
                validator: (value) => value == null ? 'الآلة مطلوبة' : null, // Add to ARB
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text(appLocalizations.start), // Add to ARB
              onPressed: () async {
                if (selectedMachineId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('يرجى اختيار آلة لبدء الإنتاج.')), // Add to ARB
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                try {
                  await useCases.startProductionStage(
                    order: order,
                    stageName: stageName,
                    responsibleUser: currentUser,
                    machineId: selectedMachineId,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.productionStartedSuccessfully}: $stageName')), // Add to ARB
                  );
                  setState(() {}); // Refresh UI
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorStartingProduction}: $e')), // Add to ARB
                  );
                  print('Error starting production: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _showCompleteStageDialog(
      BuildContext context,
      ProductionOrderModel order,
      String stageName,
      UserModel currentUser,
      ProductionOrderUseCases useCases,
      bool requiresSignature,
      [bool isOperatorCompleting = false,
      bool selectShiftSupervisor = false,
      bool simpleShiftHandover = false]) async {
    _pickedImages.clear();
    _signatureController.clear();
    String? notes;
    String? delayReason;
    double? actualTimeMinutes;
    List<UserModel> supervisors = [];
    UserModel? selectedSupervisor;

    // Calculate expected time if needed (from product model)
    final expectedTimeMinutes = order.requiredQuantity * (await Provider.of<ProductionOrderUseCases>(context, listen: false).getProductById(order.productId))!.expectedProductionTimePerUnit;

    if (selectShiftSupervisor) {
      final userUseCases = Provider.of<UserUseCases>(context, listen: false);
      supervisors = await userUseCases.getUsersByRole(UserRole.productionShiftSupervisor);
    }


    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final appLocalizations = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text('${appLocalizations.completeStage}: ${stageName}'), // Add to ARB
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) => notes = value,
                      decoration: InputDecoration(
                        labelText: appLocalizations.addNotes,
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    if (selectShiftSupervisor) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserModel>(
                        items: supervisors
                            .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u.name),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => selectedSupervisor = val),
                        decoration: InputDecoration(
                          labelText: appLocalizations.shiftSupervisor,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    if (!simpleShiftHandover) ...[
                      SizedBox(height: 16),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'الوقت الفعلي المستغرق (بالدقائق)', // Add to ARB
                          hintText: 'مثال: 120',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          actualTimeMinutes = double.tryParse(value);
                          if (actualTimeMinutes != null &&
                              expectedTimeMinutes > 0 &&
                              actualTimeMinutes! > expectedTimeMinutes * 1.1) {
                            // Extra delay field can be shown here
                          }
                        },
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 16),
                      if (actualTimeMinutes != null &&
                          expectedTimeMinutes > 0 &&
                          actualTimeMinutes! > expectedTimeMinutes * 1.1)
                        TextField(
                          onChanged: (value) => delayReason = value,
                          decoration: InputDecoration(
                            labelText: appLocalizations.delayReason,
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () =>
                                _pickImage(ImageSource.camera).then((_) => setState(() {})),
                            icon: Icon(Icons.camera_alt),
                            label: Text(appLocalizations.camera),
                          ),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _pickImage(ImageSource.gallery).then((_) => setState(() {})),
                            icon: Icon(Icons.photo_library),
                            label: Text(appLocalizations.gallery),
                          ),
                        ],
                      ),
                      _pickedImages.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8),
                                Text(appLocalizations.attachedImages,
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  textDirection: TextDirection.rtl,
                                  children: _pickedImages.map((file) {
                                    return Stack(
                                      children: [
                                        Image.file(file,
                                            width: 80, height: 80, fit: BoxFit.cover),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _pickedImages.remove(file);
                                              });
                                            },
                                            child: CircleAvatar(
                                              radius: 10,
                                              backgroundColor: Colors.red,
                                              child:
                                                  Icon(Icons.close, size: 12, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            )
                          : SizedBox.shrink(),
                      SizedBox(height: 16),
                      if (requiresSignature)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appLocalizations.customerSignature,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Signature(
                                controller: _signatureController,
                                height: 150,
                                width: MediaQuery.of(context).size.width,
                                backgroundColor: Colors.grey[100]!,
                              ),
                            ),
                            SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => _signatureController.clear(),
                                child: Text(appLocalizations.clearSignature),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(appLocalizations.cancel),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: Text(appLocalizations.complete), // Add to ARB
                  onPressed: () async {
                    if (requiresSignature && _signatureController.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(appLocalizations.signatureRequired)),
                      );
                      return;
                    }
                    if (!simpleShiftHandover &&
                        (actualTimeMinutes == null || actualTimeMinutes! <= 0)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('الرجاء إدخال الوقت الفعلي المستغرق.')), // Add to ARB
                      );
                      return;
                    }
                    if (selectShiftSupervisor && selectedSupervisor == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(appLocalizations.selectShiftSupervisorError)),
                      );
                      return;
                    }

                    Uint8List? signatureBytes;
                    if (requiresSignature) {
                      signatureBytes = await _exportSignature();
                    }

                    Navigator.of(dialogContext).pop();
                    try {
                      String? signatureUrl;
                      if (signatureBytes != null) {
                        final ref = await _uploadFile(
                          bytes: signatureBytes,
                          path:
                              'signatures/${order.id}_${stageName}_${DateTime.now().microsecondsSinceEpoch}.png',
                        );
                        signatureUrl = ref?.toString();
                      }

                      // Create a copy of the existing stage from the order and update its status
                      final currentStageData = order.workflowStages.firstWhere((s) => s.stageName == stageName);
                      final updatedStage = currentStageData.copyWith(
                        status: 'completed',
                        completedAt: Timestamp.now(),
                        notes: notes,
                        attachments: [
                          ...currentStageData.attachments,
                          if (!simpleShiftHandover)
                            ..._pickedImages.map((e) => e.path)
                        ],
                        delayReason: simpleShiftHandover ? null : delayReason,
                        actualTimeMinutes:
                            simpleShiftHandover ? null : actualTimeMinutes,
                        signatureImageUrl: signatureUrl,
                      );

                      // Now call the use case to update the specific stage
                      await useCases.completeProductionStage(
                        order: order,
                        stageName: stageName,
                        responsibleUser: currentUser,
                        notes: notes,
                        attachments:
                            simpleShiftHandover ? null : _pickedImages,
                        delayReason:
                            simpleShiftHandover ? null : delayReason,
                        actualTimeMinutes:
                            simpleShiftHandover ? null : actualTimeMinutes,
                        shiftSupervisor: selectedSupervisor,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${appLocalizations.stageCompletedSuccessfully}: $stageName')), // Add to ARB
                      );
                      setState(() {}); // Refresh UI
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${appLocalizations.errorCompletingStage}: $e')), // Add to ARB
                      );
                      print('Error completing stage: $e');
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

  Future<void> _showAddDailyLogDialog(BuildContext context,
      ProductionDailyLogUseCases logUseCases, ProductionOrderModel order,
      UserModel currentUser) async {
    final appLocalizations = AppLocalizations.of(context)!;
    List<File> logImages = [];
    String? notes;
    int? counterReading;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(appLocalizations.addFollowUp),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (v) => notes = v,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (v) => counterReading = int.tryParse(v),
                      decoration: const InputDecoration(
                        labelText: 'قراءة العداد',
                        border: OutlineInputBorder(),
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picked =
                                await _picker.pickImage(source: ImageSource.camera);
                            if (picked != null) {
                              setState(() => logImages.add(File(picked.path)));
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('كاميرا'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picked =
                                await _picker.pickImage(source: ImageSource.gallery);
                            if (picked != null) {
                              setState(() => logImages.add(File(picked.path)));
                            }
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('معرض'),
                        ),
                      ],
                    ),
                    if (logImages.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: logImages
                              .map((f) => Image.file(f, width: 60, height: 60))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(appLocalizations.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await logUseCases.addDailyLog(
                      orderId: order.id,
                      supervisorUid: currentUser.uid,
                      supervisorName: currentUser.name,
                      counterReading: counterReading,
                      notes: notes,
                      images: logImages,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations.save)),
                    );
                  },
                  child: Text(appLocalizations.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showHandoverDialog(
      BuildContext context, ProductionOrderModel order, UserModel currentUser) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final userUseCases = Provider.of<UserUseCases>(context, listen: false);
    final handoverUseCases = Provider.of<ShiftHandoverUseCases>(context, listen: false);
    final productionUseCases = Provider.of<ProductionOrderUseCases>(context, listen: false);
    final supervisors = await userUseCases.getUsersByRole(UserRole.productionShiftSupervisor);
    UserModel? selected;
    String? notes;
    double? meter;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(appLocalizations.shiftHandover),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<UserModel>(
                      items: supervisors
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u.name),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => selected = val),
                      decoration: const InputDecoration(
                        labelText: 'إلى المشرف',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (v) => meter = double.tryParse(v),
                      decoration: const InputDecoration(
                        labelText: 'قراءة العداد',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => notes = v,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(appLocalizations.cancel),
                ),
                ElevatedButton(
                  onPressed: selected == null || meter == null
                      ? null
                      : () async {
                          Navigator.of(dialogContext).pop();
                          await handoverUseCases.addHandover(
                            orderId: order.id,
                            fromSupervisor: currentUser,
                            toSupervisor: selected!,
                            meterReading: meter!,
                            notes: notes,
                          );
                          await productionUseCases.updateShiftSupervisor(order, selected!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(appLocalizations.save)),
                          );
                        },
                  child: Text(appLocalizations.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper function to upload file to external server
  Future<Uri?> _uploadFile({File? file, Uint8List? bytes, required String path}) async {
    try {
      String? url;
      if (bytes != null) {
        url = await _uploadService.uploadBytes(bytes, path);
      } else if (file != null) {
        url = await _uploadService.uploadFile(file, path);
      }
      return url != null ? Uri.parse(url) : null;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
}
