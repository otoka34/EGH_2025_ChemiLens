import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../models/detection_result.dart';

class OpenAIService {
  // ★あなたのAPIキーに差し替え
  static const String _apiKey = '';
  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini';

  static final Dio _dio =
      Dio(
          BaseOptions(
            headers: const {'Content-Type': 'application/json'},
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              options.headers['Authorization'] = 'Bearer $_apiKey';
              return handler.next(options);
            },
          ),
        );

  // 共通の JSON Schema（厳密）
  static Map<String, dynamic> _schema() => {
    "name": "ChemilensDetectionResult",
    "schema": {
      "type": "object",
      "properties": {
        "object_name": {"type": "string", "description": "認識された物体名（日本語優先）"},
        "object_category": {"type": "string", "description": "物体のカテゴリ（日本語）"},
        "molecules": {
          "type": "array",
          "minItems": 3,
          "maxItems": 5,
          "items": {
            "type": "object",
            "properties": {
              "name_jp": {"type": "string"},
              "name_en": {"type": "string"},
              "formula": {"type": "string"},
              "description": {"type": "string"},
              "confidence": {"type": "number", "minimum": 0, "maximum": 1},
            },
            "required": [
              "name_jp",
              "name_en",
              "formula",
              "description",
              "confidence",
            ],
            "additionalProperties": false,
          },
        },
      },
      "required": ["object_name", "object_category", "molecules"],
      "additionalProperties": false,
    },
    "strict": true,
  };

  // 画像(PNGバイト列) → 推定
  static Future<DetectionResult> analyzePngBytes(Uint8List pngBytes) async {
    final base64Png = base64Encode(pngBytes);
    final body = {
      "model": _model,
      "temperature": 0.2,
      "messages": [
        {
          "role": "system",
          "content": "あなたは物体認識と化学物質推定の専門家です。厳密なJSON（指定スキーマ）で返してください。",
        },
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text":
                  "この画像の物体名とカテゴリ、さらに含まれうる代表的な分子を3〜5個（日本語名/英語名/化学式/説明/確信度0-1）で返してください。",
            },
            {
              "type": "image_url",
              "image_url": {"url": "data:image/png;base64,$base64Png"},
            },
          ],
        },
      ],
      "response_format": {"type": "json_schema", "json_schema": _schema()},
    };

    return _postWithRetry(body);
  }

  // ★ 追加：テキスト（物体名） → 推定
  static Future<DetectionResult> analyzeByObjectName(String objectName) async {
    final prompt =
        "対象: $objectName\n"
        "この対象のカテゴリを推定し、実際に含まれうる代表的な分子を3〜5個、"
        "日本語名/英語名/化学式/説明/確信度(0〜1)で、厳密なJSON（指定スキーマ）として返してください。"
        "わからない場合は一般的な可能性を挙げ、信頼度を低めに設定してください。";

    final body = {
      "model": _model,
      "temperature": 0.2,
      "messages": [
        {
          "role": "system",
          "content": "あなたは化学物質推定の専門家です。厳密なJSON（指定スキーマ）で返してください。",
        },
        {
          "role": "user",
          "content": [
            {"type": "text", "text": prompt},
          ],
        },
      ],
      "response_format": {"type": "json_schema", "json_schema": _schema()},
    };

    return _postWithRetry(body);
  }

  // 共通：POST + 429指数バックオフ + エラー整形
  static Future<DetectionResult> _postWithRetry(
    Map<String, dynamic> body,
  ) async {
    int attempt = 0;
    const maxAttempts = 4;
    while (attempt < maxAttempts) {
      try {
        final res = await _dio.post(_endpoint, data: jsonEncode(body));
        final data = res.data;
        final content = data?['choices']?[0]?['message']?['content']
            ?.toString();
        if (content == null || content.isEmpty) {
          throw Exception('OpenAI応答の解析に失敗（contentが空）');
        }
        return DetectionResult.fromJson(jsonDecode(content));
      } on DioException catch (e) {
        final status = e.response?.statusCode ?? 0;
        final body = e.response?.data;
        final code = (body is Map)
            ? (body['error']?['code']?.toString())
            : null;

        if (code == 'insufficient_quota') {
          throw Exception(
            'OpenAIの利用上限/残高が不足しています（insufficient_quota）。Billingで上限を上げるかクレジットを追加してください。',
          );
        }

        if (status == 429 && attempt < maxAttempts - 1) {
          final retryAfter =
              int.tryParse(e.response?.headers.value('retry-after') ?? '') ?? 0;
          final baseMs = (600 * pow(2, attempt)).toInt(); // 0.6s,1.2s,2.4s...
          final jitter = 0.5 + Random().nextDouble(); // 0.5〜1.5
          final waitMs = (retryAfter > 0)
              ? retryAfter * 1000
              : (baseMs * jitter).toInt();
          await Future.delayed(Duration(milliseconds: waitMs));
          attempt++;
          continue;
        }
        throw Exception('OpenAIエラー status=$status body=$body');
      }
    }
    throw Exception('429のリトライに失敗しました。時間を置いて再試行してください。');
  }
}
