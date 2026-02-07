import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:plutus_fe_prototype/config/aws_config.dart';

enum OCRMode {
  offline,
  online,
  auto,
}

class OCRService {
  TextRecognizer? _textRecognizer;

  OCRService() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    }
  }

  /// Main entry point: process invoice with specified OCR mode.
  /// mode: OCRMode.offline - Use TesseractOCR (offline with Vietnamese support)
  /// mode: OCRMode.online - Use AWS Textract (online with Vietnamese support)
  /// mode: OCRMode.auto - Automatically choose based on connectivity and config
  Future<Map<String, dynamic>?> processInvoice(String imagePath, {OCRMode mode = OCRMode.auto}) async {
    // 1. Check Connectivity
    bool hasInternet = false;
    try {
      final result = await Connectivity().checkConnectivity();
      // In connectivity_plus ^6.0.0, result is a List<ConnectivityResult>
      hasInternet = !result.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
    }

    // 2. Check AWS Config
    bool awsConfigured = AWSConfig.accessKeyId != 'YOUR_ACCESS_KEY_ID';

    // 3. Decide Strategy based on mode
    bool useCloud = false;
    
    if (mode == OCRMode.online) {
      // Force online mode
      useCloud = true;
      if (!awsConfigured) {
        return {'error': 'AWS Keys not configured for online OCR'};
      }
      if (!hasInternet) {
        return {'error': 'No internet connection for online OCR'};
      }
    } else if (mode == OCRMode.offline) {
      // Force offline mode
      useCloud = false;
    } else {
      // Auto mode: Decide based on platform and availability
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        useCloud = true;
      } else {
        // On mobile, prefer cloud if internet + keys exist
        if (hasInternet && awsConfigured) {
          useCloud = true;
        }
      }
    }

    if (useCloud) {
      if (!awsConfigured) {
        debugPrint('AWS Not Configured. Cannot use Cloud OCR.');
        // If on mobile, fallback to offline even if internet exists (but keys missing)
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          return _analyzeWithTesseract(imagePath);
        }
        return {'error': 'AWS Keys not configured'};
      }
      return await _analyzeWithTextract(imagePath);
    } else {
      return await _analyzeWithTesseract(imagePath);
    }
  }

  /// Analyze image using TesseractOCR (offline mode) with Vietnamese language support
  Future<Map<String, dynamic>?> _analyzeWithTesseract(String imagePath) async {
    // Check if platform is supported for offline OCR
    if (kIsWeb) {
      return {'error': 'Offline OCR is not supported on Web. Please use Online mode.'};
    }
    
    // Windows: Use Tesseract via command-line if installed
    if (!kIsWeb && Platform.isWindows) {
      return await _runTesseractWindows(imagePath);
    }
    
    // Linux/macOS desktop: Try command-line Tesseract
    if (!Platform.isAndroid && !Platform.isIOS) {
      return await _runTesseractWindows(imagePath); // Same approach for Linux/macOS
    }
    
    // Android/iOS: Use Google ML Kit for text recognition
    try {
      return await _analyzeWithMLKit(imagePath);
    } catch (e) {
      debugPrint('Error processing image with ML Kit: $e');
      return {'error': 'ML Kit text recognition failed: $e'};
    }
  }

  /// Run Tesseract via command-line on Windows/Linux/macOS
  Future<Map<String, dynamic>?> _runTesseractWindows(String imagePath) async {
    try {
      // Create temporary output file path
      final outputPath = '${imagePath}_ocr';
      
      // Determine tesseract executable path
      String tesseractCmd = 'tesseract';
      
      // On Windows, try common installation paths if 'tesseract' is not in PATH
      if (Platform.isWindows) {
        final commonPaths = [
          'tesseract', // Try PATH first
          'C:\\Program Files\\Tesseract-OCR\\tesseract.exe',
          'C:\\Program Files (x86)\\Tesseract-OCR\\tesseract.exe',
        ];
        
        // Test which path works
        for (final path in commonPaths) {
          try {
            final testResult = await Process.run(path, ['--version']);
            if (testResult.exitCode == 0) {
              tesseractCmd = path;
              debugPrint('Found Tesseract at: $path');
              break;
            }
          } catch (e) {
            // Continue to next path
            continue;
          }
        }
      }
      
      // Run tesseract command
      // tesseract image.jpg output -l eng+vie --psm 4
      final result = await Process.run(
        tesseractCmd,
        [
          imagePath,
          outputPath,
          '-l', 'eng+vie', // English + Vietnamese
          '--psm', '4', // Page segmentation mode
        ],
      );
      
      if (result.exitCode != 0) {
        final errorMsg = result.stderr.toString();
        debugPrint('Tesseract command error: $errorMsg');
        
        // Check for common errors
        if (errorMsg.contains('not found') || errorMsg.contains('not recognized')) {
          return {
            'error': 'Tesseract is not found in PATH.\n\n'
                'Please make sure:\n'
                '1. Tesseract is installed at: C:\\Program Files\\Tesseract-OCR\n'
                '2. Added to PATH (requires restart after adding)\n'
                '3. Try restarting this app'
          };
        } else if (errorMsg.contains('vie.traineddata') || errorMsg.contains('language')) {
          return {
            'error': 'Vietnamese language data not found.\n\n'
                'Please download Vietnamese tessdata:\n'
                '1. Go to: https://github.com/tesseract-ocr/tessdata\n'
                '2. Download: vie.traineddata\n'
                '3. Place in: C:\\Program Files\\Tesseract-OCR\\tessdata\\'
          };
        }
        
        return {'error': 'Tesseract error: $errorMsg'};
      }
      
      // Read the output text file
      final textFile = File('$outputPath.txt');
      if (!await textFile.exists()) {
        return {'error': 'Tesseract did not generate output file'};
      }
      
      final text = await textFile.readAsString();
      
      // Clean up temporary file
      try {
        await textFile.delete();
      } catch (e) {
        debugPrint('Could not delete temp file: $e');
      }
      
      debugPrint('TesseractOCR extracted text: $text');
      
      if (text.trim().isEmpty) {
        return {'error': 'No text detected in image. Please try a clearer image.'};
      }
      
      return extractTransactionDetails(text);
    } catch (e) {
      debugPrint('Error running Tesseract: $e');
      
      if (e.toString().contains('No such file or directory') || 
          e.toString().contains('cannot run executable')) {
        return {
          'error': 'Tesseract is not found in PATH.\n\n'
              'Please make sure:\n'
              '1. Tesseract is installed at: C:\\Program Files\\Tesseract-OCR\n'
              '2. Added to PATH (requires system restart)\n'
              '3. Restart this app after adding to PATH'
        };
      }
      
      return {'error': 'Error running Tesseract: $e'};
    }
  }

  /// Legacy ML Kit method - kept for backward compatibility
  Future<Map<String, dynamic>?> _analyzeWithMLKit(String imagePath) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('Offline OCR only supported on Android/iOS.');
      return null;
    }

    try {
      if (_textRecognizer == null) return null;
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
      return extractTransactionDetails(recognizedText.text);
    } catch (e) {
      debugPrint('Error processing image with ML Kit: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _analyzeWithTextract(String imagePath) async {
    try {
      // 1. Read Image Bytes
      Uint8List imageBytes;
      if (kIsWeb) {
        // On web, imagePath might be a blob URL or we need to handle it differently.
        // For this prototype, assume we can fetch it or it's passed differently.
        // Ideally, we'd pass Uint8List directly to processInvoice.
        // For now, if it's a network URL (blob: or http), try to fetch it.
        final response = await http.get(Uri.parse(imagePath));
        imageBytes = response.bodyBytes;
      } else {
        imageBytes = await File(imagePath).readAsBytes();
      }

      // 2. Prepare AWS Request
      final endpoint = 'https://textract.${AWSConfig.region}.amazonaws.com';
      final body = jsonEncode({
        'Document': {
          'Bytes': base64Encode(imageBytes),
        }
      });

      final request = AWSHttpRequest(
        method: AWSHttpMethod.post,
        uri: Uri.parse(endpoint),
        headers: {
          'content-type': 'application/x-amz-json-1.1',
          'x-amz-target': 'Textract.AnalyzeExpense',
        },
        body: utf8.encode(body),
      );

      // 3. Sign Request
      final signer = AWSSigV4Signer(
        credentialsProvider: AWSCredentialsProvider(
          AWSCredentials(
            AWSConfig.accessKeyId,
            AWSConfig.secretAccessKey,
            AWSConfig.sessionToken,
          ),
        ),
      );

      final scope = AWSCredentialScope(
        region: AWSConfig.region,
        service: AWSService.textract,
      );

      final signedRequest = await signer.sign(
        request,
        credentialScope: scope,
      );

      // 4. Send Request
      final response = await http.post(
        signedRequest.uri,
        headers: signedRequest.headers,
        body: await signedRequest.bodyBytes,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseTextractResponse(data);
      } else {
        debugPrint('Textract Error: ${response.statusCode} - ${response.body}');
        return {'error': 'Textract API Error: ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('Error calling AWS Textract: $e');
      return {'error': e.toString()};
    }
  }

  Map<String, dynamic> _parseTextractResponse(Map<String, dynamic> data) {
    final Map<String, dynamic> result = {
      'items': <Map<String, dynamic>>[],
    };

    if (data['ExpenseDocuments'] == null || (data['ExpenseDocuments'] as List).isEmpty) {
      return result;
    }

    final doc = data['ExpenseDocuments'][0];
    final summaryFields = doc['SummaryFields'] as List? ?? [];
    final lineItemGroups = doc['LineItemGroups'] as List? ?? [];

    // Extract Summary Fields
    for (var field in summaryFields) {
      final type = field['Type']['Text'];
      final value = field['ValueDetection']['Text'];
      
      if (type == 'VENDOR_NAME') {
        result['payee'] = value;
      } else if (type == 'TOTAL') {
        // Clean amount string
        String cleanAmount = value.replaceAll(RegExp(r'[^0-9.]'), '');
        result['amount'] = double.tryParse(cleanAmount);
      } else if (type == 'INVOICE_RECEIPT_DATE') {
        // Textract usually returns standardized dates, but we might need parsing.
        // For now, pass as string, the UI tries to parse it.
        result['date'] = value;
      } else if (type == 'CURRENCY') { 
         // Textract usually provides currency code
         result['currency'] = value; 
      }
    }

    // Extract Line Items
    for (var group in lineItemGroups) {
      final lineItems = group['LineItems'] as List? ?? [];
      for (var item in lineItems) {
        final expenseFields = item['LineItemExpenseFields'] as List? ?? [];
        String desc = '';
        double amount = 0.0;

        for (var field in expenseFields) {
          final type = field['Type']['Text'];
          final value = field['ValueDetection']['Text'];

          if (type == 'ITEM') {
            desc = value;
          } else if (type == 'PRICE') {
             String cleanAmount = value.replaceAll(RegExp(r'[^0-9.]'), '');
             amount = double.tryParse(cleanAmount) ?? 0.0;
          }
        }

        if (desc.isNotEmpty || amount > 0) {
          (result['items'] as List).add({
            'description': desc,
            'amount': amount,
          });
        }
      }
    }

    return result;
  }

  void dispose() {
    _textRecognizer?.close();
  }

  // Deprecated: kept for offline fallback logic
  Future<String?> processImage(String imagePath) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('OCR is only supported on Android and iOS.');
      return null;
    }

    try {
      if (_textRecognizer == null) return null;
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('Error processing image: $e');
      return null;
    }
  }

  // Simple heuristic to find date and amount
  Map<String, dynamic> extractTransactionDetails(String text) {
    final Map<String, dynamic> details = {};
    
    // Regex for Amount (simple version: looks for numbers with decimals)
    // Matches: $10.00, 10.00, 1,000.00
    final amountRegex = RegExp(r'[\$]?\s?(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)');
    
    // Regex for Date (YYYY-MM-DD, DD/MM/YYYY, etc.)
    // Matches: 2023-10-25, 25/10/2023, Oct 25 2023
    final dateRegex = RegExp(
      r'(\d{4}[-/]\d{1,2}[-/]\d{1,2})|(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})'
    );

    final lines = text.split('\n');
    
    // Simple heuristic for Payee: First non-empty line that isn't a date
    for (var line in lines) {
      if (line.trim().isNotEmpty) {
        // Skip if it looks like a date (very rough check)
        if (!line.contains(RegExp(r'\d{4}')) && !line.contains('/')) {
           details['payee'] = line.trim();
           break;
        }
      }
    }

    for (var line in lines) {
      // Look for Date
      if (!details.containsKey('date')) {
        final dateMatch = dateRegex.firstMatch(line);
        if (dateMatch != null) {
          // Normalize date if needed, for now just storing the string
          details['date'] = dateMatch.group(0);
        }
      }
      
      // Look for Amount (often the largest number on a receipt is the total, but we'll take the first reasonable one or try to find "Total")
      // A better heuristic finds "Total" line
      if (line.toLowerCase().contains('total') || line.toLowerCase().contains('amount')) {
         final amountMatch = amountRegex.firstMatch(line);
         if (amountMatch != null) {
           String rawAmount = amountMatch.group(1)!.replaceAll(',', '');
           details['amount'] = double.tryParse(rawAmount);
         }
      }
    }
    
    // Fallback if no "Total" line found, scan all lines for highest number? 
    // For now, let's keep it simple. If we didn't find "Total", maybe just user edits it.

    // Attempt to extract line items
    // Heuristic: Line starts with text, ends with number (price)
    List<Map<String, dynamic>> items = [];
    final itemRegex = RegExp(r'^(.+?)\s+[\$]?(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)$');

    for (var line in lines) {
       // Skip lines that look like Date or Total
       if (dateRegex.hasMatch(line)) continue;
       if (line.toLowerCase().contains('total')) continue;
       
       final match = itemRegex.firstMatch(line.trim());
       if (match != null) {
         String desc = match.group(1)?.trim() ?? '';
         String amountStr = match.group(2)?.replaceAll(',', '') ?? '0';
         double? amount = double.tryParse(amountStr);
         
         if (amount != null && desc.isNotEmpty && desc.length < 50) { // arbitrary length check to avoid capturing long garbage
           items.add({
             'description': desc,
             'amount': amount,
           });
         }
       }
    }
    
    if (items.isNotEmpty) {
      details['items'] = items;
    }
    
    return details;
  }
}
