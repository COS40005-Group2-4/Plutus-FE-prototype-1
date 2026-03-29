import 'package:flutter_dotenv/flutter_dotenv.dart';

class AWSConfig {
  static String get accessKeyId =>
      dotenv.env['PLUTUS_AWS_ACCESS_KEY_ID'] ??
      const String.fromEnvironment(
        'PLUTUS_AWS_ACCESS_KEY_ID',
        defaultValue: 'YOUR_ACCESS_KEY_ID',
      );

  static String get secretAccessKey =>
      dotenv.env['PLUTUS_AWS_SECRET_ACCESS_KEY'] ??
      const String.fromEnvironment(
        'PLUTUS_AWS_SECRET_ACCESS_KEY',
        defaultValue: 'YOUR_SECRET_ACCESS_KEY',
      );
  
  static String? get sessionToken =>
      dotenv.env['PLUTUS_AWS_SESSION_TOKEN'] ??
      const String.fromEnvironment('PLUTUS_AWS_SESSION_TOKEN').ifEmpty(null);

  static String get region =>
      dotenv.env['PLUTUS_AWS_REGION'] ??
      const String.fromEnvironment(
        'PLUTUS_AWS_REGION',
        defaultValue: 'ap-southeast-1',
      );

  static String get bucketName =>
      dotenv.env['PLUTUS_AWS_S3_BUCKET_NAME'] ??
      const String.fromEnvironment(
        'PLUTUS_AWS_S3_BUCKET_NAME',
        defaultValue: 'your-s3-bucket-name',
      );

  static String get dynamoTcTableName =>
      dotenv.env['PLUTUS_DYNAMO_TC_TABLE_NAME'] ??
      const String.fromEnvironment(
        'PLUTUS_DYNAMO_TC_TABLE_NAME',
        defaultValue: 'plutus-tc-acceptance',
      );
}

extension StringExtension on String {
  String? ifEmpty(String? value) {
    return isEmpty ? value : this;
  }
}
