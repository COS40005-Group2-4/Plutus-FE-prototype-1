import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import '../l10n/app_localizations.dart';
import '../services/export_service.dart';
import '../theme/app_spacing.dart';
import '../theme/plutus_tokens.dart';
import 'core/app_card.dart';

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
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(t, l10n),
            Divider(height: 1, color: t.border),
            Expanded(
              child: widget.format == ExportFormat.pdf
                  ? _buildPdfPreview(t, l10n)
                  : _buildTxtPreview(t, l10n),
            ),
            Divider(height: 1, color: t.border),
            _buildFooter(t, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PlutusTokens t, AppLocalizations l10n) {
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
                ? t.error.text
                : t.brandNavy,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.exportPreview,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.filePath.split(Platform.pathSeparator).last,
                  style: TextStyle(fontSize: 12, color: t.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: t.textSecondary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview(PlutusTokens t, AppLocalizations l10n) {
    if (widget.pdfDocument == null) {
      return Center(
        child: Text(l10n.pdfNotAvailable, style: TextStyle(color: t.textSecondary)),
      );
    }

    return FutureBuilder<Uint8List>(
      future: widget.pdfDocument!.save(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: t.gold));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: t.error.text),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Error loading PDF preview: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.textSecondary),
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

  Widget _buildTxtPreview(PlutusTokens t, AppLocalizations l10n) {
    if (widget.txtContent == null) {
      return Center(
        child: Text(l10n.textNotAvailable, style: TextStyle(color: t.textSecondary)),
      );
    }

    return Container(
      // Faint backing tint behind the monospace text — not a scrim over
      // rendered page content (the PDF branch above uses PdfPreview, a
      // separate renderer/widget). t.surfaceSubtle is the token equivalent
      // of the original low-alpha black wash used purely as a text-preview
      // backing surface, so it stays theme-aware in both brightnesses.
      color: t.surfaceSubtle,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          widget.txtContent!,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: t.text,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(PlutusTokens t, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFileLocationInfo(t, l10n),
          const SizedBox(height: AppSpacing.lg),
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
                label: Text(l10n.openInExternalApp),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.check_circle),
                label: Text(l10n.done),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileLocationInfo(PlutusTokens t, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: t.brandNavy),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.fileLocation,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: t.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            widget.filePath,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: t.textSecondary,
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
      final AppLocalizations l10n = AppLocalizations.of(context);
      final PlutusTokens t = context.tokens;

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.couldNotOpenFile}${result.message}',
              style: TextStyle(color: t.onStatus),
            ),
            backgroundColor: t.warning.dot,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final AppLocalizations l10n = AppLocalizations.of(context);
      final PlutusTokens t = context.tokens;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.errorOpeningFile}$e',
            style: TextStyle(color: t.onStatus),
          ),
          backgroundColor: t.error.dot,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }
}
