import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/config/aws_config.dart';

void main() {
  group('AWSConfig.sessionToken', () {
    test('returns null when the dotenv value is empty '
        '(amplify.yml writes PLUTUS_AWS_SESSION_TOKEN= with no value)', () {
      dotenv.loadFromString(envString:'PLUTUS_AWS_SESSION_TOKEN=');
      expect(AWSConfig.sessionToken, isNull);
    });

    test('returns the token when dotenv has a real value', () {
      dotenv.loadFromString(envString:'PLUTUS_AWS_SESSION_TOKEN=abc123');
      expect(AWSConfig.sessionToken, 'abc123');
    });

    test('returns null when the variable is absent entirely', () {
      dotenv.loadFromString(envString:'OTHER_KEY=value');
      expect(AWSConfig.sessionToken, isNull);
    });
  });
}
