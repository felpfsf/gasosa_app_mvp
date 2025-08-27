import 'dart:io';

abstract interface class LocalPhotoStorage {
  Future<String> savePhoto(File photo);
  // Future<Uint8List?> getPhoto(String id);
  Future<void> deletePhoto(String path);
}
