import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 画像圧縮サービス
class ImageCompressionService {
  /// 画像を圧縮（500KB以下を目標）
  static Future<Uint8List> compressImage(Uint8List imageData) async {
    try {
      // 画像をデコード
      final image = img.decodeImage(imageData);
      if (image == null) {
        print('Failed to decode image, returning original');
        return imageData;
      }

      print('Original image: ${image.width}x${image.height}');

      // 段階的に圧縮
      var quality = 85;
      var maxWidth = 1200;
      Uint8List? compressedData;

      while (quality >= 20 && maxWidth >= 400) {
        // リサイズ（アスペクト比を保持）
        img.Image resized = image;
        if (image.width > maxWidth) {
          resized = img.copyResize(
            image,
            width: maxWidth,
            interpolation: img.Interpolation.average,
          );
        }

        // JPEG圧縮
        compressedData = Uint8List.fromList(
          img.encodeJpg(resized, quality: quality),
        );

        print(
          'Compressed to ${resized.width}x${resized.height}, quality: $quality, size: ${compressedData.length} bytes',
        );

        // 500KB以下なら完了
        if (compressedData.length <= 500 * 1024) {
          print('Compression successful: ${compressedData.length} bytes');
          return compressedData;
        }

        // 次の圧縮レベルを試す
        if (quality > 50) {
          quality -= 15;
        } else if (maxWidth > 600) {
          maxWidth = (maxWidth * 0.8).round();
          quality = 70; // 解像度を下げたら品質を少し上げる
        } else {
          quality -= 10;
          maxWidth = (maxWidth * 0.9).round();
        }
      }

      // 最終的に500KBを超える場合でも圧縮済みデータを返す
      print('Final compression: ${compressedData?.length ?? 0} bytes');
      return compressedData ?? imageData;
    } catch (e) {
      print('Error compressing image: $e');
      return imageData;
    }
  }
}
