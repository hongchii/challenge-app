import 'dart:convert';

/// 한글 인코딩 문제 해결을 위한 유틸리티 함수들
class TextEncoding {
  /// 문자열을 UTF-8로 안전하게 정규화
  /// 
  /// 간헐적으로 발생하는 인코딩 문제를 해결하기 위해
  /// 문자열을 UTF-8로 명시적으로 변환하고 정규화합니다.
  static String normalizeString(dynamic value) {
    if (value == null) return '';
    
    // 이미 String인 경우
    if (value is String) {
      try {
        // 빈 문자열이면 바로 반환
        if (value.isEmpty) return '';
        
        // UTF-8로 명시적으로 인코딩/디코딩하여 정규화
        // 이 과정에서 잘못된 인코딩이 수정됩니다
        final utf8Bytes = utf8.encode(value);
        final normalized = utf8.decode(utf8Bytes, allowMalformed: true);
        
        // 유효한 UTF-8 문자인지 확인하고 깨진 문자 제거
        return normalized.replaceAll(RegExp(r'[\uFFFD\u0000]'), '');
      } catch (e) {
        // UTF-8 디코딩 실패 시, codeUnits를 사용한 대체 방법 시도
        try {
          // codeUnits를 사용하여 안전하게 변환
          // 유효한 유니코드 범위의 문자만 유지
          final codeUnits = value.codeUnits.where((c) => 
            (c > 0 && c < 0xD800) || (c >= 0xE000 && c <= 0x10FFFF)
          ).toList();
          final result = String.fromCharCodes(codeUnits);
          return result.replaceAll(RegExp(r'[\uFFFD\u0000]'), '');
        } catch (e2) {
          // 모든 방법 실패 시 원본 반환 (최후의 수단)
          return value;
        }
      }
    }
    
    // String이 아닌 경우 toString() 후 정규화
    return normalizeString(value.toString());
  }

  /// JSON에서 문자열 필드를 안전하게 추출
  /// 
  /// Firestore나 JSON에서 가져온 데이터의 문자열 필드를
  /// 안전하게 추출하고 정규화합니다.
  static String safeStringFromJson(Map<String, dynamic> json, String key, {String defaultValue = ''}) {
    final value = json[key];
    if (value == null) return defaultValue;
    return normalizeString(value);
  }

  /// 리스트에서 문자열을 안전하게 추출
  static String safeStringFromList(List<dynamic> list, int index, {String defaultValue = ''}) {
    if (index < 0 || index >= list.length) return defaultValue;
    return normalizeString(list[index]);
  }

  /// 텍스트 입력 필드에서 받은 문자열 정규화
  /// 
  /// TextField나 TextFormField에서 입력받은 텍스트를
  /// 저장하기 전에 정규화합니다.
  static String normalizeInput(String? input) {
    if (input == null || input.isEmpty) return '';
    return normalizeString(input.trim());
  }

  /// 문자열이 유효한 UTF-8인지 확인
  static bool isValidUtf8(String text) {
    try {
      // UTF-8로 인코딩/디코딩이 가능한지 확인
      final bytes = text.codeUnits;
      String.fromCharCodes(bytes);
      return !text.contains(RegExp(r'[\uFFFD]'));
    } catch (e) {
      return false;
    }
  }
}

