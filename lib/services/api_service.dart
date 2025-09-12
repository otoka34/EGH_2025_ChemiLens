import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../models/detection_result.dart';

class ApiService {
  // TODO: 環境変数などから取得するようにする
  static const String _baseUrl = 'http://localhost:3000';

  static final Dio _dio = Dio();

  static Future<DetectionResult> analyzeImage(Uint8List imageBytes, String? mimeType) async {
    try {
      // FormDataを作成して画像を添付
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: 'upload',
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      });

      // バックエンドの /analyze エンドポイントにPOSTリクエストを送信
      final response = await _dio.post(
        '$_baseUrl/analyze',
        data: formData,
      );

      if (response.statusCode == 200) {
        // 成功レスポンスをDetectionResultに変換
        return DetectionResult.fromJson(response.data);
      } else {
        // エラーレスポンス
        throw Exception('Failed to analyze image: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Dioのエラー（ネットワークエラーなど）
      throw Exception('Failed to connect to the server: $e');
    } catch (e) {
      // その他のエラー
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // 追加: SDFデータをGLBに変換するメソッド
  static Future<Uint8List> convertSdfToGlb(String sdfData) async {
    try {
      final response = await _dio.post<Uint8List>( // レスポンスの型をUint8Listに指定
        '$_baseUrl/convert-to-glb',
        data: sdfData,
        options: Options(
          headers: {
            'Content-Type': 'text/plain',
          },
          responseType: ResponseType.bytes, // レスポンスをバイト配列として受け取る
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      } else {
        throw Exception('Failed to convert SDF to GLB: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to connect to the server for conversion: $e');
    } catch (e) {
      throw Exception('An unexpected error occurred during conversion: $e');
    }
  }
}
