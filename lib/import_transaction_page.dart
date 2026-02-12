import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'services/ocr_service.dart';
import 'transaction_service.dart';
import 'widgets/glass_container.dart';
import 'providers/auth_provider.dart';
import 'l10n/app_localizations.dart';

class ImportTransactionPage extends StatefulWidget {
  const ImportTransactionPage({super.key});

  @override
  State<ImportTransactionPage> createState() => _ImportTransactionPageState();
}

class _ImportTransactionPageState extends State<ImportTransactionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).importTransaction),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.edit), text: AppLocalizations.of(context).manual),
            Tab(icon: const Icon(Icons.upload_file), text: AppLocalizations.of(context).file),
            Tab(icon: const Icon(Icons.camera_alt), text: AppLocalizations.of(context).scanOcr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ManualImportTab(),
          const FileImportTab(),
          const ScanImportTab(),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Manual Import Tab (Reusable Form)
// -----------------------------------------------------------------------------

class ManualImportTab extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback? onSuccess;

  const ManualImportTab({super.key, this.initialData, this.onSuccess});

  @override
  State<ManualImportTab> createState() => _ManualImportTabState();
}

class _ManualImportTabState extends State<ManualImportTab> {
  final _formKey = GlobalKey<FormState>();
  late TransactionService _service;
  
  late TextEditingController _payeeController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _descController;
  
