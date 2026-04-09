import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../l10n/report_strings.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

enum ExportFormat { pdf, txt }

enum ExportContent { transactions, userData, both }

class ExportOptions {
  final ExportFormat format;
  final ExportContent content;
  final DateTime? startDate;
  final DateTime? endDate;

  ExportOptions({
    required this.format,
    required this.content,
    this.startDate,
    this.endDate,
  });
}

class ExportResult {
  final String filePath;
  final ExportFormat format;
  final pw.Document? pdfDocument;
  final String? txtContent;

  ExportResult({
    required this.filePath,
    required this.format,
    this.pdfDocument,
    this.txtContent,
  });
}

class ExportService {
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  Future<void> _loadFonts() async {
    if (_regularFont != null && _boldFont != null) return;

    try {
      // Load Noto Sans font which has excellent Vietnamese support
      _regularFont = await PdfGoogleFonts.notoSansRegular();
      _boldFont = await PdfGoogleFonts.notoSansBold();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading Noto Sans fonts: $e. Trying Roboto fallback...');
      }
      try {
        // Fallback to Roboto which also supports Vietnamese
        _regularFont = await PdfGoogleFonts.robotoRegular();
        _boldFont = await PdfGoogleFonts.robotoBold();
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('Error loading fallback fonts: $e2. Using default fonts.');
        }
        // Will use default fonts if loading fails
      }
    }
  }

  pw.TextStyle _getTextStyle({
    double? fontSize,
    pw.FontWeight? fontWeight,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      font: fontWeight == pw.FontWeight.bold ? _boldFont : _regularFont,
    );
  }

  Future<ExportResult> exportData({
    required ExportOptions options,
    required List<Transaction> transactions,
    required User? user,
    String locale = 'en',
  }) async {
    // Load Vietnamese-compatible fonts
    await _loadFonts();
    final ReportStrings s = ReportStrings(locale);
    // Filter transactions by date range if provided
    List<Transaction> filteredTransactions = _filterTransactionsByDate(
      transactions,
      options.startDate,
      options.endDate,
    );

    // Generate filename with timestamp
    final now = DateTime.now();
    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(now);
    final extension = options.format == ExportFormat.pdf ? 'pdf' : 'txt';
    final filename = 'plutus_report_$timestamp.$extension';

    // Get export directory
    final directory = await _getExportDirectory();
    final filePath = '${directory.path}${Platform.pathSeparator}$filename';

    pw.Document? pdfDoc;
    String? txtContent;

    // Generate file based on format
    if (options.format == ExportFormat.pdf) {
      pdfDoc = await _generatePdf(
        filePath: filePath,
        options: options,
        transactions: filteredTransactions,
        user: user,
        s: s,
      );
    } else {
      txtContent = await _generateTxt(
        filePath: filePath,
        options: options,
        transactions: filteredTransactions,
        user: user,
        s: s,
      );
    }

    return ExportResult(
      filePath: filePath,
      format: options.format,
      pdfDocument: pdfDoc,
      txtContent: txtContent,
    );
  }

  List<Transaction> _filterTransactionsByDate(
    List<Transaction> transactions,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) {
      return transactions;
    }

    return transactions.where((tx) {
      final txDate = tx.dateTime;
      if (startDate != null && txDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && txDate.isAfter(endDate.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<Directory> _getExportDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Web export not supported');
    }

    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    // Create exports subdirectory
    final exportsDir = Directory('${directory!.path}${Platform.pathSeparator}exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }

    return exportsDir;
  }

  String getExportDirectoryPath() {
    if (kIsWeb) {
      return 'Web exports not supported';
    }

    if (Platform.isAndroid) {
      return 'Android/data/app_package/files/exports/';
    } else if (Platform.isWindows) {
      return 'Documents/exports/';
    } else if (Platform.isMacOS) {
      return '~/Documents/exports/';
    } else if (Platform.isLinux) {
      return '~/Documents/exports/';
    }
    return 'Application documents/exports/';
  }

  Future<pw.Document> _generatePdf({
    required String filePath,
    required ExportOptions options,
    required List<Transaction> transactions,
    required User? user,
    required ReportStrings s,
  }) async {
    final pdf = pw.Document();

    // Add pages based on content selection
    if (options.content == ExportContent.userData || options.content == ExportContent.both) {
      if (user != null) {
        _addUserDataPage(pdf, user, s);
      }
    }

    if (options.content == ExportContent.transactions || options.content == ExportContent.both) {
      _addTransactionsPages(pdf, transactions, options, s);
    }

    // Save PDF
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return pdf;
  }

  void _addUserDataPage(pw.Document pdf, User user, ReportStrings s) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: _regularFont,
          bold: _boldFont,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(s.tr('export_user_information'), s),
              pw.SizedBox(height: 30),
              _buildPdfInfoRow('${s.tr('export_user_id')}:', user.id.toString()),
              _buildPdfInfoRow('${s.tr('export_username')}:', user.username),
              _buildPdfInfoRow('${s.tr('export_display_name')}:', user.displayName),
              if (user.email != null)
                _buildPdfInfoRow('${s.tr('export_email')}:', user.email!),
              _buildPdfInfoRow('${s.tr('export_account_type')}:', user.isGuest ? s.tr('export_guest') : s.tr('export_registered')),
              if (user.oauthProvider != null)
                _buildPdfInfoRow('${s.tr('export_oauth_provider')}:', user.oauthProvider!),
              _buildPdfInfoRow(
                '${s.tr('export_account_created')}:',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(user.createdAt),
              ),
              _buildPdfInfoRow(
                '${s.tr('export_last_login')}:',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(user.lastLogin),
              ),
              _buildPdfInfoRow('${s.tr('export_status')}:', user.isActive ? s.tr('export_active') : s.tr('export_inactive')),
              pw.SizedBox(height: 30),
              _buildPdfFooter(s),
            ],
          );
        },
      ),
    );
  }

  void _addTransactionsPages(
    pw.Document pdf,
    List<Transaction> transactions,
    ExportOptions options,
    ReportStrings s,
  ) {
    // Calculate summary statistics
    final totalTransactions = transactions.length;
    final totalExpenses = transactions
        .where((tx) => tx.isExpense)
        .fold<double>(0, (sum, tx) => sum + tx.totalAmount);
    final totalIncome = transactions
        .where((tx) => !tx.isExpense)
        .fold<double>(0, (sum, tx) => sum + tx.totalAmount);

    // Add summary page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: _regularFont,
          bold: _boldFont,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(s.tr('export_transaction_summary'), s),
              pw.SizedBox(height: 30),
              if (options.startDate != null || options.endDate != null) ...[
                pw.Text(
                  '${s.tr('export_period')}: ${_formatDateRange(options.startDate, options.endDate)}',
                  style: _getTextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
              ],
              _buildPdfInfoRow('${s.tr('export_total_transactions')}:', totalTransactions.toString()),
              _buildPdfInfoRow('${s.tr('report_total_expenses')}:', _formatCurrency(totalExpenses)),
              _buildPdfInfoRow('${s.tr('report_total_income')}:', _formatCurrency(totalIncome)),
              _buildPdfInfoRow(
                '${s.tr('export_net_amount')}:',
                _formatCurrency(totalIncome - totalExpenses),
              ),
              pw.SizedBox(height: 30),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              pw.Text(
                s.tr('export_transaction_details'),
                style: _getTextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    // Add transaction details pages
    const itemsPerPage = 15;
    for (int i = 0; i < transactions.length; i += itemsPerPage) {
      final pageTransactions = transactions.skip(i).take(itemsPerPage).toList();
      _addTransactionDetailPage(pdf, pageTransactions, i + 1, transactions.length, s);
    }
  }

  void _addTransactionDetailPage(
    pw.Document pdf,
    List<Transaction> transactions,
    int startIndex,
    int totalCount,
    ReportStrings s,
  ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: _regularFont,
          bold: _boldFont,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${s.tr('report_transactions')} ($startIndex - ${startIndex + transactions.length - 1} of $totalCount)',
                style: _getTextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 15),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildTableCell(s.tr('report_col_date'), isHeader: true),
                      _buildTableCell(s.tr('report_col_description'), isHeader: true),
                      _buildTableCell(s.tr('report_col_amount'), isHeader: true),
                      _buildTableCell(s.tr('export_col_type'), isHeader: true),
                    ],
                  ),
                  // Data rows
                  ...transactions.map((tx) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(tx.formattedDate),
                        _buildTableCell(tx.label),
                        _buildTableCell(
                          '${tx.isExpense ? '-' : '+'}${_formatCurrency(tx.totalAmount)} ${tx.currency}',
                        ),
                        _buildTableCell(tx.isExpense ? s.tr('export_expense') : s.tr('export_income')),
                      ],
                    );
                  }),
                ],
              ),
              pw.Spacer(),
              _buildPdfFooter(s),
            ],
          );
        },
      ),
    );
  }

  pw.Widget _buildPdfHeader(String title, ReportStrings s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PLUTUS ${s.tr('report_financial_report').toUpperCase()}',
          style: _getTextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          title,
          style: _getTextStyle(fontSize: 18, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: _getTextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: _getTextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: _getTextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildPdfFooter(ReportStrings s) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 5),
        pw.Text(
          '${s.tr('report_generated_on')}${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
          style: _getTextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  Future<String> _generateTxt({
    required String filePath,
    required ExportOptions options,
    required List<Transaction> transactions,
    required User? user,
    required ReportStrings s,
  }) async {
    final buffer = StringBuffer();

    // Add header
    buffer.writeln('=' * 80);
    buffer.writeln('PLUTUS ${s.tr('report_financial_report').toUpperCase()}');
    buffer.writeln('${s.tr('report_generated_on')}${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('=' * 80);
    buffer.writeln();

    // Add user data if requested
    if ((options.content == ExportContent.userData || options.content == ExportContent.both) && user != null) {
      buffer.writeln(s.tr('export_user_information').toUpperCase());
      buffer.writeln('-' * 80);
      buffer.writeln('${s.tr('export_user_id')}:          ${user.id}');
      buffer.writeln('${s.tr('export_username')}:         ${user.username}');
      buffer.writeln('${s.tr('export_display_name')}:     ${user.displayName}');
      if (user.email != null) {
        buffer.writeln('${s.tr('export_email')}:            ${user.email}');
      }
      buffer.writeln('${s.tr('export_account_type')}:     ${user.isGuest ? s.tr('export_guest') : s.tr('export_registered')}');
      if (user.oauthProvider != null) {
        buffer.writeln('${s.tr('export_oauth_provider')}:   ${user.oauthProvider}');
      }
      buffer.writeln('${s.tr('export_account_created')}:  ${DateFormat('yyyy-MM-dd HH:mm:ss').format(user.createdAt)}');
      buffer.writeln('${s.tr('export_last_login')}:       ${DateFormat('yyyy-MM-dd HH:mm:ss').format(user.lastLogin)}');
      buffer.writeln('${s.tr('export_status')}:           ${user.isActive ? s.tr('export_active') : s.tr('export_inactive')}');
      buffer.writeln();
      buffer.writeln();
    }

    // Add transactions if requested
    if (options.content == ExportContent.transactions || options.content == ExportContent.both) {
      buffer.writeln(s.tr('export_transaction_summary').toUpperCase());
      buffer.writeln('-' * 80);

      if (options.startDate != null || options.endDate != null) {
        buffer.writeln('${s.tr('export_period')}:           ${_formatDateRange(options.startDate, options.endDate)}');
      }

      final totalTransactions = transactions.length;
      final totalExpenses = transactions
          .where((tx) => tx.isExpense)
          .fold<double>(0, (sum, tx) => sum + tx.totalAmount);
      final totalIncome = transactions
          .where((tx) => !tx.isExpense)
          .fold<double>(0, (sum, tx) => sum + tx.totalAmount);

      buffer.writeln('${s.tr('export_total_transactions')}: $totalTransactions');
      buffer.writeln('${s.tr('report_total_expenses')}:     ${_formatCurrency(totalExpenses)}');
      buffer.writeln('${s.tr('report_total_income')}:       ${_formatCurrency(totalIncome)}');
      buffer.writeln('${s.tr('export_net_amount')}:         ${_formatCurrency(totalIncome - totalExpenses)}');
      buffer.writeln();
      buffer.writeln();

      buffer.writeln(s.tr('export_transaction_details').toUpperCase());
      buffer.writeln('-' * 80);
      buffer.writeln();

      // Format: Date | Description | Amount | Currency | Type
      buffer.writeln(
        '${_padRight(s.tr('report_col_date'), 20)}${_padRight(s.tr('report_col_description'), 30)}${_padRight(s.tr('report_col_amount'), 15)}${_padRight(s.tr('export_col_currency'), 10)}${s.tr('export_col_type')}',
      );
      buffer.writeln('-' * 80);

      for (final tx in transactions) {
        final date = DateFormat('yyyy-MM-dd HH:mm').format(tx.dateTime);
        final description = tx.label.length > 28 ? '${tx.label.substring(0, 28)}..' : tx.label;
        final amount = '${tx.isExpense ? '-' : '+'}${_formatCurrency(tx.totalAmount)}';
        final type = tx.isExpense ? s.tr('export_expense') : s.tr('export_income');

        buffer.writeln(
          _padRight(date, 20) +
          _padRight(description, 30) +
          _padRight(amount, 15) +
          _padRight(tx.currency, 10) +
          type,
        );

        // Add posting details if multiple postings exist
        if (tx.postings.length > 1) {
          for (final posting in tx.postings) {
            buffer.writeln(
              '  ${_padRight('→ ${posting.account}', 48)}${_padRight(posting.formattedAmount, 15)}${posting.commodity}',
            );
          }
          buffer.writeln();
        }
      }
    }

    buffer.writeln();
    buffer.writeln('=' * 80);
    buffer.writeln(s.tr('export_end_of_report'));
    buffer.writeln('=' * 80);

    final content = buffer.toString();

    // Write to file
    final file = File(filePath);
    await file.writeAsString(content);

    return content;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(amount);
  }

  String _formatDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) {
      return 'All time';
    }
    final format = DateFormat('yyyy-MM-dd');
    if (startDate != null && endDate != null) {
      return '${format.format(startDate)} to ${format.format(endDate)}';
    } else if (startDate != null) {
      return 'From ${format.format(startDate)}';
    } else {
      return 'Until ${format.format(endDate!)}';
    }
  }

  String _padRight(String text, int width) {
    if (text.length >= width) return text;
    return text + ' ' * (width - text.length);
  }
}
