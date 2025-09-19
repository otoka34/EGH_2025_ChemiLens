import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';

import '../models/detection_result.dart';
import '../screens/search/search_screen.dart'; // CompoundInfoをインポート

class ApiService {
  static String get _baseUrl {
    // ビルド時に --dart-define で指定された環境変数を読み込む
    // Vercelのrewrites設定に合わせて、パスに /api を含める
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:3000', // ローカル開発用のデフォルト値
    );
    return baseUrl.endsWith('/api') ? baseUrl : '$baseUrl/api';
  }

  static final Dio _dio = Dio();

  static Future<DetectionResult> analyzeImage(
    Uint8List imageBytes,
    String? mimeType,
  ) async {
    try {
      // MIMEタイプを確実に設定
      String finalMimeType = mimeType ?? 'image/jpeg';
      if (finalMimeType == 'application/octet-stream') {
        finalMimeType = 'image/jpeg';
      }

      print('Sending image with MIME type: $finalMimeType');

      // FormDataを作成して画像を添付
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: 'upload.jpg',
          contentType: MediaType.parse(finalMimeType),
        ),
      });

      // バックエンドの /analyze エンドポイントにPOSTリクエストを送信
      print('Sending POST request to: $_baseUrl/analyze');
      final response = await _dio.post('$_baseUrl/analyze', data: formData);

      if (response.statusCode == 200) {
        print('API Response: ${response.data}');
        // 成功レスポンスをDetectionResultに変換
        return DetectionResult.fromApiResponse(response.data);
      } else {
        // エラーレスポンス
        throw Exception('Failed to analyze image: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Dioのエラー（ネットワークエラーなど）
      print('DioException: ${e.type}, ${e.message}');
      if (e.response != null) {
        print('Response status: ${e.response!.statusCode}');
        print('Response data: ${e.response!.data}');
      }
      throw Exception('Failed to connect to the server: $e');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // SDFデータをGLBに変換するメソッド
  static Future<Uint8List> convertSdfToGlb(String sdfData) async {
    try {
      final response = await _dio.post<List<int>>(
        '$_baseUrl/convert',
        data: sdfData,
        options: Options(
          headers: {'Content-Type': 'text/plain'},
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data!);
      } else {
        throw Exception(
          'Failed to convert SDF to GLB: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Failed to connect to the server for conversion: $e');
    } catch (e) {
      throw Exception('An unexpected error occurred during conversion: $e');
    }
  }

  // 元素名や記号で化合物を検索するメソッド
  static Future<List<CompoundInfo>> searchCompoundsByQuery(String query) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/search',
        queryParameters: {'element': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => CompoundInfo.fromJson(item)).toList();
      } else {
        throw Exception(
          'Failed to search compounds: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorMessage =
            e.response?.data['error'] ?? 'Unknown error from server';
        throw Exception(errorMessage);
      }
      throw Exception('Failed to connect to the server');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  // CIDからSDFデータを取得するメソッド
  static Future<String?> getSdfDataByCid(int cid) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/cidtosdf',
        data: [
          {'cids': cid}
        ],
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (data.isNotEmpty && data[0]['sdf'] != null) {
          return data[0]['sdf'] as String;
        }
        return null;
      } else {
        throw Exception(
          'Failed to get SDF data: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorMessage =
            e.response?.data['error'] ?? 'Unknown error from server';
        throw Exception(errorMessage);
      }
      throw Exception('Failed to connect to the server');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }
}
