import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'import/manual_import_tab.dart';
import 'import/file_import_tab.dart';
import 'import/scan_import_tab.dart';

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
