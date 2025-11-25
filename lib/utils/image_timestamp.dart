import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

/// 이미지에 날짜/시간 타임스탬프를 추가하는 유틸리티 클래스
class ImageTimestamp {
  /// 이미지에 날짜/시간 오버레이를 추가합니다.
  /// 
  /// [imageBytes] 원본 이미지 바이트 데이터
  /// [dateTime] 표시할 날짜/시간 (null이면 현재 시간 사용)
  /// [position] 타임스탬프 위치 ('bottomRight', 'bottomLeft', 'topRight', 'topLeft')
  /// 
  /// 반환: 타임스탬프가 추가된 이미지 바이트 데이터
  static Future<Uint8List> addTimestamp(
    Uint8List imageBytes, {
    DateTime? dateTime,
    String position = 'bottomRight',
  }) async {
    try {
      debugPrint('🖼️ 타임스탬프 추가 시작 - 이미지 크기: ${imageBytes.length} bytes');
      
      // 이미지 디코딩
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('이미지를 디코딩할 수 없습니다');
      }
      debugPrint('✅ 이미지 디코딩 성공: ${originalImage.width}x${originalImage.height}');

      // 날짜/시간 포맷팅
      final now = dateTime ?? DateTime.now();
      final dateFormat = DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR');
      final timeFormat = DateFormat('HH시 mm분 ss초');
      final dateString = dateFormat.format(now);
      final timeString = timeFormat.format(now);
      debugPrint('📅 타임스탬프 텍스트: $dateString\n$timeString');

      // 텍스트 스타일 설정
      const fontSize = 28.0; // 크게 표시
      const padding = 16.0;

      // 텍스트 크기 계산 (두 줄로 표시)
      final maxTextWidth = dateString.length > timeString.length 
          ? dateString.length 
          : timeString.length;
      final textWidth = maxTextWidth * (fontSize * 0.6).round();
      final textHeight = (fontSize * 2.2).round(); // 두 줄 + 여백

      // 타임스탬프 박스 위치 계산 (position에 따라)
      final boxWidth = textWidth + padding * 2;
      final boxHeight = textHeight + padding * 2;
      
      double boxX, boxY;
      final margin = 20.0; // 가장자리 여백
      
      switch (position) {
        case 'center':
          boxX = ((originalImage.width - boxWidth) / 2).round().toDouble();
          boxY = ((originalImage.height - boxHeight) / 2).round().toDouble();
          break;
        case 'topLeft':
          boxX = margin;
          boxY = margin;
          break;
        case 'topRight':
          boxX = (originalImage.width - boxWidth - margin).round().toDouble();
          boxY = margin;
          break;
        case 'bottomLeft':
          boxX = margin;
          boxY = (originalImage.height - boxHeight - margin).round().toDouble();
          break;
        case 'bottomRight':
        default:
          boxX = (originalImage.width - boxWidth - margin).round().toDouble();
          boxY = (originalImage.height - boxHeight - margin).round().toDouble();
          break;
      }

      debugPrint('📍 타임스탬프 위치: ($boxX, $boxY) - position: $position');
      
      // 이미지를 ui.Image로 변환
      debugPrint('🔄 ui.Image로 변환 중...');
      final codec = await ui.instantiateImageCodec(
        imageBytes,
      );
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;
      debugPrint('✅ ui.Image 변환 성공');

      // Canvas로 텍스트 그리기
      debugPrint('🎨 Canvas로 그리기 시작...');
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // 이미지 그리기
      canvas.drawImage(uiImage, Offset.zero, Paint());
      debugPrint('✅ 원본 이미지 그리기 완료');
      
      // 배경 박스 그리기 (반투명 검은색)
      final bgPaint = Paint()
        ..color = const Color(0x80000000) // 반투명 검은색
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            boxX.toDouble(),
            boxY.toDouble(),
            boxWidth.toDouble(),
            boxHeight.toDouble(),
          ),
          const Radius.circular(12),
        ),
        bgPaint,
      );
      debugPrint('✅ 배경 박스 그리기 완료');
      
      // 텍스트 그리기 (두 줄로 표시, 가운데 정렬)
      final dateTextPainter = TextPainter(
        text: TextSpan(
          text: dateString,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      dateTextPainter.layout(maxWidth: boxWidth.toDouble());
      
      final timeTextPainter = TextPainter(
        text: TextSpan(
          text: timeString,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      timeTextPainter.layout(maxWidth: boxWidth.toDouble());
      
      // 가운데 정렬을 위한 오프셋 계산
      final boxCenterX = boxX + boxWidth / 2;
      final dateY = boxY + padding;
      final timeY = boxY + padding + fontSize * 1.2;
      
      // 날짜 그리기 (가운데 정렬)
      dateTextPainter.paint(
        canvas,
        Offset(boxCenterX - dateTextPainter.width / 2, dateY),
      );
      
      // 시간 그리기 (가운데 정렬)
      timeTextPainter.paint(
        canvas,
        Offset(boxCenterX - timeTextPainter.width / 2, timeY),
      );
      debugPrint('✅ 텍스트 그리기 완료');
      
      // Canvas를 이미지로 변환
      debugPrint('🔄 Canvas를 이미지로 변환 중...');
      final picture = recorder.endRecording();
      final timestampedImage = await picture.toImage(
        originalImage.width,
        originalImage.height,
      );
      debugPrint('✅ Canvas 이미지 변환 성공');
      
      // PNG로 인코딩 후 JPEG로 변환
      debugPrint('🔄 PNG 인코딩 중...');
      final byteData = await timestampedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('이미지 변환 실패');
      }
      debugPrint('✅ PNG 인코딩 성공');
      
      // PNG를 디코딩하여 JPEG로 인코딩
      debugPrint('🔄 JPEG로 변환 중...');
      final pngBytes = byteData.buffer.asUint8List();
      final decodedImage = img.decodeImage(pngBytes);
      if (decodedImage == null) {
        throw Exception('이미지 디코딩 실패');
      }
      
      final encodedImage = img.encodeJpg(decodedImage, quality: 90);
      debugPrint('✅ 타임스탬프 추가 완료! 최종 크기: ${encodedImage.length} bytes');
      return Uint8List.fromList(encodedImage);
    } catch (e, stackTrace) {
      debugPrint('❌ 타임스탬프 추가 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      // 오류 발생 시 원본 이미지 반환
      return imageBytes;
    }
  }

  /// File 이미지에 타임스탬프를 추가하고 새로운 File을 반환합니다.
  static Future<File> addTimestampToFile(
    File imageFile, {
    DateTime? dateTime,
    String position = 'bottomRight',
  }) async {
    final imageBytes = await imageFile.readAsBytes();
    final timestampedBytes = await addTimestamp(
      imageBytes,
      dateTime: dateTime,
      position: position,
    );
    
    // 임시 파일에 저장
    final timestampedFile = File('${imageFile.path}_timestamped.jpg');
    await timestampedFile.writeAsBytes(timestampedBytes);
    return timestampedFile;
  }
}

