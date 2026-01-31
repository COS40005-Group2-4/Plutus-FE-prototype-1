import 'package:flutter_dotenv/flutter_dotenv.dart';

class AWSConfig {
  static String get accessKeyId =>
      dotenv.env['AWS_ACCESS_KEY_ID'] ??
      const String.fromEnvironment(
        'AWS_ACCESS_KEY_ID',
        defaultValue: 'YOUR_ACCESS_KEY_ID',
      );

  static String get secretAccessKey =>
      dotenv.env['AWS_SECRET_ACCESS_KEY'] ??
      const String.fromEnvironment(
        'AWS_SECRET_ACCESS_KEY',
        defaultValue: 'YOUR_SECRET_ACCESS_KEY',
      );
  
  static String? get sessionToken =>
      dotenv.env['AWS_SESSION_TOKEN'] ??
      const String.fromEnvironment('AWS_SESSION_TOKEN').ifEmpty(null);

  static String get region =>
      dotenv.env['AWS_REGION'] ??
      const String.fromEnvironment(
        'AWS_REGION',
        defaultValue: 'us-east-1',
      );

  static String get bucketName =>
      dotenv.env['AWS_S3_BUCKET_NAME'] ??
      const String.fromEnvironment(
        'AWS_S3_BUCKET_NAME',
        defaultValue: 'your-s3-bucket-name',
      );
}

extension StringExtension on String {
  String? ifEmpty(String? value) {
    return isEmpty ? value : this;
  }
}
