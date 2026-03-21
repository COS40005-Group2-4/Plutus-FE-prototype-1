import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ocr_service.dart';
import '../../widgets/glass_container.dart';
import '../../l10n/app_localizations.dart';
import 'manual_import_tab.dart';

class ScanImportTab extends StatefulWidget {
  const ScanImportTab({super.key});

  @override
  State<ScanImportTab> createState() => _ScanImportTabState();
}

class _ScanImportTabState extends State<ScanImportTab> {
  final OCRService _ocrService = OCRService();
  final ImagePicker _picker = ImagePicker();

  XFile? _imageFile;
  Map<String, dynamic>? _scannedData;
  bool _scanning = false;
  OCRMode _ocrMode = OCRMode.auto;

  @override
  void initState() {
    super.initState();
    // Default to auto mode for all platforms
    _ocrMode = OCRMode.auto;
  }

  Future<void> _pickImage(ImageSource source) async {
    // Platform check removed for file picking to allow Desktop testing (even if OCR lib is limited)
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _imageFile = image;
          _scannedData = null;
        });
        _processImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context).errorPickingImage}$e')));
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;

    setState(() => _scanning = true);

    try {
      final details = await _ocrService.processInvoice(_imageFile!.path, mode: _ocrMode);

      if (details != null && !details.containsKey('error')) {
        // For online OCR (AWS Textract), add context-aware category suggestion
        if (_ocrMode == OCRMode.online || _ocrMode == OCRMode.auto) {
          final detailsWithCategory = _ocrService.processWithCategorySuggestion(details);
          setState(() {
            _scannedData = detailsWithCategory;
          });
        } else {
          setState(() {
            _scannedData = details;
          });
        }
      } else {
        if (mounted) {
          final error = details?['error'] ?? 'Could not read text from image';
          // Show error in a dialog for better visibility
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).ocrError,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Text(error),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context).ok),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).ocrError,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Text('Unexpected error: $e', overflow: TextOverflow.ellipsis),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context).ok),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        opacity: 0.1,
        child: Column(
        children: [
          // OCR Mode Selector
          const Text(
            'OCR Mode',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<OCRMode>(
            segments: [
              ButtonSegment<OCRMode>(
                value: OCRMode.offline,
                label: Text(AppLocalizations.of(context).offline),
                icon: const Icon(Icons.computer),
                enabled: !kIsWeb,
              ),
              ButtonSegment<OCRMode>(
                value: OCRMode.online,
                label: Text(AppLocalizations.of(context).online),
                icon: Icon(Icons.cloud),
              ),
              ButtonSegment<OCRMode>(
                value: OCRMode.auto,
                label: Text(AppLocalizations.of(context).auto),
                icon: const Icon(Icons.auto_mode),
              ),
            ],
            selected: {_ocrMode},
            onSelectionChanged: (Set<OCRMode> newSelection) {
              setState(() {
                _ocrMode = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            _ocrMode == OCRMode.offline
                ? 'Uses TesseractOCR (Vietnamese support)'
                : _ocrMode == OCRMode.online
                    ? 'Uses AWS Textract (requires internet & AWS config)'
                    : 'Automatically chooses best option',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          if (!kIsWeb && Platform.isWindows && _ocrMode == OCRMode.offline)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              'Windows Offline Mode',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Requires Tesseract OCR installed and added to PATH.\n'
                      'Vietnamese language data (vie.traineddata) must be in tessdata folder.',
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Replaced Camera with File Picker focus as requested
              ElevatedButton.icon(
                onPressed: _scanning ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.image),
                label: Text(AppLocalizations.of(context).selectInvoiceImage),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_imageFile != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: kIsWeb
                    ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                    : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),

          if (_scannedData != null) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Review & Edit Scanned Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ManualImportTab(
              initialData: _scannedData,
              onSuccess: () {
                // Auto-redirect to dashboard after successful OCR entry
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    Navigator.of(context).pop(true);
                  }
                });
              },
            ),
          ]
        ],
      ),
      ),
    );
  }
}
