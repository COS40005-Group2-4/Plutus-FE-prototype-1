import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:plutus_fe_prototype/services/ocr_service.dart';
import 'transaction_service.dart';

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
        title: const Text('Import Transaction'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Manual'),
            Tab(icon: Icon(Icons.upload_file), text: 'File'),
            Tab(icon: Icon(Icons.camera_alt), text: 'Scan (OCR)'),
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
  final TransactionService _service = TransactionService();
  
  late TextEditingController _payeeController;
  late TextEditingController _amountController;
  late TextEditingController _currencyController;
  late TextEditingController _accountController;
  late TextEditingController _categoryController;
  late TextEditingController _descController;
  
  String _type = 'expense';
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  
  // Child items (splits)
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final data = widget.initialData ?? {};
    _payeeController = TextEditingController(text: data['payee']?.toString() ?? '');
    _amountController = TextEditingController(text: data['amount']?.toString() ?? '');
    _currencyController = TextEditingController(text: data['currency']?.toString() ?? 'VND');
    _accountController = TextEditingController(text: data['account']?.toString() ?? '');
    _categoryController = TextEditingController(text: data['category']?.toString() ?? '');
    _descController = TextEditingController(text: data['description']?.toString() ?? '');
    
    if (data['type'] != null) {
      _type = data['type'].toString().toLowerCase();
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
    _currencyController.dispose();
    _accountController.dispose();
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
  
  void _updateTotalFromItems() {
    double total = 0.0;
    for(var item in _items) {
      total += (item['amount'] as num? ?? 0.0).toDouble();
    }
    if (total > 0) {
      _amountController.text = total.toStringAsFixed(2);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      final transaction = {
        'date': _selectedDate.toIso8601String(),
        'payee': _payeeController.text,
        'description': _descController.text,
        // Using a flatter structure for now, but keeping in mind the backend needs postings
        // Ideally we would structure this as:
        // 'postings': [
        //   {'account': _accountController.text, 'amount': -amount, 'commodity': _currencyController.text},
        //   {'account': _categoryController.text, 'amount': amount, 'commodity': _currencyController.text}
        // ]
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'currency': _currencyController.text,
        'account': _accountController.text,
        'type': _type,
        'category': _categoryController.text,
        'items': _items,
      };
      
      await _service.importTransaction(transaction);
      
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction saved successfully')),
        );
        
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          // Clear form if strictly manual mode
          _amountController.clear();
          _descController.clear();
          // Keep others
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                  child: TextFormField(
                    controller: _currencyController,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
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
              items: const [
                DropdownMenuItem(value: 'income', child: Text('Income')),
                DropdownMenuItem(value: 'expense', child: Text('Expense')),
              ],
              onChanged: (val) => setState(() => _type = val!),
            ),
            const SizedBox(height: 16),
            
            // Account & Category
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _accountController,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
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
                const Text('Items / Splits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => _removeItem(index),
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
                  : const Text('Save Transaction'),
            ),
          ],
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
  final TransactionService _service = TransactionService();
  String? _fileName;
  String? _fileContent;
  String? _fileType; // 'json', 'csv', 'xml'
  List<Map<String, dynamic>> _parsedTransactions = [];
  bool _loading = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv', 'xml'],
    );

    if (result != null) {
      final file = result.files.single;
      final extension = file.extension?.toLowerCase();
      
      setState(() => _loading = true);
      
      try {
        String content;
        if (kIsWeb) {
          content = utf8.decode(file.bytes!);
        } else {
          content = await File(file.path!).readAsString();
        }

        setState(() {
          _fileName = file.name;
          _fileContent = content;
          _fileType = extension;
          _parsedTransactions = [];
        });
        
        await _parseFile();
      } catch (e) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading file: $e')));
        }
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _parseFile() async {
    if (_fileContent == null || _fileType == null) return;
    
    try {
      List<Map<String, dynamic>> result = [];
      if (_fileType == 'json') {
        final parsed = await _service.parseJsonFile(_fileContent!);
        // Handle old format vs new generic list format if needed
        if (parsed.containsKey('transactions')) {
          result = (parsed['transactions'] as List).cast<Map<String, dynamic>>();
        }
      } else if (_fileType == 'csv') {
        result = await _service.parseCsvFile(_fileContent!);
      } else if (_fileType == 'xml') {
        result = await _service.parseXmlFile(_fileContent!);
      }
      
      setState(() {
        _parsedTransactions = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Parse error: $e')));
      }
    }
  }

  Future<void> _importAll() async {
    if (_parsedTransactions.isEmpty) return;
    
    setState(() => _loading = true);
    try {
      for (var t in _parsedTransactions) {
        await _service.importTransaction(t);
      }
      setState(() {
        _loading = false;
        _parsedTransactions = [];
        _fileName = null;
        _fileContent = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All transactions imported!')));
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error importing: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _loading ? null : _pickFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Select File (JSON, CSV, XML)'),
          ),
          if (_fileName != null) ...[
            const SizedBox(height: 8),
            Text('Selected: $_fileName', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 16),
          if (_parsedTransactions.isNotEmpty) ...[
            Text('Found ${_parsedTransactions.length} transactions:'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _parsedTransactions.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final t = _parsedTransactions[index];
                  return ListTile(
                    title: Text('${t['amount']} ${t['currency']} - ${t['payee'] ?? ''}'),
                    subtitle: Text('${t['date']} \n${t['description'] ?? ''}'),
                    isThreeLine: true,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _importAll,
              child: _loading ? const CircularProgressIndicator() : const Text('Import All'),
            ),
          ] else if (_fileContent != null && !_loading)
            const Text('No transactions found or parse failed.'),
        ],
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;
    
    setState(() => _scanning = true);
    
    try {
      final details = await _ocrService.processInvoice(_imageFile!.path);
      
      if (details != null && !details.containsKey('error')) {
        setState(() {
          _scannedData = details;
        });
      } else {
        if (mounted) {
           final error = details?['error'] ?? 'Could not read text from image';
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OCR Error: $e')));
      }
    } finally {
      setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Replaced Camera with File Picker focus as requested
              ElevatedButton.icon(
                onPressed: _scanning ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.image),
                label: const Text('Select Invoice Image'),
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
                setState(() {
                  _imageFile = null;
                  _scannedData = null;
                });
              },
            ),
          ]
        ],
      ),
    );
  }
}
