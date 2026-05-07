import 'dart:typed_data';
import '../../models/report_data.dart';

abstract class IReportPdfService {
  Future<String> generatePdf({
    required ReportDataModel data,
    String locale = 'en',
  });

  Future<Uint8List> generatePdfBytes({
    required ReportDataModel data,
    String locale = 'en',
  });
}
