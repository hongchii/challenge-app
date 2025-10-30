import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // 프로필 이미지 업로드
  Future<String> uploadProfileImage(File file, String userId) async {
    final fileName = '${userId}_${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('profile_images/$fileName');
    
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // 인증 사진 업로드
  Future<String> uploadVerificationImage(File file, String challengeId) async {
    final fileName = '${challengeId}_${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('verification_images/$fileName');
    
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // 이미지 삭제
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // 이미지가 이미 삭제되었거나 존재하지 않을 수 있음
      print('Error deleting image: $e');
    }
  }
}