  String _type = 'expense';
  String _currency = 'VND';
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  
  // Child items (splits)
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _service = TransactionService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      _service.setCurrentUser(authProvider.currentUserId!);
    }
    _initControllers();
  }

  void _initControllers() {
    final data = widget.initialData ?? {};
    _payeeController = TextEditingController(text: data['payee']?.toString() ?? '');
    _amountController = TextEditingController(text: data['amount']?.toString() ?? '');
    _categoryController = TextEditingController(text: data['category']?.toString() ?? '');
    _descController = TextEditingController(text: data['description']?.toString() ?? '');
    
    if (data['type'] != null) {
      _type = data['type'].toString().toLowerCase();
    }
    
    // Set currency from data or default to VND
    final currencyFromData = data['currency']?.toString().toUpperCase() ?? 'VND';
    if (['VND', 'USD', 'EUR'].contains(currencyFromData)) {
      _currency = currencyFromData;
    } else {
      _currency = 'VND'; // Default if invalid currency
    }
    
    if (data['date'] != null) {
      try {
        _selectedDate = DateTime.parse(data['date']);
      } catch (e) {
        // ignore invalid date
      }
    }
    
    if (data['items'] != null && data['items'] is List) {
      _items = List<Map<String, dynamic>>.from(data['items']);
    } else {
      _items = [];
    }
  }
  
  @override
  void didUpdateWidget(ManualImportTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      _initControllers();
    }
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add({
        'description': '',
        'amount': 0.0,
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }
  
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      double amount = double.tryParse(_amountController.text) ?? 0.0;
      
      // Determine account name from category or use default
      String accountName = 'Cash'; // Default account
      String categoryPath = _categoryController.text.trim();
      
      // If category is empty, use default
      if (categoryPath.isEmpty) {
        categoryPath = _type == 'expense' ? 'Other' : 'General';
      }
      
      // Build account paths following P1:P2:P3 format
      String assetAccount = 'Assets:$accountName';
      String categoryAccount = _type == 'expense' 
          ? 'Expenses:$categoryPath' 
          : 'Income:$categoryPath';
      
      // Create postings for double-entry accounting
      List<Map<String, dynamic>> postings = [];
      
      if (_type == 'expense') {
        // For expense: deduct from asset, add to expense
        postings.add({
          'account': assetAccount,
          'amount': -amount.abs(),
          'commodity': _currency,
        });
        postings.add({
          'account': categoryAccount,
          'amount': amount.abs(),
          'commodity': _currency,
        });
      } else {
        // For income: add to asset, deduct from income source
        postings.add({
          'account': assetAccount,
          'amount': amount.abs(),
          'commodity': _currency,
        });
        postings.add({
          'account': categoryAccount,
          'amount': -amount.abs(),
          'commodity': _currency,
        });
      }
      
      // Add child items as additional postings if present
      if (_items.isNotEmpty) {
        double totalItemsAmount = 0.0;
        for (final item in _items) {
          final itemAmount = (item['amount'] as num?)?.toDouble() ?? 0.0;
          if (itemAmount > 0) {
            final itemDesc = item['description'] as String? ?? 'Item';
            String itemAccount = _type == 'expense'
                ? 'Expenses:$categoryPath:$itemDesc'
                : 'Income:$categoryPath:$itemDesc';
            
            // Add child item posting
            postings.add({
              'account': itemAccount,
              'amount': _type == 'expense' ? itemAmount.abs() : -itemAmount.abs(),
              'commodity': _currency,
            });
            totalItemsAmount += itemAmount;
          }
        }
        
        // Adjust the parent category posting to maintain balance
        if (totalItemsAmount > 0 && postings.length > 2) {
          // Remove the original category posting
          postings.removeAt(1);
        }
      }

      final transaction = {
        'date': _selectedDate.toIso8601String(),
        'payee': _payeeController.text,
        'description': _descController.text,
        'postings': postings,
        // Keep flat fields for backward compatibility
        'amount': _type == 'expense' ? -amount.abs() : amount.abs(),
        'currency': _currency,
        'type': _type,
        'category': categoryAccount,
        'account': assetAccount,
      };
      
      await _service.importTransaction(transaction);
      
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).transactionSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          // Auto-redirect to dashboard after successful manual entry
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).errorSaving}$e')),
        );
      }
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
        child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            
            // Payee
            TextFormField(
              controller: _payeeController,
              decoration: const InputDecoration(
                labelText: 'Payee',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Amount & Currency
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'VND', child: Text(AppLocalizations.of(context).vnd)),
                      DropdownMenuItem(value: 'USD', child: Text(AppLocalizations.of(context).usd)),
                      DropdownMenuItem(value: 'EUR', child: Text(AppLocalizations.of(context).eur)),
                    ],
                    onChanged: (val) => setState(() => _currency = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Type Dropdown
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'income', child: Text(AppLocalizations.of(context).income)),
                DropdownMenuItem(value: 'expense', child: Text(AppLocalizations.of(context).expense)),
              ],
              onChanged: (val) => setState(() => _type = val!),
            ),
            const SizedBox(height: 16),
            
            // Category
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                helperText: 'e.g., Food, Transportation, Salary, etc.',
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description / Note',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Items Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).itemsSplits,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_circle),
                  color: Colors.blue,
                ),
              ],
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: item['description'],
                            decoration: const InputDecoration(
                              labelText: 'Item Name',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => item['description'] = val,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: item['amount'].toString(),
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (val) {
                               item['amount'] = double.tryParse(val) ?? 0.0;
                               // Optional: _updateTotalFromItems();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _removeItem(index),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            
            // Save Button
            ElevatedButton(
              onPressed: _loading ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(AppLocalizations.of(context).saveTransaction),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// File Import Tab
// -----------------------------------------------------------------------------

class FileImportTab extends StatefulWidget {
  const FileImportTab({super.key});

  @override
  State<FileImportTab> createState() => _FileImportTabState();
}

class _FileImportTabState extends State<FileImportTab> {
  late TransactionService _service;
  String? _fileName;
  String? _filePath;
  bool _loading = false;
  
  @override
  void initState() {
    super.initState();
    _service = TransactionService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      _service.setCurrentUser(authProvider.currentUserId!);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv', 'xml', 'ledger', 'txt'],
    );

    if (result != null) {
      final file = result.files.single;
      
      setState(() {
        _fileName = file.name;
        _filePath = file.path;
      });
    }
  }

  Future<void> _importFile() async {
    if (_filePath == null) return;
    
    setState(() => _loading = true);
    try {
      if (kDebugMode) {
        print('Starting file import: $_filePath');
      }
      
      await _service.importTransactionFile(_filePath!);
      
      if (kDebugMode) {
        print('File import completed successfully');
      }
      
      setState(() {
        _loading = false;
        _fileName = null;
        _filePath = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).fileImportedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        // Return true to signal successful import
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('File import error: $e');
      }
      
      setState(() => _loading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorImportingFile}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        opacity: 0.1,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Import Transaction File',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a transaction file to import into the database. The backend will process and store the transactions.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loading ? null : _pickFile,
            icon: const Icon(Icons.folder_open),
            label: Text(AppLocalizations.of(context).selectFile),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          if (_fileName != null) ...[
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(12),
              borderRadius: 8,
              opacity: 0.15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected File:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(_fileName!, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _importFile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: _loading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(AppLocalizations.of(context).importFile, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Scan (OCR) Tab
// -----------------------------------------------------------------------------

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
        setState(() {
          _scannedData = details;
        });
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
