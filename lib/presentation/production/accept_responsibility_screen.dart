import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';

import 'package:plastic_factory_management/core/services/file_upload_service.dart';
import 'package:plastic_factory_management/data/models/production_order_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/production_order_usecases.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class AcceptResponsibilityScreen extends StatefulWidget {
  final ProductionOrderModel order;
  final String stageName;
  final UserModel currentUser;
  final bool requiresSignature;

  const AcceptResponsibilityScreen({
    Key? key,
    required this.order,
    required this.stageName,
    required this.currentUser,
    required this.requiresSignature,
  }) : super(key: key);

  @override
  State<AcceptResponsibilityScreen> createState() => _AcceptResponsibilityScreenState();
}

class _AcceptResponsibilityScreenState extends State<AcceptResponsibilityScreen> {
  final ImagePicker _picker = ImagePicker();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  final FileUploadService _uploadService = FileUploadService();

  final TextEditingController _notesController = TextEditingController();
  List<File> _pickedImages = [];

  @override
  void dispose() {
    _signatureController.dispose();
    _notesController.dispose();
    super.dispose();
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
    if (_signatureController.isEmpty) return null;
    return await _signatureController.toPngBytes();
  }

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

  Future<void> _submit() async {
    final appLocalizations = AppLocalizations.of(context)!;
    final useCases = Provider.of<ProductionOrderUseCases>(context, listen: false);
    if (widget.requiresSignature && _signatureController.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(appLocalizations.signatureRequired)));
      return;
    }
    Uint8List? signatureBytes;
    if (widget.requiresSignature) {
      signatureBytes = await _exportSignature();
    }
    try {
      String? signatureUrl;
      if (signatureBytes != null) {
        final ref = await _uploadFile(
          bytes: signatureBytes,
          path: 'signatures/${widget.order.id}_${widget.stageName}_${DateTime.now().microsecondsSinceEpoch}.png',
        );
        signatureUrl = ref?.toString();
      }
      await useCases.acceptStageResponsibility(
        order: widget.order,
        stageName: widget.stageName,
        responsibleUser: widget.currentUser,
        signatureImageUrl: signatureUrl,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        attachments: _pickedImages,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appLocalizations.stageAcceptedSuccessfully}: ${widget.stageName}')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appLocalizations.errorAcceptingStage}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${appLocalizations.acceptResponsibility}: ${widget.stageName}'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: appLocalizations.addNotes,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(appLocalizations.camera),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: Text(appLocalizations.gallery),
                  ),
                ],
              ),
              if (_pickedImages.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(appLocalizations.attachedImages,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
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
                            child: const CircleAvatar(
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
              const SizedBox(height: 16),
              if (widget.requiresSignature) ...[
                Text(appLocalizations.customerSignature,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _signatureController.clear(),
                    child: Text(appLocalizations.clearSignature),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(appLocalizations.acceptResponsibility),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
