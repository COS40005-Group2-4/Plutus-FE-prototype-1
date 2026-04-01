import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/report_data.dart';
import 'interfaces/i_report_pdf_service.dart';

class ReportPdfService implements IReportPdfService {
  @override
  Future<String> generatePdf({required ReportDataModel data}) async {
    final Uint8List bytes = await generatePdfBytes(data: data);

    final Directory dir = await getApplicationDocumentsDirectory();
    final String exportDir = '${dir.path}/exports';
    await Directory(exportDir).create(recursive: true);

    final String timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final String filePath = '$exportDir/plutus_report_$timestamp.pdf';
    await File(filePath).writeAsBytes(bytes);

    return filePath;
  }

  @override
  Future<Uint8List> generatePdfBytes({required ReportDataModel data}) async {
    // Stub: Task 14 replaces this with full HTML template rendering.
    // Minimal placeholder PDF so the pipeline compiles end-to-end.
    final String html = _buildHtml(data);
    return await Printing.convertHtml(format: PdfPageFormat.a4, html: html);
  }

  String _buildHtml(ReportDataModel data) {
    return '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>Plutus Report</title></head>
<body>
  <h1>Plutus Financial Report</h1>
  <p>Generated: ${DateFormat.yMMMd().format(data.generatedAt)}</p>
  <p>Period: ${DateFormat.yMMMd().format(data.config.dateRange.start)} — ${DateFormat.yMMMd().format(data.config.dateRange.end)}</p>
  <p>Placeholder — full template in Task 14.</p>
</body>
</html>''';
  }
}
