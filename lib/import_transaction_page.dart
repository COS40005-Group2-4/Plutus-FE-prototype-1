import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'transaction_service.dart';

class ImportTransactionPage extends StatefulWidget {
  const ImportTransactionPage({super.key});

  @override
  State<ImportTransactionPage> createState() => _ImportTransactionPageState();
}

class _ImportTransactionPageState extends State<ImportTransactionPage> {
  final TransactionService _service = TransactionService();
  String? _fileContent;
  Map<String, dynamic>? _parsedData;
  bool _loading = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final file = result.files.single;
      if (file.bytes != null) {
        setState(() {
          _fileContent = utf8.decode(file.bytes!);
          _parsedData = null;
        });
      } else if (file.path != null) {
        final fileData = File(file.path!);
        final bytes = await fileData.readAsBytes();
        setState(() {
          _fileContent = utf8.decode(bytes);
          _parsedData = null;
        });
      }
    }
  }

  Future<void> _parseFile() async {
    if (_fileContent == null) return;
    
    setState(() => _loading = true);
    try {
      final parsed = await _service.parseJsonFile(_fileContent!);
      setState(() {
        _parsedData = parsed;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing file: $e')),
        );
      }
    }
  }

  Future<void> _importTransactions() async {
    if (_parsedData == null || _parsedData!['transactions'] == null) return;
    
    setState(() => _loading = true);
    try {
      final transactions = _parsedData!['transactions'] as List;
      for (var transaction in transactions) {
        await _service.importTransaction(transaction as Map<String, dynamic>);
      }
      setState(() => _loading = false);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transactions imported successfully')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Select JSON File'),
            ),
            const SizedBox(height: 16),
            if (_fileContent != null) ...[
              ElevatedButton(
                onPressed: _loading ? null : _parseFile,
                child: const Text('Parse File'),
              ),
              const SizedBox(height: 16),
            ],
            if (_parsedData != null) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(_parsedData),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _importTransactions,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Import Transactions'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

