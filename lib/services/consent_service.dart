import 'dart:convert';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/aws_config.dart';
import 'interfaces/i_consent_service.dart';

class ConsentService implements IConsentService {
  static final ConsentService _instance = ConsentService._internal();
  factory ConsentService() => _instance;
  ConsentService._internal();

  String get _region => AWSConfig.region;
  String get _tableName => AWSConfig.dynamoTcTableName;
  String get _dynamoHost => 'dynamodb.$_region.amazonaws.com';

  AWSSigV4Signer get _signer => AWSSigV4Signer(
        credentialsProvider: AWSCredentialsProvider(
          AWSCredentials(
            AWSConfig.accessKeyId,
            AWSConfig.secretAccessKey,
            AWSConfig.sessionToken,
          ),
        ),
      );

  AWSCredentialScope get _scope => AWSCredentialScope(
        region: _region,
        service: AWSService('dynamodb'),
      );

  @override
  Future<bool> hasAcceptedTerms(String email) async {
    _validateCredentials();

    final body = jsonEncode({
      'TableName': _tableName,
      'Key': {
        'email': {'S': email},
      },
    });

    final uri = Uri.https(_dynamoHost, '/');
    final request = AWSHttpRequest(
      method: AWSHttpMethod.post,
      uri: uri,
      headers: {
        'Content-Type': 'application/x-amz-json-1.0',
        'X-Amz-Target': 'DynamoDB_20120810.GetItem',
      },
      body: utf8.encode(body),
    );

    final signedRequest = await _signer.sign(
      request,
      credentialScope: _scope,
    );

    final response = await http.post(
      signedRequest.uri,
      headers: signedRequest.headers,
      body: await signedRequest.bodyBytes,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data.containsKey('Item');
    } else {
      throw ConsentServiceException(
        'DynamoDB GetItem failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  @override
  Future<void> recordAcceptance(String email) async {
    _validateCredentials();

    final body = jsonEncode({
      'TableName': _tableName,
      'Item': {
        'email': {'S': email},
        'agreed_at': {'S': DateTime.now().toUtc().toIso8601String()},
      },
    });

    final uri = Uri.https(_dynamoHost, '/');
    final request = AWSHttpRequest(
      method: AWSHttpMethod.post,
      uri: uri,
      headers: {
        'Content-Type': 'application/x-amz-json-1.0',
        'X-Amz-Target': 'DynamoDB_20120810.PutItem',
      },
      body: utf8.encode(body),
    );

    final signedRequest = await _signer.sign(
      request,
      credentialScope: _scope,
    );

    final response = await http.post(
      signedRequest.uri,
      headers: signedRequest.headers,
      body: await signedRequest.bodyBytes,
    );

    if (response.statusCode != 200) {
      throw ConsentServiceException(
        'DynamoDB PutItem failed: ${response.statusCode} ${response.body}',
      );
    }

    if (kDebugMode) {
      print('ConsentService: Recorded T&C acceptance for $email');
    }
  }

  void _validateCredentials() {
    if (AWSConfig.accessKeyId == 'YOUR_ACCESS_KEY_ID' ||
        AWSConfig.secretAccessKey == 'YOUR_SECRET_ACCESS_KEY') {
      throw ConsentServiceException(
        'AWS credentials not configured. Check your .env file.',
      );
    }
  }
}

class ConsentServiceException implements Exception {
  final String message;
  ConsentServiceException(this.message);

  @override
  String toString() => 'ConsentServiceException: $message';
}
