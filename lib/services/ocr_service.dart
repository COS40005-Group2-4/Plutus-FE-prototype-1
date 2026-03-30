import 'dart:convert';
import 'dart:io';

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

  /// Suggests a category based on the invoice content (vendor name and items)
  /// Uses keyword matching to determine the most appropriate category
  String suggestCategory(Map<String, dynamic> data) {
    final payee = (data['payee'] ?? '').toString().toLowerCase();
    final items = data['items'] as List? ?? [];
    final fullText = StringBuffer(payee);

    // Collect all item descriptions
    for (var item in items) {
      fullText.write(' ');
      fullText.write((item['description'] ?? '').toString().toLowerCase());
    }

    final text = fullText.toString();

    // Category keyword mappings — Vietnam, USA & Europe
    final categoryKeywords = {
      'Food': [
        // === Vietnam ===
        'phở', 'bún', 'bánh mì', 'cơm tấm', 'cơm bình dân', 'cơm văn phòng',
        'hủ tiếu', 'bún bò', 'bún chả', 'bún riêu', 'bánh cuốn', 'bánh xèo',
        'chè', 'trà sữa', 'trà đào', 'nước mía', 'sinh tố', 'nước ép',
        'nhà hàng', 'quán ăn', 'quán nhậu', 'ăn uống', 'ăn sáng', 'ăn trưa',
        'ăn tối', 'cơm', 'bếp', 'đồ ăn', 'thức ăn', 'ẩm thực',
        'highlands coffee', 'phúc long', 'the coffee house', 'cộng cà phê',
        'trung nguyên', 'king coffee', 'passio', 'ông bầu',
        'jollibee', 'lotteria', 'golden gate', 'kichi kichi', 'gogi house',
        'sumo bbq', 'manwah', 'haidilao', 'hotpot', 'lẩu', 'nướng', 'bbq',
        'grabfood', 'shopee food', 'shopeefood', 'baemin', 'beamin',
        'loship', 'now.vn', 'gojek food',
        'bách hóa xanh', 'winmart', 'vinmart', 'co.op mart', 'coopmart',
        'big c', 'mega market', 'lotte mart', 'aeon', 'emart',
        'circle k', 'ministop', 'gs25', 'family mart', '7-eleven',
        'annam gourmet', 'satra',
        // === USA ===
        'walmart', 'kroger', 'costco', 'trader joe', 'whole foods',
        'safeway', 'target', 'publix', 'aldi', 'wegmans',
        'chipotle', 'chick-fil-a', 'wendy', 'taco bell', 'panda express',
        'five guys', 'shake shack', 'in-n-out', 'panera', 'sweetgreen',
        'doordash', 'uber eats', 'grubhub', 'instacart', 'postmates',
        'dunkin', 'tim hortons', 'cvs pharmacy',
        // === Europe ===
        'carrefour', 'lidl', 'aldi', 'tesco', 'sainsbury', 'asda',
        'marks & spencer', 'waitrose', 'monoprix', 'leclerc', 'auchan',
        'edeka', 'rewe', 'albert heijn', 'delhaize', 'mercadona', 'esselunga',
        'deliveroo', 'just eat', 'uber eats', 'glovo', 'wolt',
        'boulangerie', 'bäckerei', 'patisserie', 'traiteur',
        'pret a manger', 'paul', 'leon', 'itsu', 'nando',
        // General
        'restaurant', 'cafe', 'coffee', 'food', 'grocery', 'supermarket',
        'bakery', 'pizza', 'burger', 'sushi', 'convenience',
        'kfc', 'mcdonald', 'burger king', 'pizza hut', 'dominos',
        'starbucks', 'texas chicken', 'popeyes', 'subway',
      ],
      'Transportation': [
        // === Vietnam ===
        'grab', 'grabcar', 'grabbike', 'be', 'be group', 'xanh sm',
        'gojek', 'go-viet', 'mai linh', 'vinasun', 'sun taxi',
        'taxi', 'xe ôm', 'xe máy', 'xe buýt', 'xe khách',
        'petrolimex', 'pvoil', 'saigon petro', 'mipec', 'thanh lễ',
        'xăng', 'dầu', 'đổ xăng', 'trạm xăng',
        'bãi đỗ xe', 'giữ xe', 'phí cầu đường',
        'vietnam airlines', 'vietjet', 'vietjet air', 'bamboo airways',
        'pacific airlines', 'jetstar', 'vietravel airlines',
        'xe lửa', 'đường sắt', 'ga sài gòn', 'ga hà nội',
        'phương trang', 'futa', 'hoàng long', 'kumho', 'the sinh tourist',
        'ô tô', 'xe', 'vé xe', 'vé máy bay', 'phà', 'tàu',
        // === USA ===
        'uber', 'lyft', 'amtrak', 'greyhound', 'megabus',
        'delta', 'united airlines', 'american airlines', 'southwest',
        'spirit airlines', 'frontier', 'alaska airlines',
        'shell', 'chevron', 'exxon', 'bp', 'sunoco', 'speedway',
        'ez pass', 'ezpass', 'turnpike', 'mta', 'bart', 'caltrain',
        'nj transit', 'wmata', 'cta', 'septa',
        // === Europe ===
        'ryanair', 'easyjet', 'wizz air', 'lufthansa', 'air france',
        'klm', 'british airways', 'vueling', 'transavia', 'norwegian',
        'eurostar', 'thalys', 'sncf', 'tgv', 'deutsche bahn', 'db',
        'renfe', 'trenitalia', 'flixbus', 'blablacar',
        'total energies', 'esso', 'aral', 'repsol',
        'tfl', 'oyster', 'navigo', 'ov-chipkaart',
        'bolt', 'free now', 'freenow', 'cabify',
        // General
        'gas', 'petrol', 'fuel', 'parking', 'toll',
        'train', 'metro', 'bus', 'ferry',
      ],
      'Entertainment': [
        // === Vietnam ===
        'cgv', 'lotte cinema', 'galaxy cinema', 'beta cinemas', 'bhd star',
        'rạp chiếu phim', 'rạp phim', 'xem phim', 'rạp chiếu',
        'karaoke', 'icool', 'kingdom', 'nhà văn hóa',
        'công viên', 'đầm sen', 'suối tiên', 'vinwonders', 'vinpearl',
        'sun world', 'bà nà hills', 'dragon park',
        'california fitness', 'citigym', 'elite fitness',
        'quán bar', 'bia', 'nhậu',
        'fpt play', 'viettel tv',
        'giải trí', 'vui chơi', 'thể thao',
        // === USA ===
        'amc', 'regal cinemas', 'cinemark', 'imax',
        'disneyland', 'disney world', 'universal studios', 'six flags',
        'planet fitness', 'equinox', 'orangetheory', 'la fitness',
        'peloton', 'soulcycle', 'crossfit',
        'ticketmaster', 'stubhub', 'eventbrite',
        'hbo max', 'hulu', 'peacock', 'paramount+', 'apple tv',
        'topgolf', 'dave and busters',
        // === Europe ===
        'odeon', 'vue cinemas', 'pathé', 'gaumont', 'cineplex',
        'europapark', 'disneyland paris', 'port aventura', 'tivoli',
        'david lloyd', 'virgin active', 'pure gym', 'basic-fit',
        'sky', 'dazn', 'canal+', 'joyn',
        // General
        'gym', 'yoga', 'fitness', 'sport', 'bơi', 'hồ bơi',
        'spa', 'massage', 'nail', 'làm đẹp', 'thẩm mỹ',
        'pub', 'club', 'bar', 'bowling',
        'netflix', 'spotify', 'youtube', 'disney+',
        'game', 'steam', 'playstation', 'xbox', 'nintendo',
      ],
      'Shopping': [
        // === Vietnam ===
        'shopee', 'lazada', 'tiki', 'sendo', 'thế giới di động',
        'điện máy xanh', 'fpt shop', 'cellphones', 'cellphoneS',
        'hoàng hà mobile', 'viettel store', 'phong vũ', 'nguyễn kim',
        'hnam mobile', 'di động việt',
        'vincom', 'aeon mall', 'crescent mall', 'saigon centre',
        'takashimaya', 'parkson', 'lotte mall', 'gigamall', 'nowzone',
        'diamond plaza', 'landmark 81', 'bitexco',
        'canifa', 'routine', 'yody', 'owen', 'aristino', 'ivy moda',
        'elise', 'juno', 'vascara',
        'mua sắm', 'siêu thị', 'cửa hàng', 'thời trang',
        'quần áo', 'giày dép', 'điện thoại', 'máy tính',
        'phụ kiện', 'đồ gia dụng', 'nội thất',
        // === USA ===
        'amazon', 'ebay', 'best buy', 'home depot', 'lowe',
        'macy', 'nordstrom', 'bloomingdale', 'saks', 'neiman marcus',
        'tj maxx', 'marshalls', 'ross', 'burlington',
        'apple store', 'microsoft store', 'gamestop',
        'nike', 'adidas', 'gap', 'old navy', 'banana republic',
        'bath & body works', 'sephora', 'ulta',
        'wayfair', 'pottery barn', 'crate & barrel', 'ikea',
        // === Europe ===
        'john lewis', 'selfridges', 'harrods', 'galeries lafayette',
        'el corte ingles', 'karstadt', 'de bijenkorf',
        'primark', 'decathlon', 'mediamarkt', 'saturn', 'fnac', 'darty',
        'zalando', 'asos', 'about you', 'otto', 'cdiscount',
        'uniqlo', 'zara', 'h&m', 'muji', 'mango', 'pull&bear',
        'charles & keith', 'sandro', 'maje',
        // General
        'shop', 'mall', 'clothing', 'fashion', 'electronics', 'laptop',
      ],
      'Bills': [
        // === Vietnam ===
        'evn', 'điện lực', 'tiền điện', 'hóa đơn điện',
        'sawaco', 'tiền nước', 'hóa đơn nước', 'nước sạch',
        'viettel', 'mobifone', 'vinaphone', 'vnpt', 'fpt telecom',
        'sctv', 'vtv cab', 'k+', 'truyền hình',
        'fpt internet', 'vnpt internet', 'viettel internet',
        'cáp quang', 'mạng',
        'tiền nhà', 'thuê nhà', 'phí quản lý', 'phí dịch vụ chung cư',
        'bảo hiểm', 'tiền gas',
        'hóa đơn', 'tiện ích', 'phí', 'cước',
        // === USA ===
        'comcast', 'xfinity', 'at&t', 'verizon', 't-mobile', 'sprint',
        'spectrum', 'cox', 'centurylink', 'frontier communications',
        'pg&e', 'con edison', 'duke energy', 'dominion energy',
        'state farm', 'geico', 'allstate', 'progressive',
        'rent', 'mortgage', 'hoa', 'property tax',
        // === Europe ===
        'edf', 'engie', 'british gas', 'eon', 'vattenfall', 'iberdrola',
        'vodafone', 'orange', 'o2', 'three', 'deutsche telekom', 'swisscom',
        'sky', 'bt', 'free mobile', 'bouygues', 'sfr',
        'thames water', 'veolia', 'suez',
        'council tax', 'gez', 'loyer', 'miete',
        // General
        'electricity', 'electric', 'water', 'wifi', 'internet',
        'phone bill', 'utility', 'power', 'insurance',
      ],
      'Healthcare': [
        // === Vietnam ===
        'vinmec', 'fv hospital', 'hoàn mỹ', 'chợ rẫy', 'bạch mai',
        'đại học y dược', 'y khoa', 'bệnh viện', 'phòng khám',
        'nha khoa', 'mắt', 'da liễu', 'tai mũi họng',
        'nhà thuốc', 'pharmacity', 'long châu', 'an khang',
        'thuốc', 'dược', 'y tế', 'khám bệnh', 'xét nghiệm',
        'nha sĩ', 'bác sĩ', 'chữa bệnh', 'điều trị',
        'bảo hiểm y tế', 'bhyt',
        // === USA ===
        'cvs', 'walgreens', 'rite aid', 'kaiser', 'cigna', 'aetna',
        'united health', 'blue cross', 'blue shield', 'humana',
        'mayo clinic', 'cleveland clinic', 'johns hopkins',
        'zocdoc', 'one medical', 'teladoc', 'goodrx',
        // === Europe ===
        'boots', 'superdrug', 'lloyds pharmacy', 'apotheke', 'pharmacie',
        'doctolib', 'nhs', 'krankenkasse', 'sécurité sociale',
        'bupa', 'axa health', 'sanitas',
        // General
        'pharmacy', 'hospital', 'clinic', 'doctor', 'medical',
        'health', 'dental', 'medicine', 'drugstore',
      ],
      'Education': [
        // === Vietnam ===
        'đại học', 'cao đẳng', 'trung học', 'tiểu học', 'mầm non',
        'trường', 'học phí', 'sách giáo khoa', 'sách vở',
        'trung tâm anh ngữ', 'vus', 'iig', 'ielts', 'toeic',
        'apax', 'yola', 'wall street english', 'british council',
        'topica', 'funix',
        'gia sư', 'luyện thi', 'khóa học', 'dạy thêm', 'học thêm',
        'nhà sách', 'fahasa', 'phương nam', 'tiki sách',
        'du học', 'học bổng',
        // === USA ===
        'chegg', 'khan academy', 'masterclass', 'skillshare',
        'linkedin learning', 'pluralsight', 'datacamp',
        'college board', 'sat', 'act', 'gre', 'gmat',
        'barnes & noble', 'amazon textbook',
        'student loan', 'tuition', 'semester',
        // === Europe ===
        'open university', 'futurelearn', 'guardian masterclasses',
        'goethe institut', 'alliance française', 'cervantes',
        'erasmus', 'waterstones', 'thalia', 'fnac livres',
        // General
        'school', 'university', 'college', 'course', 'book',
        'training', 'certificate', 'education', 'learning',
        'edx', 'coursera', 'udemy',
      ],
      'Salary': [
        // Vietnam
        'lương', 'lương tháng', 'lương cơ bản', 'thưởng', 'phụ cấp',
        'tiền lương', 'chuyển lương', 'nhận lương', 'trả lương',
        'lương net', 'lương gross', 'tháng 13', 'thưởng tết',
        // General
        'salary', 'payroll', 'wage', 'bonus', 'monthly salary',
        'direct deposit', 'gehalt', 'salaire', 'stipendio',
      ],
      'Freelance': [
        // Vietnam
        'tự do', 'hợp đồng', 'dự án', 'phí dịch vụ',
        'khoán', 'cộng tác viên', 'ctv', 'part-time',
        // General
        'freelance', 'contract', 'project fee', 'consulting',
        'dịch vụ', 'invoice', 'gig', 'fiverr', 'upwork',
      ],
      'Investment': [
        // === Vietnam ===
        'chứng khoán', 'cổ phiếu', 'trái phiếu', 'quỹ đầu tư',
        'vn-index', 'vnindex', 'ssi', 'vndirect', 'tcbs', 'fpts',
        'vps', 'mirae asset', 'kis', 'bsc',
        'lãi suất', 'tiền gửi', 'tiết kiệm', 'ngân hàng',
        'vietcombank', 'vcb', 'techcombank', 'tcb', 'mb bank',
        'bidv', 'agribank', 'vpbank', 'acb', 'tpbank', 'sacombank',
        'cổ tức', 'lãi', 'đầu tư',
        // === USA ===
        'robinhood', 'fidelity', 'charles schwab', 'vanguard', 'etrade',
        'td ameritrade', 'merrill', 'sofi', 'wealthfront', 'betterment',
        's&p 500', 'nasdaq', 'dow jones', 'nyse',
        'coinbase', 'kraken', 'gemini',
        // === Europe ===
        'degiro', 'trading 212', 'etoro', 'revolut invest', 'scalable capital',
        'trade republic', 'saxo', 'interactive brokers',
        'binance', 'bitstamp',
        'dax', 'ftse', 'cac 40', 'euronext',
        // General
        'dividend', 'interest', 'stock', 'bond', 'fund', 'investment',
        'crypto', 'bitcoin', 'ethereum', 'etf', '401k', 'ira',
      ],
      'Gift': [
        // Vietnam
        'quà tặng', 'quà', 'biếu', 'mừng', 'lì xì', 'tiền mừng',
        'từ thiện', 'quyên góp', 'ủng hộ', 'thiện nguyện',
        // General
        'gift', 'present', 'donation', 'charity', 'gofundme',
        'cadeau', 'geschenk', 'regalo',
      ],
    };

    // Find the best matching category
    int bestScore = 0;
    String bestCategory = 'Other';

    for (var entry in categoryKeywords.entries) {
      int score = 0;
      for (var keyword in entry.value) {
        if (text.contains(keyword)) {
          score++;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestCategory = entry.key;
      }
    }

    return bestCategory;
  }

  /// Process OCR result and add category suggestion
  Map<String, dynamic> processWithCategorySuggestion(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    result['category'] = suggestCategory(data);
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
