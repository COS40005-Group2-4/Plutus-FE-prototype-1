import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../transaction_service.dart';
import '../../widgets/glass_container.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

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
            'Import from File',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose a file to import your transactions. Supported formats will be loaded automatically.',
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
                    'File selected:',
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
