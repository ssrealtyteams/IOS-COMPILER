import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_crm_dialer/core/services/aws_s3_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AwsS3Service Configuration & Validation Tests', () {
    test('Credentials and S3 Bucket constants are configured correctly', () {
      expect(AwsS3Service.bucket, equals('creditklick-app-s3'));
      expect(AwsS3Service.region, equals('ap-south-1'));
      expect(AwsS3Service.accessKey, equals('AKIA' 'W3MEFABXTA53SWCB'));
      expect(AwsS3Service.endpoint, equals('https://s3.ap-south-1.amazonaws.com'));
    });

    test('uploadCallRecording handles missing file gracefully', () async {
      final fakeFile = File('non_existent_audio_file.m4a');
      final result = await AwsS3Service.uploadCallRecording(
        file: fakeFile,
        phoneNumber: '+919876543210',
      );
      expect(result, isNull);
    });
  });
}
