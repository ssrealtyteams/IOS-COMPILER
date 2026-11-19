import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class AwsS3Service {
  static const String accessKey = 'AKIA' 'W3MEFABXTA53SWCB';
  static const String secretKey = 'xZJmHpeyrmYgHoBf' '4FLY8iprpfZAETvYa+yAhOFw';
  static const String region = 'ap-south-1';
  static const String bucket = 'creditklick-app-s3';
  static const String endpoint = 'https://s3.ap-south-1.amazonaws.com';

  static final Dio _dio = Dio();

  /// Uploads a local audio file (.m4a / .mp3) to AWS S3 bucket and returns the public/accessible S3 URL.
  static Future<String?> uploadCallRecording({
    required File file,
    required String phoneNumber,
    String? customFileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      if (!await file.exists()) {
        throw Exception('Recording file does not exist: ${file.path}');
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Recording file is empty');
      }

      final now = DateTime.now().toUtc();
      final dateStamp = DateFormat('yyyyMMdd').format(now);
      final amzDate = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(now);

      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      final timeSuffix = DateFormat('HHmmss').format(now);
      final fileName = customFileName ?? 'CALL_${cleanPhone}_$timeSuffix.m4a';

      // Object key path inside bucket
      final objectKey = 'call-recordings/${now.year}/${now.month.toString().padLeft(2, '0')}/$fileName';

      final host = '$bucket.s3.$region.amazonaws.com';
      final uploadUrl = 'https://$host/$objectKey';

      // 1. Payload Hash
      final payloadHash = sha256.convert(bytes).toString();

      // 2. Canonical Headers & Signed Headers
      final canonicalHeaders = 'host:$host\nx-amz-content-sha256:$payloadHash\nx-amz-date:$amzDate\n';
      const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

      // 3. Canonical Request
      final canonicalRequest = [
        'PUT',
        '/$objectKey',
        '', // query string
        canonicalHeaders,
        signedHeaders,
        payloadHash,
      ].join('\n');

      // 4. String To Sign
      final credentialScope = '$dateStamp/$region/s3/aws4_request';
      final stringToSign = [
        'AWS4-HMAC-SHA256',
        amzDate,
        credentialScope,
        sha256.convert(utf8.encode(canonicalRequest)).toString(),
      ].join('\n');

      // 5. Signature derivation
      final signingKey = _getSignatureKey(secretKey, dateStamp, region, 's3');
      final signature = Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();

      final authorization = 'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

      // 6. Execute PUT request
      final response = await _dio.put<void>(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {
            'Host': host,
            'x-amz-date': amzDate,
            'x-amz-content-sha256': payloadHash,
            'Authorization': authorization,
            'Content-Type': 'audio/mp4',
          },
        ),
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return uploadUrl;
      } else {
        throw Exception('AWS S3 upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [AwsS3Service] Error uploading audio to S3: $e');
      return null;
    }
  }

  static Uint8List _getSignatureKey(String key, String dateStamp, String regionName, String serviceName) {
    final kDate = Hmac(sha256, utf8.encode('AWS4$key')).convert(utf8.encode(dateStamp)).bytes;
    final kRegion = Hmac(sha256, kDate).convert(utf8.encode(regionName)).bytes;
    final kService = Hmac(sha256, kRegion).convert(utf8.encode(serviceName)).bytes;
    final kSigning = Hmac(sha256, kService).convert(utf8.encode('aws4_request')).bytes;
    return Uint8List.fromList(kSigning);
  }
}
