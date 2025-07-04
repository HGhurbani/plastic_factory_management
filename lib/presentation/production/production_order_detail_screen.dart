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
import 'package:intl/intl.dart' as intl;
import 'package:image_picker/image_picker.dart'; // لإرفاق الصور
import 'package:signature/signature.dart'; // للتوقيع الرقمي
import 'dart:io'; // لاستخدام File
import 'dart:typed_data'; // لاستخدام Uint8List
import 'package:flutter/foundation.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';

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
      if (stage.stageName == 'تسليم القالب لمشرف الإنتاج' && currentUser.userRoleEnum == UserRole.productionShiftSupervisor) {
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
            onPressed: () => _showAcceptResponsibilityDialog(context, order, 'استلام مشرف تركيب القوالب', currentUser, useCases, true),
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
        onPressed: () => _showCompleteStageDialog(context, order, 'تركيب القالب', currentUser, useCases, false), // No signature for this
        child: Text('إتمام تركيب القالب'), // Add to ARB
      );
    }

    // Production Shift Supervisor actions
    if (currentUser.userRoleEnum == UserRole.productionShiftSupervisor && currentActiveStage.stageName == 'تسليم القالب لمشرف الإنتاج' && currentActiveStage.status == 'pending') {
      return ElevatedButton(
        onPressed: () => _showAcceptResponsibilityDialog(context, order, 'تسليم القالب لمشرف الإنتاج', currentUser, useCases, true),
        child: Text(appLocalizations.acceptResponsibility),
      );
    }
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
            if (_template != null) ...[
              const SizedBox(height: 8),
              Text(appLocalizations.templateDetails,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _buildDetailRow(appLocalizations.templateName, _template!.name,
                  icon: Icons.dashboard_customize_outlined),
              _buildSubDetailRow(appLocalizations.templateCode, _template!.code),
              _buildSubDetailRow(appLocalizations.timeRequired,
                  _template!.timeRequired.toString()),
              _buildSubDetailRow(appLocalizations.percentage,
                  _template!.percentage.toString()),
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
            // Action button for the current user based on their role and stage
            Align(
              alignment: Alignment.center, // Center the action button
              child: _buildActionButton(appLocalizations, widget.order, currentUser, productionUseCases),
            ),
          ],
        ),
      ),
      ), );
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
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

  // --- Dialogs for Workflow Actions ---

  Future<void> _showAcceptResponsibilityDialog(
      BuildContext context,
      ProductionOrderModel order,
      String stageName,
      UserModel currentUser,
      ProductionOrderUseCases useCases,
      bool requiresSignature,
      ) async {
    _pickedImages.clear(); // Clear previous selections
    _signatureController.clear();
    String? notes;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final appLocalizations = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text('${appLocalizations.acceptResponsibility}: ${stageName}'),
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
                    SizedBox(height: 16),
                    // Image picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera).then((_) => setState(() {})),
                          icon: Icon(Icons.camera_alt),
                          label: Text(appLocalizations.camera), // Add to ARB
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery).then((_) => setState(() {})),
                          icon: Icon(Icons.photo_library),
                          label: Text(appLocalizations.gallery), // Add to ARB
                        ),
                      ],
                    ),
                    _pickedImages.isNotEmpty
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text(appLocalizations.attachedImages, style: TextStyle(fontWeight: FontWeight.bold)), // Add to ARB
                        SizedBox(height: 4),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          textDirection: TextDirection.rtl,
                          children: _pickedImages.map((file) {
                            return Stack(
                              children: [
                                Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
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
                                      child: Icon(Icons.close, size: 12, color: Colors.white),
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
                          Text(appLocalizations.customerSignature, style: TextStyle(fontWeight: FontWeight.bold)), // Reuse text
                          SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Signature(
                              controller: _signatureController,
                              height: 150,
                              backgroundColor: Colors.grey[100]!,
                            ),
                          ),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => _signatureController.clear(),
                              child: Text(appLocalizations.clearSignature), // Add to ARB
                            ),
                          ),
                        ],
                      ),
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
                  child: Text(appLocalizations.acceptResponsibility),
                  onPressed: () async {
                    if (requiresSignature && _signatureController.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(appLocalizations.signatureRequired)), // Add to ARB
                      );
                      return;
                    }
                    Uint8List? signatureBytes;
                    if (requiresSignature) {
                      signatureBytes = await _exportSignature();
                    }

                    Navigator.of(dialogContext).pop(); // Dismiss dialog
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

                      await useCases.acceptStageResponsibility(
                        order: order,
                        stageName: stageName,
                        responsibleUser: currentUser,
                        signatureImageUrl: signatureUrl,
                        notes: notes,
                        attachments: _pickedImages,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${appLocalizations.stageAcceptedSuccessfully}: $stageName')), // Add to ARB
                      );
                      // Refresh the current order details to show updated workflow
                      setState(() {
                        // This will trigger a re-build of the current screen to show updated order state
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${appLocalizations.errorAcceptingStage}: $e')), // Add to ARB
                      );
                      print('Error accepting stage: $e');
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
      [bool isOperatorCompleting = false] // New parameter for operator specific completion
      ) async {
    _pickedImages.clear();
    _signatureController.clear();
    String? notes;
    String? delayReason;
    double? actualTimeMinutes;

    // Calculate expected time if needed (from product model)
    final expectedTimeMinutes = order.requiredQuantity * (await Provider.of<ProductionOrderUseCases>(context, listen: false).getProductById(order.productId))!.expectedProductionTimePerUnit;


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
                        // Optional: Trigger delay reason prompt if actualTime > expectedTime * threshold
                        if (actualTimeMinutes != null && expectedTimeMinutes > 0 && actualTimeMinutes! > expectedTimeMinutes * 1.1) {
                          // If actual time is more than 10% over expected
                          // You can show a specific field or dialog for delayReason here
                        }
                      },
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 16),
                    if (actualTimeMinutes != null && expectedTimeMinutes > 0 && actualTimeMinutes! > expectedTimeMinutes * 1.1)
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
                    // Image picker (similar to accept responsibility)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera).then((_) => setState(() {})),
                          icon: Icon(Icons.camera_alt),
                          label: Text(appLocalizations.camera),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery).then((_) => setState(() {})),
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
                        Text(appLocalizations.attachedImages, style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          textDirection: TextDirection.rtl,
                          children: _pickedImages.map((file) {
                            return Stack(
                              children: [
                                Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
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
                                      child: Icon(Icons.close, size: 12, color: Colors.white),
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
                          Text(appLocalizations.customerSignature, style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Signature(
                              controller: _signatureController,
                              height: 150,
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
                    if (actualTimeMinutes == null || actualTimeMinutes! <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('الرجاء إدخال الوقت الفعلي المستغرق.')), // Add to ARB
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
                        status: 'completed', // Or appropriate status for operator completion
                        completedAt: Timestamp.now(),
                        notes: notes,
                        attachments: [...currentStageData.attachments, ..._pickedImages.map((e) => e.path)], // Need to upload these files
                        delayReason: delayReason,
                        actualTimeMinutes: actualTimeMinutes,
                        signatureImageUrl: signatureUrl,
                      );

                      // Now call the use case to update the specific stage
                      await useCases.completeProductionStage(
                        order: order,
                        stageName: stageName,
                        responsibleUser: currentUser,
                        notes: notes,
                        attachments: _pickedImages, // Pass files directly, useCase will upload
                        delayReason: delayReason,
                        actualTimeMinutes: actualTimeMinutes,
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