import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import '../services/export_service.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';

class ExportPreviewDialog extends StatefulWidget {
  final String filePath;
  final ExportFormat format;
  final pw.Document? pdfDocument;
  final String? txtContent;

  const ExportPreviewDialog({
    super.key,
    required this.filePath,
    required this.format,
    this.pdfDocument,
    this.txtContent,
  });

  @override
  State<ExportPreviewDialog> createState() => _ExportPreviewDialogState();
}

class _ExportPreviewDialogState extends State<ExportPreviewDialog> {
  bool _isOpening = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GlassContainer(
        borderRadius: 16,
        opacity: 0.15,
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: widget.format == ExportFormat.pdf
                  ? _buildPdfPreview()
                  : _buildTxtPreview(),
            ),
            const Divider(height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            widget.format == ExportFormat.pdf
                ? Icons.picture_as_pdf
                : Icons.text_snippet,
            size: 28,
            color: widget.format == ExportFormat.pdf
                ? AppColors.error
                : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Export Preview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.filePath.split(Platform.pathSeparator).last,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textOnLightSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview() {
    if (widget.pdfDocument == null) {
      return const Center(
        child: Text('PDF document not available for preview'),
      );
    }

    return FutureBuilder<Uint8List>(
      future: widget.pdfDocument!.save(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading PDF preview: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }

        return PdfPreview(
          build: (format) async => snapshot.data!,
          allowPrinting: true,
          allowSharing: true,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          maxPageWidth: 700,
          pdfFileName: widget.filePath.split(Platform.pathSeparator).last,
        );
      },
    );
  }

  Widget _buildTxtPreview() {
    if (widget.txtContent == null) {
      return const Center(
        child: Text('Text content not available for preview'),
      );
    }

    return Container(
      color: Colors.black.withValues(alpha:0.05),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          widget.txtContent!,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFileLocationInfo(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _isOpening ? null : _openFile,
                icon: _isOpening
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.open_in_new),
                label: const Text('Open in External App'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.check_circle),
                label: const Text('Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileLocationInfo() {
    return GlassContainer(
      borderRadius: 8,
      opacity: 0.1,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'File Location',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            widget.filePath,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: AppColors.textOnLightSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile() async {
    setState(() => _isOpening = true);

    try {
      final result = await OpenFile.open(widget.filePath);

      if (!mounted) return;

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: ${result.message}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }
}
